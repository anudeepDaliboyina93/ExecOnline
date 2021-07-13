public class TRG_Opportunity_Helper {
    public static void createProvisionedEPCUs(List<Opportunity> newClosedWonOppsList){
        Map<Id,Opportunity> mapClosedWonOpps = new Map<Id,Opportunity>();
        List<EPC_Utilization__c> listEPCUs = new List<EPC_Utilization__c>();
        if(newClosedWonOppsList!=NULL && !newClosedWonOppsList.isEmpty()){
            mapClosedWonOpps = new Map<Id,Opportunity>(newClosedWonOppsList);
            List<AggregateResult> listOppLinesAggrResult = [Select Product2.Finance_Code__c financeCode, Product2.Purchase_Type__c purchaseType
                                                            ,OpportunityId oppId,SUM(Quantity) quantitySum, Opportunity.AccountId accId
                                                            ,Service_Category__c serviceCategory
                                                            FROM OpportunityLineItem
                                                            WHERE Product2.Purchase_Type__c!=NULL
                                                            AND Product2.Finance_Code__c!=NULL
                                                            AND OpportunityId IN:mapClosedWonOpps.keySet()
                                                            GROUP BY Product2.Finance_Code__c,Product2.Purchase_Type__c,OpportunityId
                                                            ,Opportunity.AccountId,Service_Category__c
                                                           ];
            system.debug('listOppLinesAggrResult---'+listOppLinesAggrResult);
            if(listOppLinesAggrResult!=NULL && !listOppLinesAggrResult.isEmpty()){
                for(AggregateResult aggr : listOppLinesAggrResult){
                    EPC_Utilization__c provEPC = new EPC_Utilization__c();
                    provEPC.Account__c = (Id)aggr.get('accId');
                    provEPC.Opportunity__c = (Id)aggr.get('oppId');
                    provEPC.Finance_Code__c = (String)aggr.get('financeCode');
                    provEPC.Purchase_Quantity__c = (Decimal)aggr.get('quantitySum');
                    string purchaseType = (String)aggr.get('purchaseType'); //NULL CHECK DONE AT QUERY LEVEL
                    provEPC.Purchase_Type__c = purchaseType;
                    provEPC.Type__c = 'Provisioned';
                    string serviceCategory = 'All';
                    
                    //IF CONDITIONS
                    serviceCategory = ((String)aggr.get('serviceCategory')!=NULL && (String)aggr.get('serviceCategory')!='') ? (String)aggr.get('serviceCategory'):'';
                    provEPC.Service_Category__c = serviceCategory;
                    if(purchaseType=='EPC'){
                        provEPC.EPCs_Utilized__c = (Decimal)aggr.get('quantitySum');
                    }
                    if(purchaseType=='Unlimited'){
                        provEPC.EPCs_Utilized__c = 0;
                    }
                    listEPCUs.add(provEPC);
                }
            }
        }
        
        if(listEPCUs!=NULL && !listEPCUs.isEmpty()){
            List<Database.SaveResult> listSaveResult = Database.insert(listEPCUs);
        }
    }
}