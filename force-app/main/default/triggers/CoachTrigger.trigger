trigger CoachTrigger on Coach__c (after insert, after update, after delete, after undelete) {
    TriggerFactory.createHandler(Coach__c.sObjectType);
}