trigger CalloutBufferItemTrigger on Callout_Buffer_Item__c (before update) {
    TriggerFactory.createHandler(Callout_Buffer_Item__c.sObjectType);

}