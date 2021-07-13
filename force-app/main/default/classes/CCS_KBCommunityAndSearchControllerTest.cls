@IsTest (SeeAllData=true)
private class CCS_KBCommunityAndSearchControllerTest{
    @isTest
    static void getNavigationTopicsAndSearchTest(){
        Callout_Buffer_Configuration__c cbc = Callout_Buffer_Configuration__c.getOrgDefaults();
        cbc.Callout_Buffer_Enabled__c = false;
        update cbc;

        Account a = new Account(Name = 'Test Account', EPC_Autocalculation_Enabled__c = false);
        insert a;

        Contact c = new Contact(LastName = 'TestLast', AccountId = a.id);
        insert c;

        Id commId;
        Id globalTopic;
        Id dobbsManagedTopic;
        Id progManagedTopic;

        ConnectApi.CommunityPage cp = ConnectApi.Communities.getCommunities();
        for(ConnectApi.Community myCommunity : cp.communities){
            if(myCommunity.name == 'ExecOnline Service Center')
                commId = myCommunity.id;
        }

        ConnectApi.ManagedTopicCollection mtCollection = ConnectAPI.ManagedTopics.getManagedTopics(commId, ConnectApi.ManagedTopicType.Navigational,2);
        for(ConnectApi.ManagedTopic mtopic : mtCollection.managedTopics){
            if(mtopic.topic.name == 'Global')
                globalTopic = mtopic.topic.id;
            else if(mtopic.topic.name.indexOf('Dobbs') != -1)
                dobbsManagedTopic = mtopic.topic.id;
            else
                progManagedTopic = mtopic.topic.id;
        }

        Id progTopic = [SELECT Id FROM Topic__c WHERE TopicId__c =: progManagedTopic].Id;
        Id dobbsTopic = [SELECT Id FROM Topic__c WHERE TopicId__c =: dobbsManagedTopic].Id;

        Program_Family__c testProgFam = new Program_Family__c(
            Name = 'Test Family',
            Status__c = 'Active',
            Topic__c = progTopic);
        insert testProgFam;

        Program__c testProg = new Program__c(
            Name = 'Test Progam',
            Short_Name__c = 'Test',
            Friendly_Name__c = 'Test',
            Program_Family__c = testProgFam.Id);
        insert testProg;

        Student__c testStudent = new Student__c(
            Contact__c = c.Id,
            Program__c = testProg.Id
        );
        insert testStudent;

        cbc.Callout_Buffer_Enabled__c = true;
        update cbc;

        Knowledge__kav testArticle = [SELECT Id, Title, LastModifiedDate, ArticleNumber, Summary, UrlName FROM Knowledge__kav WHERE Id IN (SELECT EntityId FROM TopicAssignment WHERE TopicId =: globalTopic) AND PublishStatus = 'Online' AND Language = 'en_US' LIMIT 1];
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = testArticle.Id;
        Test.setFixedSearchResults(fixedSearchResults);

        system.Test.startTest();
        CCS_KnowledgeSearchController.searchForArticles('test',null);
        
        CCS_KnowledgeBaseCommunityController.getNavigationTopics(c.Id,commId);
        CCS_KnowledgeBaseCommunityController.getContact(c.Id);

        CCS_KnowledgeSearchController.searchForArticles('test',c.Id);

        testProgFam.Name = 'CIMA Test';
        testProgFam.Topic__c = dobbsTopic;
        update testProgFam;

        CCS_KnowledgeBaseCommunityController.getNavigationTopics(c.Id,commId);
        CCS_KnowledgeSearchController.searchForArticles('test?',c.Id);

        testProgFam.Name = 'Test No Topic';
        testProgFam.Topic__c = null;
        update testProgFam;

        CCS_KnowledgeBaseCommunityController.getNavigationTopics(c.Id,commId);
        CCS_KnowledgeSearchController.searchForArticles('test?',c.Id);
        
        system.Test.stopTest();
    }
    @IsTest
    static void createCaseTest(){
        Callout_Buffer_Configuration__c cbc = Callout_Buffer_Configuration__c.getOrgDefaults();
        cbc.Callout_Buffer_Enabled__c = false;
        update cbc;

        Account a = new Account(Name = 'Test Account');
        insert a;

        Contact c = new Contact(LastName = 'TestLast', AccountId = a.id, FirstName='TestFirst', Email='test@test.org');
        insert c;
        
        cbc.Callout_Buffer_Enabled__c = true;
        update cbc;

        Case cs = new Case(ContactId = c.Id,
                           AccountId = a.Id,
                           SuppliedName = c.Name,
                           SuppliedEmail = c.Email,
                           Origin = 'Web',
                           Subject = 'Test Subject',
                           Description = 'test description');
        
        system.Test.startTest();
        CCS_KnowledgeBaseCommunityController.createCase(cs);
        system.Test.stopTest();
    }
}