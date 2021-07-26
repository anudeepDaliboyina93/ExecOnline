public with sharing class TRG_EPCUtilization_Helper {
    public static void calculateQuantityUtilized(List<EPC_Utilization__c> listEpcUtilizations) {
        Set<Id> epcUtilProvIdSet = new Set<Id>();
        Map<Id,EPC_Utilization__c> mapEPCUtilizationProvRecs = new Map<Id,EPC_Utilization__c>();
        List<AggregateResult> listAggregateResult = new List<AggregateResult>();
        if(listEpcUtilizations!=null && !listEpcUtilizations.isEmpty()){
            for(EPC_Utilization__c epcUtil : listEpcUtilizations){
                if(epcUtil.Type__c == 'Actual'){
                    epcUtilProvIdSet.add(epcUtil.Provisioned_EPCU__c);
                }
            }
        }

        if(epcUtilProvIdSet!=null && !epcUtilProvIdSet.isEmpty()){
            mapEPCUtilizationProvRecs = new Map<Id,EPC_Utilization__c>([Select Id,Quantity_Utilized__c 
                                                                         FROM EPC_Utilization__c
                                                                        WHERE (Purchase_Type__c=:'Quantity'
                                                                        OR Purchase_Type__c=:'Unlimited')
                                                                        AND
                                                                        Type__c=:'Provisioned'
                                                                        ]);
            listAggregateResult = [Select sum(Quantity_Utilized__c) utilizedQuantity, Provisioned_EPCU__c provEpcu
                FROM EPC_Utilization__c
                WHERE Provisioned_EPCU__c IN:epcUtilProvIdSet
                AND Provisioned_EPCU__c!=null
                AND (Type__c='Actual' OR Type__c='Adjustment' OR Type__c='Finance Adjustment')
                Group By Provisioned_EPCU__c
            ];
        }

        if(mapEPCUtilizationProvRecs!=null && !mapEPCUtilizationProvRecs.isEmpty()){
            for(Id provId : mapEPCUtilizationProvRecs.keySet()){
                decimal quanUtilized = 0.0;
                if(listAggregateResult!=null && !listAggregateResult.isEmpty()){
                    for(AggregateResult aggrRes : listAggregateResult){
                        if(provId == (Id)aggrRes.get('provEpcu')){
                            mapEPCUtilizationProvRecs.get(provId).Quantity_Utilized__c = (Decimal)aggrRes.get('utilizedQuantity');
                        }
                    }
                }
            }
            List<Database.SaveResult> listSaveResults = Database.update(mapEPCUtilizationProvRecs.values());
        }
        
    }
}
