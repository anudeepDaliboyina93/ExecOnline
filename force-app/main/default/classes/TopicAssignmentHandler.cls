/**
 *@ purpose : Topic Assignment Trigger Handler for the Topic SObject. This class implements the ITrigger.
 *@ Created Date: 17 Aug 2016
 */
public with sharing class TopicAssignmentHandler implements ITrigger {

    //Member variable
    private List<Topic_Assignment__c> topicAssignmentListToUpsert = new List<Topic_Assignment__c>();
    private Set<String> topicAssignmentIdSet = new Set<String>();
    private Map<Id, Id> stdTopicIdToCustTopicIdMap;
    private Map<String, Schema.SObjectField> topicAssignmentFieldMap;
    private Set<Id> caseIdSet = new Set<Id>();

    // Constructor
    public TopicAssignmentHandler(){

    }

    /**
     * bulkBefore
     * This method is called prior to execution of a BEFORE trigger. Use this to cache
     * any data required into maps prior execution of the trigger.
    **/
    public void bulkBefore(){
    }

    public void bulkAfter(){
        if(Trigger.isInsert){
            stdTopicIdToCustTopicIdMap = buildStdTopicIdToCustTopicIdMap(Trigger.new);
            topicAssignmentFieldMap = Topic_Assignment__c.sObjectType.getDescribe().fields.getMap();
        }

    }

    public void beforeInsert(SObject so){
    }

    public void beforeUpdate(SObject oldSo, SObject so){
    }

    public void beforeDelete(SObject so) {
    }

    public void beforeUnDelete(Sobject so) {
        TopicAssignment topicAssignment = (TopicAssignment) so;
    }

    public void afterInsert(SObject sObj) {
        TopicAssignment topicAssignment = (TopicAssignment) sObj;
        topicAssignmentListToUpsert.add(createCustTopicAssignment(topicAssignment));
        if(topicAssignment.EntityType == 'Case'){
            caseIdSet.add(topicAssignment.EntityId);
        }
    }

    public void afterUpdate(SObject oldSObj, SObject sObj){
    }

    public void afterDelete(SObject sObj) {
        topicAssignmentIdSet.add(sObj.Id);
        TopicAssignment topicAssignment = (TopicAssignment) sObj;
        if(topicAssignment.EntityType == 'Case'){
            caseIdSet.add(topicAssignment.EntityId);
        }
    }

    public void afterUndelete(SObject sObj){
        TopicAssignment topicAssignment = (TopicAssignment) sObj;
        /* topicAssignmentListToUpsert.add(createCustTopicAssignment(topicAssignment));*/
    }

    /**
     *@ purpose: To build the map of standard topicId to custom topicId.
     *@ param : topicAssignmentList
     *@ return : stdTopicIdToCustTopicIdMap
    **/
    private Map<Id, Id> buildStdTopicIdToCustTopicIdMap(List<TopicAssignment> topicAssignmentList){

        Set<Id> stdTopicIdSet = getstdTopicIdSet(topicAssignmentList);
        Map<Id, Id> stdTopicIdToCustTopicIdMap = new Map<Id, Id>();

        for(Topic__c topicRec :[SELECT Id, TopicId__c
                                FROM Topic__c
                                WHERE TopicId__c IN :stdTopicIdSet ORDER BY CreatedDate DESC]){

            stdTopicIdToCustTopicIdMap.put(topicRec.TopicId__c, topicRec.Id);
        }

        return stdTopicIdToCustTopicIdMap;

    }

    private Set<Id> getstdTopicIdSet(List<TopicAssignment> topicAssignmentList) {

        Set<Id> stdTopicIdSet = new Set<Id>();

        for (TopicAssignment topicAssignment :topicAssignmentList) {

            stdTopicIdSet.add(topicAssignment.TopicId);
        }

        return stdTopicIdSet;
    }

    /**
     *@ purpose : To create Duplicate topic assignment record from standard Topic.
     *@ param   : TopicList
    **/
    private Topic_Assignment__c createCustTopicAssignment(TopicAssignment topicAssignment) {

        Topic_Assignment__c custTopicAssignment = new Topic_Assignment__c();

        if(stdTopicIdToCustTopicIdMap.containsKey(topicAssignment.TopicId)) {
            custTopicAssignment.TopicId__c = stdTopicIdToCustTopicIdMap.get(topicAssignment.TopicId);
        }

        if(!topicAssignmentFieldMap.isEmpty()) {

            String objectName = topicAssignment.EntityId.getSObjectType().getDescribe().getName();

            for(String fieldName : topicAssignmentFieldMap.keySet()) {

                Schema.DescribeFieldResult field = topicAssignmentFieldMap.get(fieldName).getDescribe();

                if(field.getType() == Schema.DisplayType.REFERENCE &&
                   objectName == String.valueOf(field.getReferenceTo()[0])) {

                    custTopicAssignment.put(fieldName, topicAssignment.EntityId);
                }

            }
        }

        custTopicAssignment.Topic_Assignment_Id__c = topicAssignment.Id;

        return custTopicAssignment;
    }

    /**
     * andFinally
     * This method is called once all records have been processed by the trigger. Use this
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally() {

        updateTopicCountOnCase(caseIdSet);
        UPSERT topicAssignmentListToUpsert Topic_Assignment_Id__c;
        deleteCustomTopicAssignment(topicAssignmentIdSet);
    }

    /**
     *@purpose : To update topic count on case.
     *@param : set of case id.
     *@return :-
    **/
    public void updateTopicCountOnCase(Set<Id> caseIdSet){

        List<Case> caseListToUpdate = new List<Case>();

        system.debug('**CaseIdSet :' + caseIdSet);

        if(!caseIdSet.isEmpty()){

            List<aggregateResult> aggregateResultList = [SELECT EntityId, COUNT(ID)
                                                         FROM TopicAssignment
                                                         WHERE EntityId IN :caseIdSet
                                                         GROUP BY EntityId];

            if(aggregateResultList.isEmpty()){
                for(Id caseId : caseIdSet){

                    caseListToUpdate.add(new Case(Id = caseId,
                                                  Topic_Count__c = 0));
                }
            }
            else{
                for(aggregateResult aggregateRec :aggregateResultList){

                    caseListToUpdate.add(new Case(Id = (Id)aggregateRec.get('EntityId'),
                                                  Topic_Count__c = (Decimal)aggregateRec.get('expr0')));
                }
            }
        }

        UPDATE caseListToUpdate;
    }
    /**
     *@ purpose : To Delete Duplicate topic assignment record which created from standard Topic.
     *@ param   : topicAssignmentIdSet : deleted topic assignment Id
    **/
    private void deleteCustomTopicAssignment(Set<String> topicAssignmentIdSet) {

        if(!topicAssignmentIdSet.isEmpty()) {

            List<Topic_Assignment__c> topicAssignmentsToDelete = [SELECT Id, Name
                                                                  FROM Topic_Assignment__c
                                                                  WHERE Topic_Assignment_Id__c IN :topicAssignmentIdSet];

            DELETE topicAssignmentsToDelete;
        }
    }
}