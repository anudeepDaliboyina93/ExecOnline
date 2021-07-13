/**
 *@ purpose : Topic Assignment Trigger Handler helper.
 *@ Created Date: 22 Aug 2016
 */
public with sharing class TopicAssignmentHandlerHelper { 
    
    /**
     *@purpose : To update topic count on case.
     *@param : set of case id.
     *@return :-
    **/
    public static void updateTopicCountOnCase(Set<Id> caseIdSet){
        
        Map<Id, Integer> caseIdToTopicCountMap = getCaseIdToTopicCountMap(caseIdSet);
        List<Case> caseListToUpdate = new List<Case>();
        
        for(Case caseRec :[SELECT Id, Topic_Count__c
                           FROM Case
                           WHERE Id IN :caseIdToTopicCountMap.keySet()]){
                               
            caseListToUpdate.add(new Case(Id = caseRec.Id,
                                          Topic_Count__c = caseIdToTopicCountMap.get(caseRec.Id)
                                          ));
        }
        
        UPDATE caseListToUpdate;
    }
    
    /**
     *@purpose : Built the map of Case Id and id count from topic assignment. 
     *@param : set of case Id.
     *@return : Map of case Id and Topic count of that id.
    **/
    private static Map<Id, Integer> getCaseIdToTopicCountMap(Set<Id> caseIdSet){
        
        Map<Id, Integer> caseIdToTopicCountMap = new Map<Id, Integer>();
        
        if(!caseIdSet.isEmpty()){
            for(TopicAssignment topicAssignmentRec : [SELECT Id, EntityId
                                                      FROM TopicAssignment
                                                      WHERE EntityId IN :caseIdSet]){
                
                if(caseIdToTopicCountMap.containskey(topicAssignmentRec.EntityId)){
                    caseIdToTopicCountMap.put(topicAssignmentRec.EntityId, 
                                              caseIdToTopicCountMap.get(topicAssignmentRec.EntityId)+1);
                }else{
                    caseIdToTopicCountMap.put(topicAssignmentRec.EntityId, 1);
                }
            }
            
            return caseIdToTopicCountMap;
        }
        else{
            return null;
        }
    }
}