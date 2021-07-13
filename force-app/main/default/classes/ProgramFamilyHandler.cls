public with sharing class ProgramFamilyHandler extends TriggerHandler {
 
    public static Map<Id,Id> aepServices = new Map<Id, Id>();

    public override void afterInsert(Map<Id, SObject> newItemMap) {

     List<Program_Family__c> newProgramFamily = newItemMap.values();

        createPrimaryService(newProgramFamily);
        findPrimaryService(newProgramFamily);
        updateAEPOppsWithWeightings();

    }

    private void createPrimaryService(List<Program_Family__c> programFamilies){

        List<Service__c> insertPrimaryService = new List<Service__c>();
        for (Program_Family__c pf : programFamilies){

            Service__c primaryService = new Service__c();

            primaryService.Name                        = 'Core Program - ' + pf.Name;
            primaryService.Program_Family__c           = pf.Id;
            primaryService.List_Weighting__c           = 0.00;
            primaryService.Utilization_Date_Formula__c = 'Program Start Date -14d';
            primaryService.Status__c                   = 'Active';
            primaryService.Service_Category__c         = 'All';

            insertPrimaryService.add(primaryService);

        }

        if (!insertPrimaryService.isEmpty()){

            insert insertPrimaryService;
            
        }
    }

    private void findPrimaryService(List<Program_Family__c> programFamilies){

        List<Program_Family__c> updateProgramFamilies = new List<Program_Family__c>();
        Set<Id> programFamilyIds = new Set<Id>();
        Map<Id, Service__c> serviceMap = new Map<Id, Service__c>();

        for (Program_Family__c pf : programFamilies){
            programFamilyIds.add(pf.Id);
            
        }

        List<Service__c> serviceRecords = [SELECT Id, Program_Family__c FROM Service__c WHERE Program_Family__c IN:programFamilyIds];

        for (Service__c ps : serviceRecords){

            serviceMap.put(ps.Program_Family__c, ps);
        }

        List<Program_Family__c> newList = [SELECT Id, EPC_Weighting__c, Primary_Service__c, Name FROM Program_Family__c WHERE Id IN:programFamilyIds];

        for (Program_Family__c pf : newList){

            if (pf.Primary_Service__c == null){

                pf.Primary_Service__c = serviceMap.get(pf.Id).Id;
                pf.EPC_Weighting__c   = 0.00;
                
            }
            
            if (pf.Name.contains('AEP')){

               aepServices.put(pf.Primary_Service__c, pf.Id);
            }

            updateProgramFamilies.add(pf);
        }

        if (!updateProgramFamilies.isEmpty()){

            update updateProgramFamilies;
        }
    }

    private void updateAEPOppsWithWeightings(){

        if (!aepServices.isEmpty()){

            List<EPC_Weighting__c> weightingsToInsert  = new List<EPC_Weighting__c>();
            Set<Id>                oppIds              = new Set<Id>();
            List<Opportunity>      aepOpps             = [SELECT Id, AccountId, CloseDate, Contract_End_Date__c FROM Opportunity WHERE Number_of_AEP_Products__c > 0 AND StageName = 'Closed/Won'];

            for (Opportunity opp : aepOpps){

                for (Id aepService : aepServices.keySet()){

                    EPC_Weighting__c ew   = new EPC_Weighting__c(
                        Opportunity__c    = opp.Id,
                        Service__c        = aepService,
                        EPC_Weighting__c  = 0,
                        Is_Unlimited__c   = true,
                        Program_Family__c = aepServices.get(aepService),
                        Account__c        = opp.AccountId,
                        Start_Date__c     = opp.CloseDate,
                        End_Date__c       = opp.Contract_End_Date__c
                    );

                    weightingsToInsert.add(ew);
                }
            }
        

           if (!weightingsToInsert.isEmpty() && weightingsToInsert.size() < 10000){
               insert weightingsToInsert;
           } 

        }
 
    }
}