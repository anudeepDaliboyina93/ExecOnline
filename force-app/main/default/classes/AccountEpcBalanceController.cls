public class AccountEpcBalanceController {

    @AuraEnabled(cacheable=true)
    public static Boolean isEpcAdmin() {
        return UserUtility.isEpcAdmin();
    }

    @AuraEnabled(cacheable=true)
    public static String getJsonBalanceLineItemsForAccountId(Id accountId) {
        return JSON.serialize(getBalanceWrapperForAccountId(accountId).getReverseListOrder());
    }

    public static EpcBalanceWrapper getBalanceWrapperForAccountId(Id accountId) {
        EpcBalanceWrapper epcBalanceWrap = getBalanceWrappersForAccountIds(new Set<Id>{ accountId }).get(accountId);
        if(!UserUtility.isEpcAdmin()) {
            epcBalanceWrap.removeUtilizationsBeforeDate(Date.newInstance(2020, 1, 1));
            epcBalanceWrap.removeAdjustments();
        }
        return epcBalanceWrap;
    }

    public static Map<Id, EpcBalanceWrapper> getBalanceWrappersForAccountIds(Set<Id> accountIds) {
        Map<Id, EpcBalanceWrapper> accountIdToEpcBalanceWrapperMap = new Map<Id, EpcBalanceWrapper>();

        List<EPC_Utilization__c> epcus = getEpcusForAccountIds(accountIds);
        for(EPC_Utilization__c epcu : epcus) {
            if(accountIdToEpcBalanceWrapperMap.get(epcu.Account__c) == null) {
                accountIdToEpcBalanceWrapperMap.put(epcu.Account__c, new EpcBalanceWrapper(epcu.Account__r));
            }
            accountIdToEpcBalanceWrapperMap.get(epcu.Account__c).addLineItemFromEpcu(epcu);
        }

        for(EpcBalanceWrapper balanceWrapper : accountIdToEpcBalanceWrapperMap.values()) {
            balanceWrapper.sortedLineItems = balanceWrapper.lineItemsMap.values();
            balanceWrapper.sortedLineItems.sort();
            balanceWrapper.calculateLineItemBalances();
        }

        return accountIdToEpcBalanceWrapperMap;
    }
    
    public static List<EPC_Utilization__c> getEpcusForAccountIds(Set<Id> accountIds) {
        return [SELECT Id, Account__c, Account__r.Name, Adjustment_Date__c, EPCs_Utilized__c, Opportunity__c, Opportunity__r.Name, Opportunity__r.CloseDate, Adjustment_Program_Period__c, Adjustment_Program_Period__r.Name, Program__r.Program_Period__r.Name, Program__r.Program_Period__r.Start_Date__c, Type__c 
                FROM EPC_Utilization__c 
                WHERE Account__c IN :accountIds
                    AND (Type__c IN ('Actual', 'Adjustment', 'Provisioned')
                    OR (Type__c = 'Finance Adjustment' AND EPCs_Utilized__c > 0))
                ORDER BY Type__c DESC];
    }

    public class EpcBalanceWrapper {
        public Account parentAccount {get;set;}
        public Map<String, EpcBalanceLineItem> lineItemsMap {get;set;}
        public List<EpcBalanceLineItem> sortedLineItems {get;set;}

        public EpcBalanceWrapper(Account acc) {
            this.parentAccount = acc;
            this.lineItemsMap = new Map<String, EpcBalanceLineItem>();
        }
        
        public void addLineItemFromEpcu(EPC_Utilization__c epcu) {
            EpcBalanceLineItem newLineItem = new EpcBalanceLineItem(epcu);
            if(lineItemsMap.get(newLineItem.description) == null) {
                lineItemsMap.put(newLineItem.description, newLineItem);
            } else {
                lineItemsMap.get(newLineItem.description).groupLineItem(newLineItem);
            }
        }

        public void calculateLineItemBalances() {
            for(Integer i = 0; i < this.sortedLineItems.size(); i++) {
                if(i == 0) {
                    this.sortedLineItems[i].balance = this.sortedLineItems[i].amount;
                    this.sortedLineItems[i].displayBalance = this.sortedLineItems[i].balance < 0 ? '(' + (this.sortedLineItems[i].balance * -1).setScale(2) + ')' : String.valueOf(this.sortedLineItems[i].balance.setScale(2));
                    continue;
                }
                if(this.sortedLineItems[i].type == 'Reserved') {
                    this.sortedLineItems[i].balance = this.sortedLineItems[i - 1].balance;
                    this.sortedLineItems[i].displayBalance = this.sortedLineItems[i - 1].displayBalance;
                    continue;
                }
                Decimal balance = this.sortedLineItems[i - 1].balance + this.sortedLineItems[i].amount;
                this.sortedLineItems[i].balance = balance;
                this.sortedLineItems[i].displayBalance = balance < 0 ? '(' + (balance * -1).setScale(2) + ')' : String.valueOf(balance.setScale(2));
            }
        }

        public void removeUtilizationsBeforeDate(Date d) {
            List<EpcBalanceLineItem> noUtilizationsBeforeDate = new List<EpcBalanceLineItem>();
            for(Integer i = 0; i < this.sortedLineItems.size(); i++) {
                if(this.sortedLineItems[i].type == 'Utilization' && this.sortedLineItems[i].itemDate < d) {
                    continue;
                }
                noUtilizationsBeforeDate.add(this.sortedLineItems[i]);
            }
            this.sortedLineItems = noUtilizationsBeforeDate;
        }

        public void removeAdjustments() {
            List<EpcBalanceLineItem> noAdjustments = new List<EpcBalanceLineItem>();
            for(Integer i = 0; i < this.sortedLineItems.size(); i++) {
                if (this.sortedLineItems[i].description != null){
                    if(!this.sortedLineItems[i].description.toLowerCase().contains('adjustment')) {
                        noAdjustments.add(this.sortedLineItems[i]);
                }
              
                }
            }
            this.sortedLineItems = noAdjustments;
        }

        public List<EpcBalanceLineItem> getReverseListOrder() {
            List<EpcBalanceLineItem> reverseOrder = new List<EpcBalanceLineItem>();
            for(Integer i = this.sortedLineItems.size() - 1; i >= 0; i--) {
                reverseOrder.add(this.sortedLineItems[i]);
            }
            return reverseOrder;
        }
    }

    public class EpcBalanceLineItem implements Comparable {
        public String type {get;set;}
        public Decimal amount {get;set;}
        public String displayAmount {get;set;}
        public Decimal balance {get;set;}
        public String displayBalance {get;set;}
        public Date itemDate {get;set;}
        public String description {get;set;}
        public List<Id> groupedEpcuIds {get;set;}
        public String url {get;set;}
        
        public EpcBalanceLineItem() {}

        public EpcBalanceLineItem(EPC_Utilization__c epcu) {
            this.groupedEpcuIds = new List<Id>{ epcu.Id };
            this.amount = epcu.EPCs_Utilized__c;
            if(epcu.Type__c == 'Actual') {
                this.itemDate = epcu.Program__r.Program_Period__r.Start_Date__c != null ? epcu.Program__r.Program_Period__r.Start_Date__c : null; //14 DAYS

                if (this.itemDate != null ){
                    this.type = this.itemDate?.addDays(-14) <= Date.today() ? 'Utilization' : 'Reserved'; 
                }

                else {
                    this.type = 'Utilization'; 
                }
                
                this.description = epcu.Program__r.Program_Period__r.Name;
                this.displayAmount = '(' + this.amount.setScale(2) + ')';
                this.amount = epcu.EPCs_Utilized__c * -1;
                this.url = getReportBaseUrl() + '?' + getReportUrlParameterBase() + '1=' + epcu.Program__r.Program_Period__r.Name + '&' + getReportUrlParameterBase() + '2=' + epcu.Account__c;
            } else if(epcu.Type__c == 'Provisioned' || epcu.Type__c == 'Finance Adjustment') {
                this.type = 'Purchase';
                this.displayAmount = String.valueOf(this.amount.setScale(2));
                if(epcu.Type__c == 'Provisioned') {
                    this.itemDate = epcu.Opportunity__r.CloseDate;
                    this.description = epcu.Opportunity__r.Name;
                    this.url = '/' + epcu.Opportunity__c;
                } else {
                    this.itemDate = epcu.Adjustment_Date__c;
                    this.url = '/' + epcu.Id;
                    this.description = 'Adjustment';
                    if(epcu.Adjustment_Program_Period__c != null) {
                        this.description = epcu.Adjustment_Program_Period__r.Name;
                    } else if(epcu.Opportunity__c != null) {
                        this.description = epcu.Opportunity__r.Name;
                    }
                }
            } else if(epcu.Type__c == 'Adjustment') {
                this.type = epcu.Type__c;
                this.itemDate = epcu.Adjustment_Date__c;
                if(epcu.Adjustment_Program_Period__c != null) {
                    this.description = epcu.Adjustment_Program_Period__r.Name;
                    this.url = getReportBaseUrl() + '?' + getReportUrlParameterBase() + '1=' + epcu.Adjustment_Program_Period__r.Name + '&' + getReportUrlParameterBase() + '2=' + epcu.Account__c;
                } else {
                    this.description = 'Adjustment on ' + epcu.Opportunity__r.Name;
                    this.url = '/' + epcu.Id;
                }
                this.displayAmount = '(' + this.amount.setScale(2) + ')';
                this.amount = this.amount * -1;
            }
        }

        public String getReportBaseUrl() {
            if(UserUtility.isUsingLightningExperience()) {
                return '/lightning/r/Report/00O1Y000007A5kIUAS/view';
            }
            return '/00O1Y000007A5kIUAS';
        }

        public String getReportUrlParameterBase() {
            return UserUtility.isUsingLightningExperience() ? 'fv' : 'pv';
        }

        public void groupLineItem(EpcBalanceLineItem lineItem) {
            this.amount += lineItem.amount;
            this.displayAmount = this.amount < 0 ? '(' + (this.amount * -1).setScale(2) + ')' : String.valueOf(this.amount.setScale(2));
            this.groupedEpcuIds.addAll(lineItem.groupedEpcuIds);
        }

        public Integer compareTo(Object compareTo) {
            EpcBalanceLineItem compareToEpcBalanceLineItem = (EpcBalanceLineItem)compareTo;
            if(this.itemDate > compareToEpcBalanceLineItem.itemDate) {
                return 1;
            }
            return -1;
        }
    }
}