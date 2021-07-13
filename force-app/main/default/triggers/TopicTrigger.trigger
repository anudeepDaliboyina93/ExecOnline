/*************************************************************************************************************************
@purpose: Topic Trigger.
@Created Date : 18 Aug 2016
**************************************************************************************************************************/
trigger TopicTrigger on Topic (after insert, after update, after delete, after undelete) {
    
    TriggerFactory.createHandler(Topic.sObjectType);
 
}