/**
 * ProgramHandler.cls
 * Copyright 2015 Wired Triangle, LLC
 * http://www.wiredtriangle.com
 */

public with sharing class ProgramHandler implements ITrigger {
    private CalloutBuffer.ObjectsToEnqueueWrapper objectsToEnqueue = new CalloutBuffer.ObjectsToEnqueueWrapper();

    Set<Id> programIdsToUpdate = new Set<Id>();
    Set<Id> programIdsToUpdateName = new Set<Id>();
    Set<Id> programIdsToInsert = new Set<Id>();

    private static Map<Id, Campaign> programIdToNewCampaign = new Map<Id, Campaign>();
    private static Map<Id, Campaign> programIdToUpdateCampaign = new Map<Id, Campaign>();
    private static List<Id> programIdsWithNewCampaigns = new List<Id>();
    private static Map<Id, Id> existingProgramIdToCampaignId = new Map<Id, Id>();
    private static Map<Id, String> existingCampaignToNewName = new Map<Id, String>();
    public static Boolean preventFurtherUpdateHandler = FALSE;
    private static List<Program__c> programs = new List<Program__c>();
    private Set<Date> dates = new Set<Date>();
    private static Map<Date, Id> dateMap = new Map<Date, Id>();

    private Id managerMasterCampaignId;

    public void bulkBefore() {
        if(managerMasterCampaignId == null) {
            List<Campaign> managerMasterCampaign = [SELECT Id FROM Campaign WHERE Name = 'Master Campaign - Manager' LIMIT 1];
            managerMasterCampaignId = managerMasterCampaign.isEmpty() ? null : managerMasterCampaign[0].Id;
        }
    }

    public void bulkAfter() {
        Map<Id, Program__c> programMap = new Map<Id, Program__c>([select Id, Manager_Campaign__c from Program__c]);
        for (Id progId : programMap.keySet()) {
            Id mgrCampaignId = (programMap.get(progId).Manager_Campaign__c != NULL) ? programMap.get(progId).Manager_Campaign__c : NULL;
            if (mgrCampaignId != NULL) {
                existingProgramIdToCampaignId.put(progId, mgrCampaignId);
            }
            existingProgramIdToCampaignId.put(progId, mgrCampaignId);
        }
    }

    public void beforeInsert(SObject so) {

        Program__c program = (Program__c) so;
        

        if (program.Course_Start_Date__c != null && program.Program_Period__c == null){
            programs.add(program);
            dates.add(program.Course_Start_Date__c);
        }

    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        Program__c program    = (Program__c) so;
        Program__C oldProgram = (Program__c) oldSo;

        if (program.Course_Start_Date__c != null && program.Course_Start_Date__c != oldProgram.Course_Start_Date__c){
            programs.add(program);
            dates.add(program.Course_Start_Date__c);
        }

    }

    public void beforeDelete(SObject so) {
        Program__c program = (Program__c) so;

    }

    public void beforeUnDelete(SObject so) {
        Program__c program = (Program__c) so;

    }

    public void afterInsert(SObject so) {
        Program__c program = (Program__c) so;
        programIdsToUpdate.add(program.Id);

        Campaign c = new Campaign(Name = program.Name + ' - Managers', Program__c = program.Id, IsActive = true, Master_Campaign__c = managerMasterCampaignId);
        programIdToNewCampaign.put(program.Id, c);
        programIdsToInsert.add(program.Id);

        enqueue(program, 'POST');
        
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        Program__c program = (Program__c) so;
        Program__c oldProgram = (Program__c) oldSo;

        if (!preventFurtherUpdateHandler && program.Name != oldProgram.Name) {
            Id existingCampaignIdToUpdate = existingProgramIdToCampaignId.get(program.Id);
            existingCampaignToNewName.put(existingCampaignIdToUpdate, program.Name);
        }

        if (CalloutBuffer.hasIntegrationFieldChanged(program, oldProgram)) {
            enqueue(program, 'PUT');
        }


    }

    public void afterDelete(SObject so) {
        Program__c program = (Program__c) so;
        programIdsToUpdate.add(program.Id);

        enqueue(program, 'DELETE');

    }

    public void afterUnDelete(SObject so) {
        Program__c program = (Program__c) so;
        programIdsToUpdate.add(program.Id);

        enqueue(program, 'POST');
    }

    public void andFinally() {

        if (!programs.isEmpty()){

            updateProgramPeriod();
        }

        if (!programIdsToUpdate.isEmpty() && !System.isBatch())  {
            List<Student__c> studentsToUpdate = [Select id, Contact__c from Student__c where Program__c in :programIdsToUpdate];
            Set<Id> contactIdsToUpdateSet = new Set<Id>();
            for (Student__c student : studentsToUpdate ) {
                contactIdsToUpdateSet.add(student.contact__c);
            }
            List<Id> contactIdsToUpdate = new List<Id>();
            contactIdsToUpdate.addAll(contactIdsToUpdateSet);

            Map<Id, Contact> contactMap = new Map<Id, Contact>([Select id from Contact where Id in :contactIdsToUpdate]);
            List<Id> cIds = new List<Id>();
            cIds.addAll(contactMap.keySet());
            ContactService.pushToContactSync(cids);
        }


        if (!Trigger.isUpdate && !Trigger.isDelete) {
            if (!programIdToNewCampaign.isEmpty()) {
                List<Campaign> campaignsToInsert = programIdToNewCampaign.values();
                system.debug(campaignsToInsert);

                if (campaignsToInsert.size() > 0) {
                    insert campaignsToInsert;
                    createCampaignMemberStatuses(campaignsToInsert);
                }

                List<Program__c> programsToUpdate = [Select Id, Manager_Campaign__c from Program__c where Id in :programIdsToInsert];
                for (Program__c p : programsToUpdate) {
                    p.Manager_Campaign__c = programIdToNewCampaign.get(p.Id).Id;
                }
                preventFurtherUpdateHandler = TRUE;
                update programsToUpdate;
                preventFurtherUpdateHandler = FALSE;

            }
        }

        if (Trigger.isUpdate) {
            if (!existingCampaignToNewName.isEmpty()) {
                List<Campaign> campaignsToUpdate = [Select Id, Name from Campaign where Id in :existingCampaignToNewName.keySet()];
                for (Campaign c : campaignsToUpdate) {
                    c.Name = existingCampaignToNewName.get(c.Id) + ' - Managers';
                }
                CampaignHandler.allowCampaignNameChange = TRUE;
                update campaignsToUpdate;
                CampaignHandler.allowCampaignNameChange = FALSE;
            }
        }

        if (!objectsToEnqueue.isEmpty()) {
            CalloutBuffer.enqueueObjects(objectsToEnqueue);
        }
    }

    private void enqueue(SObject so, String action) {
        objectsToEnqueue.actionType = action;
        objectsToEnqueue.objects.add(so);
    }

    @TestVisible
    private void createCampaignMemberStatuses(List<Campaign> campaigns) {
        List<CampaignMemberStatus> cmStatuses = new List<CampaignMemberStatus>();
        for (Campaign c : campaigns) {
            CampaignMemberStatus cmStatus = new CampaignMemberStatus(CampaignId = c.Id, SortOrder = 3, Label = 'Not Participating');
            cmStatuses.add(cmStatus);
        }
        if (!cmStatuses.isEmpty()) {
            insert cmStatuses;
        }
    }

    @TestVisible
    private void updateProgramPeriod(){
        
        List<Program__c> programsToUpdate = new List<Program__c>();

            Map<Id, Program_Period__c> periods = new Map<Id, Program_Period__c>([SELECT Id, Start_Date__c FROM Program_Period__c WHERE Start_Date__c IN:dates]);

            for (Program_Period__c p : periods.values()){

                dateMap.put(p.Start_Date__c, p.Id);
            }

            Set<Id> programIds = new Set<Id>();

            if (Trigger.isBefore){

                for (Program__c program : programs){

                    program.Program_Period__c = dateMap?.get(program?.Course_Start_Date__c);
                    programsToUpdate.add(program);
                    programIds.add(program.Id);
                     
                 }
            }
          

           if (!programsToUpdate.isEmpty() && Trigger.isInsert){

            List<Program__c> programsUpdateList = [SELECT Id, Program_Period__c FROM Program__c WHERE ID IN:programIds]; 

            for (Program__c p : programsUpdateList){
                p.Program_Period__c = dateMap?.get(p?.Course_Start_Date__c);
            }

               update programsUpdateList;
           }
    }

}