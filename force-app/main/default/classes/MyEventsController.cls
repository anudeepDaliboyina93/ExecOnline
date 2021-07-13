public with sharing class MyEventsController {

    @AuraEnabled(cacheable=true)
    public static List<Event> getMyEvents(){
        return [SELECT Id, ActivityDateTime, Subject, Status__c 
                FROM Event 
                WHERE OwnerId = :UserInfo.getUserId() 
                    AND ActivityDateTime > :System.now().addDays(-7)
                    AND ActivityDateTime < :System.now().addDays(7) 
                ORDER BY ActivityDateTime DESC];
    }

    @AuraEnabled
    public static Id setEventStatus(Id eventId, String status) {
        update new Event(Id = eventId, Status__c = status);
        return eventId;
    }

}