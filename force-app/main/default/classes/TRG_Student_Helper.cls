public with sharing class TRG_Student_Helper {
    public static void calculateEPCActualAndProvisioned(List<Student__c> listStudents){
        Set<Id> studentIdSet = new Set<Id>();
        Set<Id> programIdSet = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();
        List<EPC_Utilization__c> listEPCsProvisioned = new List<EPC_Utilization__c>();
        List<Applicable_Purchase__c> listApplicablePurchases = new List<Applicable_Purchase__c>();
        if(listStudents!=null && !listStudents.isEmpty()){
            for(Student__c studentRec : listStudents){
                if(studentRec.Status_Utilized__c){
                    studentIdSet.add(studentRec.Id);
                    if(studentRec.Program__c!=null){
                        programIdSet.add(studentRec.Program__c);
                    }
                    if(studentRec.Contact__c!=null){
                        contactIdSet.add(studentRec.Contact__c);
                    }
                }
            }
        }
        
        //Get Applicable Purchases
        if(programIdSet!=null && !programIdSet.isEmpty()){
            
            Map<Id,Program_Family__c> mapProgramFamily = new Map<Id,Program_Family__c>([Select Id
                                                                                        FROM Program_Family__c
                                                                                        WHERE Id IN (Select Program_Family__c 
                                                                                                     FROM Program__c
                                                                                                     WHERE Id IN:programIdSet
                                                                                                    )            
                                                                                       ]);
            
            if(mapProgramFamily!=null && !mapProgramFamily.isEmpty()){
                listApplicablePurchases = [Select Id,List_Quantity__c,Product__c,Purchase_Type__c,Service__c
                                           FROM Applicable_Purchase__c 
                                           WHERE Service__c IN (Select Primary_Service__c
                                                                FROM Program_Family__c
                                                                WHERE Id IN:mapProgramFamily.keySet()
                                                               )
                                                               Order BY Utilization_Priority__c
                                          ];
            }
        }
        
        //Get EPC Utilization (Provisioned) for the contacts
        if(contactIdSet!=null && !contactIdSet.isEmpty()){
            Map<Id,Account> mapAccounts = new Map<Id,Account>([Select Id
                                                               FROM Account
                                                               WHERE Id IN (Select AccountId 
                                                                            FROM Contact 
                                                                            WHERE ID IN: contactIdSet
                                                                           )
                                                              ]);
            
            if(mapAccounts!=null && !mapAccounts.isEmpty()){
                
                listEPCsProvisioned = [Select Id,Opportunity_Product__r.Product2Id 
                                        FROM EPC_Utilization__c
                                       WHERE Account__c IN: mapAccounts.keySet()
                                       AND Type__c=:'Provisioned'
                                       AND Effective_Date__c<=:Date.Today()
                                       //AND Expiration_Date__c >= Date.today()
                                       AND Balance__c>:0
                                       AND (Purchase_Type__c='Unlimited' OR Purchase_Type__c='Quantity')
                                      ];
            }
        }
        List<EPC_Utilization__c> listEPCUtilizationActuals = new List<EPC_Utilization__c>();
        if(listStudents!=null && !listStudents.isEmpty()){
            for(Student__c studentRec : listStudents){
                if(studentRec.Status_Utilized__c){
                    EPC_Utilization__c epcAct = new EPC_Utilization__c();
                    epcAct.Type__c = 'Actual';
                    if(listApplicablePurchases!=null && !listApplicablePurchases.isEmpty()){
                        for(Applicable_Purchase__c appPurchase : listApplicablePurchases){
                            boolean breakAway = false;
                            if(listEPCsProvisioned!=null && !listEPCsProvisioned.isEmpty()){
                                for(EPC_Utilization__c epcUtilProv : listEPCsProvisioned){
                                    if(appPurchase.Product__c == epcUtilProv.Opportunity_Product__r.Product2Id){
                                        breakAway = true;
                                        epcAct.Provisioned_EPCU__c = epcUtilProv.Id;
                                        if(epcUtilProv.Purchase_Type__c == 'Unlimitied' || epcUtilProv.Purchase_Type__c == 'Quantity'){
                                            epcAct.Quantity_Utilized__c = appPurchase.List_Quantity__c;
                                            listEPCUtilizationActuals.add(epcAct);
                                        }
                                        break;
                                    }
                                }
                            }
                            if(breakAway){
                                break;
                            }
                        }
                    }
                }
            }
        }
        if(listEPCUtilizationActuals!=null && !listEPCUtilizationActuals.isEmpty()){
            List<Database.SaveResult> listSaveResult = Database.insert(listEPCUtilizationActuals);
        }
    }
}