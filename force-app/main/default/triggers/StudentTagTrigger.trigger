trigger StudentTagTrigger on Student_Tag__c (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {

	TriggerFactory.createHandler(Student_Tag__c.sObjectType);
}