trigger EPCUtilizationItemTrigger on EPC_Utilization_Item__c (
    before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {

	TriggerFactory.createHandler(EPC_Utilization_Item__c.sObjectType);

}