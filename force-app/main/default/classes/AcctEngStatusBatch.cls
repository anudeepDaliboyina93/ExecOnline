public class AcctEngStatusBatch implements Database.Batchable<sObject> {
  public AcctEngStatusBatch() {}

    public Iterable<sObject> start (Database.BatchableContext bc) {
        return Database.getQueryLocator('select id,Engagement_Status__c,of_Opportunities_Closed_Won__c,of_MQI_Leads__c,of_MQL_Leads__c,of_Open_Opportunities__c,of_Opportunities_Closed_Lost__c from account ');
    }

    public void execute(Database.BatchableContext BC, List<Account> scope) {
    List<Account> alist = new List<Account>();
        for (Account a : scope) {
            String curEngagement = a.Engagement_Status__c;
            
            if (a.of_Opportunities_Closed_Won__c > 0) {
                a.Engagement_Status__c = 'Closed Won';
            } else if (a.of_Open_Opportunities__c > 0 && a.of_Opportunities_Closed_Won__c == 0) {
                a.Engagement_status__c = 'Active Opportunity';
            } else if (a.of_MQI_Leads__c > 0 && a.of_MQL_Leads__c == 0 && a.of_Open_Opportunities__c == 0 && a.of_Opportunities_Closed_Lost__c == 0 && a.of_Opportunities_Closed_Won__c == 0) {
                a.Engagement_Status__c = 'MQI';
            } else if (a.of_MQL_Leads__c > 0 && a.of_MQI_Leads__c == 0 && a.of_Open_Opportunities__c == 0 && a.of_Opportunities_Closed_Lost__c == 0 && a.of_Opportunities_Closed_Won__c == 0) {
                a.Engagement_Status__c = 'MQL';    
            } else if (a.of_Opportunities_Closed_Lost__c > 0 && a.of_MQI_Leads__c == 0 && a.of_Open_Opportunities__c == 0 && a.of_MQL_Leads__c == 0 && a.of_Opportunities_Closed_Won__c == 0) {
              a.Engagement_Status__c = 'Closed Lost';
          } else {
                a.Engagement_Status__c = 'Have Not Engaged';
            }
            
            if (curEngagement != a.Engagement_Status__c) {
                alist.add(a);
            }
            
        }

        if (!alist.isEmpty()) {
            Database.update(alist, false);
        }
    }
    
    public void finish(Database.BatchableContext BC) {}
}