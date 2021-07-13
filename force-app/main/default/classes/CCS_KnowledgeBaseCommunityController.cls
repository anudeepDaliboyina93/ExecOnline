public without sharing class CCS_KnowledgeBaseCommunityController{
    @AuraEnabled
    public static List<ConnectApi.ManagedTopic> getNavigationTopics(Id contactId, Id communityId){
        set<string> setTopicIds = new set<string>();
        string dobbsTopic;
        if(contactId != null){
            list<Program__c> topicIds = [SELECT Program_Family__r.Name,Program_Family__r.Topic__r.TopicId__c,Program_Family__r.Topic__r.Name 
                                         FROM Program__c WHERE Id IN (SELECT Program__c FROM Student__c WHERE Contact__c = :contactId) 
                                         AND Program_Family__r.Status__c = 'Active'];
            for(Program__c prog : topicIds){
                if(prog.Program_Family__r.Topic__c != null && prog.Program_Family__r.Name.indexOf('CIMA') != -1){
                    dobbsTopic = prog.Program_Family__r.Topic__r.TopicId__c;
                }
                else if(prog.Program_Family__r.Topic__c != null)
                    setTopicIds.add(prog.Program_Family__r.Topic__r.TopicId__c);
            }
        }

        string commId;
        commId = test.isRunningTest() ? communityId : Network.getNetworkId();

        ConnectApi.ManagedTopicCollection mtCollection = ConnectAPI.ManagedTopics.getManagedTopics(commId, ConnectApi.ManagedTopicType.Navigational,2);
        List<ConnectApi.ManagedTopic> topicList = new List<ConnectApi.ManagedTopic>();
        for(ConnectApi.ManagedTopic mtopic : mtCollection.managedTopics){
            if(dobbsTopic != null && dobbsTopic == mtopic.topic.id)
                topicList.add(mtopic);
            else if(dobbsTopic == null && (mtopic.topic.name == 'Global' || setTopicIds.contains(mtopic.topic.id)))
                topicList.add(mtopic);
        }
        return topicList;
    }
    
    @AuraEnabled
    public static Contact getContact(string contactId){
        Contact exoContact = new Contact();
        if(contactId != null)
            exoContact = [SELECT Id,AccountId,Name,Email FROM Contact WHERE Id =: contactId];
        
        return exoContact;
    }
    
    @AuraEnabled
    public static Case createCase(Case newCase){
        
        //Fetching the assignment rules on case
        AssignmentRule AR = new AssignmentRule();
        AR = [SELECT Id FROM AssignmentRule WHERE SobjectType = 'Case' AND Active = TRUE LIMIT 1];
        
        //Creating the DMLOptions for "Assign using active assignment rules" checkbox
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;
        
        //Setting the DMLOption on Case instance
        newCase.setOptions(dmlOpts);
        insert newCase;
        
        return newCase;
    }
}