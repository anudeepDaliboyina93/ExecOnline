/***********************************************************************************************************************
@purpose : TopicAssignment Trigger.
@Created Date : 18Aug 2016.
************************************************************************************************************************/
trigger TopicAssignmentTrigger on TopicAssignment (before insert, after insert, after delete, after undelete) {

    TriggerFactory.createHandler(TopicAssignment.sObjectType);
}