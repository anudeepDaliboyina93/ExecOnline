@isTest
public class TopicAssignmentHandlerTest {
    @testSetup
    // Creating Test Data
    public static  void testData(){

        List<Account > accountList = new List<Account >();
        List<TopicAssignment> topicAssignmentList = new List<TopicAssignment>();
        List<Topic> topicList = new List<Topic>();

        // Creating new account record
        for(integer count=0; count<210; count++){
            Account accountRcord = new Account(Name ='TestAccount'+count);
            accountList.add(accountRcord);
        }

        // insert account record
        INSERT accountList ;

        // Creating new Topic record
        for(integer count=0; count<210; count++){

            Topic topicRecord = new Topic();
            topicRecord.Name = 'TestTopic'+count;
            topicRecord.Description = 'Description'+count;
            topicList.add(topicRecord);
        }

        // insert Topic record
        INSERT topicList;

        // Creating new TopicAssignment record
        for(integer count=0; count<210; count++){

            TopicAssignment topicAssignmentRecord= new TopicAssignment();
            topicAssignmentRecord.EntityId = accountList[count].id;
            topicAssignmentRecord.TopicId = topicList[count].id;
            topicAssignmentList.add(topicAssignmentRecord);
        }

        // insert TopicAssignment record
        INSERT topicAssignmentList;
    }

    private testMethod static void topicAssignmentHandlerTest(){
        Test.startTest();
            // Fetch newly created custom object Topic_Assignment__c record
            List<Topic_Assignment__c> custTopicAssignmentList = [SELECT id , Name FROM Topic_Assignment__c];
            System.assertEquals(custTopicAssignmentList.size(), 210);

            // Fetch standard object TopicAssignment record
            List<TopicAssignment> stdTopicAssignmentList = [SELECT id FROM TopicAssignment LIMIT 110];

            // delete standard object TopicAssignment record
            DELETE stdTopicAssignmentList;


            custTopicAssignmentList = [SELECT id , Name FROM Topic_Assignment__c];

            // assertEquals for custom object Topic_Assignment__c record
            System.assertEquals(custTopicAssignmentList.size(), 100);
        Test.stopTest();

    }

    private static void updateTopicCountOnCaseTest() {
        Test.startTest();
        Account acc = new Account(Name='Acme' + System.now().millisecond(), Account_Type__c = '2. Key');
		insert acc;
		Entitlement en = new Entitlement();
    	en.Name = 'TestEntitlement';
    	en.AccountId = acc.Id;
    	insert en;

		Contact contact = new Contact(firstname = 'test' + System.now().millisecond(), lastname = 'test', accountId = acc.id);
        insert contact;
		TriggerConfiguration__c tc = [select Case_Entitlement__c, Id from TriggerConfiguration__c where case_entitlement__c != null limit 1];
		Case c = new Case(ContactId=contact.id, Status = 'Our Turn', EntitlementId = en.id);
		insert c;

        Case[] caseList = [select id from Case LIMIT 10];
        system.assertEquals(1, caseList.size());
        Set<Id> caseIdSet = new Set<Id>();
        for (Case ca : caseList) {
            caseIdSet.add(ca.id);
        }
        Case ca = caseList[0];
        system.assertEquals(1, caseIdSet.size());
        system.assert(caseIdSet.isEmpty());

        TopicAssignmentHandler tah = new TopicAssignmentHandler();
        tah.updateTopicCountOnCase(new Set<Id>{ca.id});
        Test.stopTest();
        tah.updateTopicCountOnCase(new Set<Id>{ca.id});


    }
}