@isTest
public class MyEventsControllerTest {
    
    @isTest
    static void testGetAndUpdateEvent() {
        Event e = new Event(DurationInMinutes=60, ActivityDateTime = System.now(), Status__c = 'Scheduled', Subject = 'test');
        insert e;

        Test.startTest();
        List<Event> myEvents = MyEventsController.getMyEvents();
        Id eventId = MyEventsController.setEventStatus(myEvents[0].Id, 'Completed');
        Test.stopTest();

        e = [SELECT Id, Status__c FROM Event WHERE Id = :eventId LIMIT 1];
        System.assertEquals(1, myEvents.size());
        System.assertEquals('Completed', e.Status__c);
    }
    
}