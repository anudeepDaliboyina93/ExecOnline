public with sharing class TRG_Student_Helper {
    public static void calculateEPCActualAndProvisioned(List<Student__c> listStudents){
        Set<Id> studentIdSet = new Set<Id>();
        Set<Id> programIdSet = new Set<Id>();
        Set<Id> contactIdSet = new Set<Id>();
        List<EPC_Utilization__c> listEPCsProvisioned = new List<EPC_Utilization__c>();
        List<Applicable_Purchase__c> listApplicablePurchases = new List<Applicable_Purchase__c>();
        if(listStudents!=null && !listStudents.isEmpty()){
            for(Student__c studentRec : listStudents){
                studentIdSet.add(studentRec.Id);
                if(studentRec.Next_Program__c!=null){
                    programIdSet.add(studentRec.Next_Program__c);
                }
                if(studentRec.Contact__c!=null){
                    contactIdSet.add(studentRec.Contact__c);
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
                listApplicablePurchases = [Select Id
                                           FROM Applicable_Purchase__c 
                                           WHERE Service__c IN (Select Id
                                                                FROM Service__c
                                                                WHERE Program_Family__c IN:mapProgramFamily.keySet()
                                                               )
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
                
                listEPCsProvisioned = [Select Id FROM EPC_Utilization__c
                                       WHERE Account__c IN: mapAccounts.keySet()
                                       AND Type__c=:'Provisioned'
                                       AND Effective_Date__c<=:Date.Today()
                                       //AND Expiration_Date__c >= Date.today()
                                       AND Balance__c>:0
                                      ];
            }
        }
        
    }
}