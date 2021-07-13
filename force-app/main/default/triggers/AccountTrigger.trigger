trigger AccountTrigger on Account (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {
    TriggerConfiguration__c triggerConfiguration = TriggerConfiguration__c.getInstance();
    if (triggerConfiguration.Enable_AccountTrigger__c) {
		TriggerFactory.createHandler(Account.sObjectType);
	}
}