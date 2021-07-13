trigger StudentTrigger on Student__c (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {

	TriggerFactory.createHandler(Student__c.sObjectType);
}