/**
 *@ purpose : Topic Assignment(Custom) Trigger Handler for the Topic Assignment SObject. This class implements the ITrigger.
 *@ Created Date: 17 Aug 2016
 */
public with sharing class TopicAssignmentCustomHandler implements ITrigger {

    // Member variable to record Audit records
    private Map<Id, Integer> caseIdToTopicAssignCountMap = new Map<Id, Integer>();

    // Constructor
    public TopicAssignmentCustomHandler(){

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

    public void beforeUnDelete(SObject so)
    {
    }

    public void afterInsert(SObject sObj) {

        // Topic_Assignment__C topicAssignment = (Topic_Assignment__C) sObj;
        //
        // if(topicAssignment.Case__c != null){
        //     calculateCaseTopicCount(true, topicAssignment);
        // }
    }

    public void afterUpdate(SObject oldSObj, SObject sObj){

        // Topic_Assignment__C topicAssignment = (Topic_Assignment__C) sObj;
        // Topic_Assignment__C oldTopicAssignment = (Topic_Assignment__C) oldSObj;
        //
        // buildCaseIdToTopicCountMap(topicAssignment, oldTopicAssignment);

    }

    public void afterDelete(SObject sObj) {
    }

    public void afterUndelete(SObject sObj){
    }

    /**
     * andFinally
     * This method is called once all records have been processed by the trigger. Use this
     * method to accomplish any final operations such as creation or updates of other records.
     */
    public void andFinally() {
        // updateCases(caseIdToTopicAssignCountMap);
    }

    /**
     *@purpose: To build map of Case id to topic count.
    **/
    private void buildCaseIdToTopicCountMap(Topic_Assignment__C newTopicAssignment, Topic_Assignment__C oldTopicAssignment){

        // if(newTopicAssignment.Case__c != oldTopicAssignment.Case__c &&
        //     (newTopicAssignment.Case__c != null || oldTopicAssignment.Case__c != null)){
        //
        //     if(newTopicAssignment.Case__c != null){
        //         calculateCaseTopicCount(true, newTopicAssignment);
        //     }
        //     if(oldTopicAssignment.Case__c != null || newTopicAssignment.Case__c == null){
        //         calculateCaseTopicCount(false, oldTopicAssignment);
        //     }
        // }
    }

    /**
     *@ Purpose To count topic assignment for case
    **/
    private void calculateCaseTopicCount(Boolean isNewCase, Topic_Assignment__C topicAssignment){

        // if(isNewCase){
        //     if(caseIdToTopicAssignCountMap.containsKey(topicAssignment.Case__c)){
        //             caseIdToTopicAssignCountMap.put(topicAssignment.Case__c,
        //                                             caseIdToTopicAssignCountMap.get(topicAssignment.Case__c) + 1);
        //     }else{
        //         caseIdToTopicAssignCountMap.put(topicAssignment.Case__c, 1);
        //     }
        // }else{
        //     if(caseIdToTopicAssignCountMap.containsKey(topicAssignment.Case__c)){
        //             caseIdToTopicAssignCountMap.put(topicAssignment.Case__c,
        //                                             caseIdToTopicAssignCountMap.get(topicAssignment.Case__c) - 1);
        //     }else{
        //         caseIdToTopicAssignCountMap.put(topicAssignment.Case__c, -1);
        //     }
        // }
    }

    /**
     *@Purpose: To Update topic assignment count on cases.
     *@Param: Map of case Id and count
     *@return:-
    **/
    private void updateCases(Map<Id, Integer> caseIdToTopicAssignCountMap){

    //     if(!caseIdToTopicAssignCountMap.isEmpty()){
    //
    //         List<Case> caseList = new List<Case>();
    //
    //         for(Case caseRec :[SELECT Id, Topic_Count__c
    //                            FROM Case WHERE Id IN :caseIdToTopicAssignCountMap.keySet()]){
    //
    //             Integer TopicAssignmentCount = 0;
    //
    //             if(caseRec.Topic_Count__c != null){
    //                 TopicAssignmentCount = caseIdToTopicAssignCountMap.get(caseRec.ID) +
    //                                        Integer.valueOf(caseRec.Topic_Count__c);
    //             }else{
    //                 TopicAssignmentCount = Integer.valueOf(caseRec.Topic_Count__c);
    //             }
    //
    //             if(TopicAssignmentCount < 0)
    //                 TopicAssignmentCount = 0;
    //
    //             caseList.add(new Case(Id = caseRec.ID,
    //                                   Topic_Count__c = TopicAssignmentCount));
    //         }
    //
    //         UPDATE caseList;
    //     }
    // }

}
}