trigger ProfessorTrigger on Professor__c (after insert, after update, after delete, after undelete) {
    TriggerFactory.createHandler(Professor__c.sObjectType);
}