trigger CaseTrigger on Case (before insert, after update) {
    TriggerConfiguration__c triggerConfiguration = TriggerConfiguration__c.getInstance();
    TriggerFactory.createHandler(Case.sObjectType);
}