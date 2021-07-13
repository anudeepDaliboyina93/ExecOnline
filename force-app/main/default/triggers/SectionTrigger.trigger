trigger SectionTrigger on Section__c (after insert, after update, after delete, after undelete) {
    TriggerFactory.createHandler(Section__c.sObjectType);
}