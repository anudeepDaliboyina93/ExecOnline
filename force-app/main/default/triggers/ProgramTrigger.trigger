/**
 * ProgramTrigger.cls
 * Copyright 2015 Wired Triangle, LLC
 * http://www.wiredtriangle.com
 */
trigger ProgramTrigger on Program__c (
	before insert,
	before update,
	before delete,
	after insert,
	after update,
	after delete,
	after undelete) {

	TriggerFactory.createHandler(Program__c.sObjectType);
}