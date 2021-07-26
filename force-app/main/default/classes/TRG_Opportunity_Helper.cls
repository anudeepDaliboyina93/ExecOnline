public class TRG_Opportunity_Helper {
    public static void createProvisionedEPCUs(List<Opportunity> newClosedWonOppsList){
        Map<Id,Opportunity> mapClosedWonOpps = new Map<Id,Opportunity>();
        List<EPC_Utilization__c> listEPCUs = new List<EPC_Utilization__c>();
        if(newClosedWonOppsList!=NULL && !newClosedWonOppsList.isEmpty()){
            mapClosedWonOpps = new Map<Id,Opportunity>(newClosedWonOppsList);

            List<AggregateResult> listErrorEntries = [Select count(Id) countOppLines, OpportunityId oppId  From OpportunityLineItem
                                                      WHERE OpportunityId IN:mapClosedWonOpps.keySet()
                                                      AND Product2.Purchase_Type__c!=NULL
                                                      AND Product2.Finance_Code__c!=NULL
                                                      GROUP BY OpportunityId, Product2Id
                                                     ];


            if(listErrorEntries!=null && !listErrorEntries.isEmpty()){
                for(AggregateResult aggRes : listErrorEntries){
                    if((integer)aggRes.get('countOppLines')>1){
                        for(Opportunity oppRec : newClosedWonOppsList){
                            if(oppRec.Id == (Id)aggRes.get('oppId')){
                                oppRec.addError('Duplicate products present on the opportunity.');
                            }
                        }
                    }
                }
            }

            List<AggregateResult> listOppLinesAggrResult = [Select Product2.Finance_Code__c financeCode, Product2.Purchase_Type__c purchaseType
                                                            ,OpportunityId oppId,SUM(Quantity) quantitySum 
                                                            FROM OpportunityLineItem
                                                            WHERE Product2.Purchase_Type__c!=NULL
                                                            AND Product2.Finance_Code__c!=NULL
                                                            AND OpportunityId IN:mapClosedWonOpps.keySet()
                                                            GROUP BY Product2.Finance_Code__c,Product2.Purchase_Type__c,OpportunityId
                                                            ];
            
            List<OpportunityLineItem> listOppLineItems = [Select Id,Product2.Finance_Code__c, Product2.Purchase_Type__c , Opportunity.AccountId
                                                            ,Service_Category__c FROM OpportunityLineItem
                                                            WHERE Product2.Purchase_Type__c!=NULL
                                                            AND Product2.Finance_Code__c!=NULL
                                                         AND OpportunityId IN:mapClosedWonOpps.keySet()
                                                        ] ;

            
            if(listOppLineItems!=null && !listOppLineItems.isEmpty()){
                for(OpportunityLineItem oppLinItem : listOppLineItems){
                    EPC_Utilization__c provEPC = new EPC_Utilization__c();
                    provEPC.Account__c = oppLinItem.Opportunity.AccountId;
                    provEPC.Opportunity__c = oppLinItem.OpportunityId;
                    provEPC.Opportunity_Product__c = oppLinItem.Id;
                    provEPC.Finance_Code__c = oppLinItem.Finance_Code__c;
                    provEPC.Type__c = 'Provisioned';
                    string purchaseType = oppLinItem.Product2.Purchase_Type__c;
                    string serviceCategory = 'All';
                    serviceCategory = (oppLinItem.Service_Category__c!=null && oppLinItem.Service_Category__c!='') ? oppLinItem.Service_Category__c:'';
                    provEPC.Service_Category__c = serviceCategory;
                    if(purchaseType=='Unlimited'){
                        provEPC.EPCs_Utilized__c = 0;
                    }
                    if(listOppLinesAggrResult!=null && !listOppLinesAggrResult.isEmpty()){
                        for(AggregateResult aggRes : listOppLinesAggrResult){
                            if((Id)aggRes.get('oppId') == oppLinItem.OpportunityId && (string)aggRes.get('financeCode') == oppLinItem.Finance_Code__c){
                                provEPC.Purchase_Quantity__c = (Decimal)aggRes.get('quantitySum');
                            }
                            if(purchaseType=='EPC'){
                                provEPC.EPCs_Utilized__c = (Decimal)aggRes.get('quantitySum');
                            }
                        }
                    }
                    listEPCUs.add(provEPC);
                }
            }
            
            
            system.debug('listOppLinesAggrResult---'+listOppLinesAggrResult);
            /*if(listOppLinesAggrResult!=NULL && !listOppLinesAggrResult.isEmpty()){
                for(AggregateResult aggr : listOppLinesAggrResult){
                    EPC_Utilization__c provEPC = new EPC_Utilization__c();
                    provEPC.Account__c = (Id)aggr.get('accId');
                    provEPC.Opportunity__c = (Id)aggr.get('oppId');
                    provEPC.Finance_Code__c = (String)aggr.get('financeCode');
                    provEPC.Purchase_Quantity__c = (Decimal)aggr.get('quantitySum');
                    string purchaseType = (String)aggr.get('purchaseType'); //NULL CHECK DONE AT QUERY LEVEL
                    provEPC.Purchase_Type__c = purchaseType;
                    //provEPC.Opportunity_Product__c = (Id)aggr.get('oppLineItemId');
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
            }*/
        }
        
        if(listEPCUs!=NULL && !listEPCUs.isEmpty()){
            List<Database.SaveResult> listSaveResult = Database.insert(listEPCUs);
        }
    }
}