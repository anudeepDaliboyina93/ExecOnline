@isTest
public class MyEventsSlackReminder_SchBatchTest {
    
    @isTest
    static void testBatchExecution() {

        Account acc = TestDataFactory.getAccount();

        insert acc;

        Opportunity opp = TestDataFactory.getNewBusinessOpportunity(acc.Id);

        insert opp;

        Event e = new Event(DurationInMinutes=10, ActivityDateTime = System.now().addMinutes(-50), Status__c = 'Scheduled', Subject = 'test', WhatId = opp.Id);
        insert e;

        Test.startTest();
        MyEventsSlackReminder_SchBatch schBatch = new MyEventsSlackReminder_SchBatch();
        schBatch.execute(null);
        Test.stopTest();
        
        // nothing to assert
    }

}