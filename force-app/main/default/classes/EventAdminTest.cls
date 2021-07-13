@isTest
private class EventAdminTest {
    
    @testSetup static void setupTestRecords() {
        
      Contact con    = TestDataFactory.getContact();
      Id      acctId = con.AccountId;

      insert con;

      Opportunity opp = TestDataFactory.getNewBusinessOpportunity(acctId);

      insert opp;

      Event newEvent = new Event();

      newEvent.WhatId        = opp.Id;
      newEvent.WhoId         = con.Id;
      newEvent.StartDateTime = Datetime.now();
      newEvent.EndDateTime   = Datetime.now();
      newEvent.Status__c     = 'Scheduled';

      insert newEvent;

    }

    @isTest private static void testGetEvents () {

        Id oppId  = [SELECT Id FROM Opportunity LIMIT 1].Id;

        Test.startTest();

        List<Event> events = EventAdmin.getEvents(oppId);
        
        Test.stopTest();

        System.assertEquals(1, events.size());
    }

    @isTest private static void testDeleteEvents () {

        Id eventId = [SELECT Id FROM Event LIMIT 1].Id;

        Test.startTest();

        EventAdmin.deleteEvent(eventId);

        Test.stopTest();


        System.assertEquals(0, [SELECT Id FROM Event].size());
    }

    @isTest private static void testManageEvents () {

        Id eventId = [SELECT Id FROM Event LIMIT 1].Id;

        Test.startTest();

        EventAdmin.manageEvent(eventId, 'Planned', 'Testing description');

        Test.stopTest();

        Event updatedEvent = [SELECT Id, Status__c, Description FROM Event LIMIT 1];

        System.assertEquals('Planned', updatedEvent.Status__c);
        System.assertEquals('Testing description', updatedEvent.Description);
    }
}