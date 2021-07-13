public without sharing class CCS_KnowledgeSearchController{
    @AuraEnabled
    public static SearchWrapper searchForArticles(String searchText, Id contactId){
        SearchWrapper searchWrap = new SearchWrapper();
		String search = '*' + escapeSOSLTerm(searchText) + '*';
        list<Program__c> topicIds = [SELECT Program_Family__r.Name,Program_Family__r.Topic__r.TopicId__c,Program_Family__r.Topic__r.Name 
                                     FROM Program__c WHERE Id IN (SELECT Program__c FROM Student__c WHERE Contact__c = :contactId) 
                                     AND Program_Family__r.Status__c = 'Active'];

        List<Id> listOfTopicIds = new List<Id>();        

        Id globalTopic = [SELECT Id FROM Topic WHERE Name IN ('Global') AND ManagedTopicType = 'Navigational'].Id;

        if(topicIds.isEmpty())
            listOfTopicIds.add(globalTopic);
        else{
            for(Program__c prog : topicIds){
                if(prog.Program_Family__r.Topic__c != null)
                    listOfTopicIds.add(prog.Program_Family__r.Topic__r.TopicId__c);
                boolean dobbs = false;
                if(prog.Program_Family__r.Topic__c != null && prog.Program_Family__r.Name.indexOf('CIMA') != -1)
                    dobbs = true;
                if(!dobbs)
                    listOfTopicIds.add(globalTopic);
            }
        }

        String query;
        try{
            if(!listOfTopicIds.isEmpty()){
                query = 'FIND {' + search + '} IN ALL FIELDS RETURNING '+
                    'Knowledge__kav (Id, Title, LastModifiedDate, ArticleNumber, Summary, UrlName WHERE Id IN '+
                    '(SELECT EntityId FROM TopicAssignment WHERE TopicId IN: listOfTopicIds) AND PublishStatus = \'Online\' AND Language = \'en_US\')';
                
                List<List<SObject>> results = System.Search.query(query);
                
                if(!results[0].isEmpty()){
                    searchWrap.knowledgeArticlesList = (List<Knowledge__kav>) results[0];
                    searchWrap.resultCount += results[0].size();
                }
            }
            return searchWrap;
		}catch(Exception e){throw new AuraHandledException(e.getMessage());}
	}
    
    public static String escapeSOSLTerm(String term){
        term = String.escapeSingleQuotes(term.replace('\'', '\\'));
        Pattern reservedPattern = pattern.compile('[\\?&\\|!{}\\[\\]\\(\\)\\^~\\*:\\\"\\+-]');
        Matcher myMatcher = reservedPattern.matcher(term);
        List<Integer> escapeIndexs = new List<Integer>();
        while(true){
            if(myMatcher.find()){
                escapeIndexs.add(myMatcher.start());
            }else{
                break;
            }
        }
        escapeIndexs.sort();
        for(Integer i = escapeIndexs.size()-1; i>=0; i--){
            Integer escapeIndex = escapeIndexs[i];
            term = term.substring(0, escapeIndex) + '\\' + term.substring(escapeIndex);
        }
        return term; 
    }  
    
    public class SearchWrapper{
        @AuraEnabled public List<Knowledge__kav> knowledgeArticlesList;
        @AuraEnabled public Integer resultCount;
        
        public SearchWrapper(){
            this.knowledgeArticlesList = new List<Knowledge__kav>();
            this.resultCount = 0;
        }
    }
    
}