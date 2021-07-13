trigger TeamTrigger on Team__c (after insert, after update, after delete) {
    TriggerFactory.createHandler(Team__c.sObjectType);
}