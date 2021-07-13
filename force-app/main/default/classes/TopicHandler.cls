/**
 *@ purpose : Topic Trigger Handler for the Topic SObject. This class implements the ITrigger.
 *@ Created Date: 17 Aug 2016
 */
public with sharing class TopicHandler implements ITrigger {

    // Member variable to record Audit records
    private List<Topic__c> topicListToUpsert = new List<Topic__c>();
    private Set<String> topicIdSet = new Set<String>();

    // Constructor
    public TopicHandler (){

    }

    /**
     * bulkBefore
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
     */
    public void bulkBefore(){
    }

    public void bulkAfter(){

    }

    public void beforeInsert(SObject so){
    }

    public void beforeUpdate(SObject oldSo, SObject so){
    }

    public void beforeDelete(SObject so) {
    }

    public void beforeUnDelete(SObject so) {
        Topic topic = (Topic) so;
    }

    public void afterInsert(SObject sObj) {
        Topic topic = (Topic) sObj;
        createCustomTopic(topic);
    }

    public void afterUpdate(SObject oldSObj, SObject sObj){
        Topic newTopic = (Topic) sObj;
        Topic oldTopic = (Topic) oldSObj;
        createCustTopicListToUpdate(newTopic, oldTopic);
    }

    public void afterDelete(SObject sObj) {
        topicIdSet.add(sObj.Id);
    }

    public void afterUndelete(SObject sObj){
        Topic topic = (Topic) sObj;
        /*Topic topic = (Topic) sObj;
        createCustomTopic(topic);*/
    }

    /**
     *@ purpose : To create Duplicate topic record from standard Topic.
     *@ param   : TopicList
    **/
    @TestVisible private void createCustomTopic(Topic topicRec) {

        topicListToUpsert.add(new Topic__c(TopicId__c = topicRec.Id,
                                           Name = topicRec.Name,
                                           Description__c = topicRec.Description));
    }

    /**
     *@Purpose to create custom topic list for update.
     *@param : a) new Topic obj b) Old topic obj
    **/
    @TestVisible
    private void createCustTopicListToUpdate(Topic newTopic, Topic oldTopic){

        Topic__c custTopic = new Topic__c();
        Boolean isTopicChange = false;

        if(newTopic.Name != oldTopic.Name){
            isTopicChange = true;
            custTopic.Name = newTopic.Name;

        }
        if(newTopic.Description != oldTopic.Description){
            isTopicChange = true;
            custTopic.Description__c = newTopic.Description;
        }
        if(isTopicChange){
            custTopic.TopicId__c = newTopic.Id;
            topicListToUpsert.add(custTopic);
        }
    }


    /**
     *@ purpose : To Delete Duplicate topic record which created from standard Topic.
     *@ param   : TopicList : deleted topic list
    **/
    @TestVisible private void deleteCustomTopic(Set<String> topicIdSet) {

        if(!topicIdSet.isEmpty()) {

            List<Topic__c> topicListToDelete = [SELECT Id, Name
                                                FROM Topic__c
                                                WHERE TopicId__c IN :topicIdSet];

            DELETE topicListToDelete;
        }
    }

    /**
     * andFinally
     * This method is called once all records have been processed by the trigger. Use this
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally() {
        UPSERT topicListToUpsert TopicId__c;
        deleteCustomTopic(topicIdSet);
    }
}