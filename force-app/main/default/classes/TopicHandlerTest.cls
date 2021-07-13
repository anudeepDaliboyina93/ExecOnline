@isTest
public class TopicHandlerTest {
    @testSetup
    // Creating Test Data
    public static  void testData() {

    }

    public TestMethod static void positiveTesting(){
        Test.startTest();
            List<Topic> topicList = new List<Topic>();

            // Creating new Topic record
            for(integer count=0; count<210; count++){
                Topic topicRecord = new Topic();
                topicRecord.Name = 'TestTopic'+count;
                topicRecord.Description = 'TopicDescription'+count;
                topicList.add(topicRecord);
            }

            // insert standart Topic record
            INSERT topicList;

            List<Topic__c> topicCustomList = [SELECT Id , Name FROM Topic__c];

            // assertEquals for newly created custom object Topic__c record
            System.assertEquals(topiccustomList.size(), 210);

            for(Topic topicRec :[SELECT Id, Description FROM Topic]){
                topicRec.Description = 'DESC';
            }
            UPDATE topicList;

            List<Topic> topicstandardList= [SELECT id FROM Topic LIMIT 110];

            // delete standard object Topic record
            DELETE topicstandardList;

            // Fetch custom object Topic__c record
            topicCustomList = [SELECT id , Name FROM Topic__c];

            // assertEquals for custom object Topic__c record
            System.assertEquals(topicCustomList.size(), 100);


        Test.stopTest();
    }

    public TestMethod static void createCustTopicListToUpdateTest() {

        Topic topicA = new Topic(Name = 'TestA', Description = 'DescriptionA');
        Topic topicB = new Topic(Name = 'TestB', Description = 'DescriptionB');

        Test.startTest();
        TopicHandler th = new TopicHandler();
        th.createCustTopicListToUpdate(topicA, topicB);


        Test.stopTest();


    }
}