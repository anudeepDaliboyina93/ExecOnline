public without sharing class EventAdmin {
    
    @AuraEnabled(cacheable=true)
    public static List<Event> getEvents(String oppId){

            Set<Id> eventIds = new Set<Id>();
            List<EventRelation> ers = [SELECT Id, RelationId, EventId FROM EventRelation WHERE RelationId = :oppId];

            for (EventRelation er : ers){
                eventIds.add(er.EventId);
            }
            return [SELECT Id, ActivityDate, Subject, Status__c, Description FROM Event WHERE Id IN:eventIds ORDER BY ActivityDate];
      
    }

    @AuraEnabled
    public static string deleteEvent(String eventId){
      
            delete [SELECT Id FROM Event WHERE Id=:eventId];

            return 'deleted';
      
    }
    @AuraEnabled
    public static string manageEvent(String eventId, String status, String notes){
    
            Event e = [SELECT Id, Status__c, Description FROM Event WHERE Id=:eventId];

            e.Status__c = status;
            e.Description = notes;

            update e;

            return 'managed';
      
    }

}