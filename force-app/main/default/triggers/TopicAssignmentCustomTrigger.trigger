/*************************************************************************************************************************
@purpose: Topic Assignment Trigger(Custom).
@Created Date : 18 Aug 2016
**************************************************************************************************************************/
trigger TopicAssignmentCustomTrigger on Topic_Assignment__c (after insert, after update) {
    
    TriggerFactory.createHandler(Topic_Assignment__c.sObjectType);
 
}