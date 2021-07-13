public with sharing class CoachHandler implements ITrigger {
    private CalloutBuffer.ObjectsToEnqueueWrapper objectsToEnqueue = new CalloutBuffer.ObjectsToEnqueueWrapper();

    public void bulkBefore() {
    }

    public void bulkAfter() {
    }

    public void beforeInsert(SObject so) {

    }

    public void beforeUpdate(SObject oldSo, SObject so) {

    }

    public void beforeDelete(SObject so) {
    }

    public void beforeUnDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
        Coach__c coach = (Coach__c)so;

        if (coach.Program__c != null && coach.Contact__c != null) {
            enqueue(coach, 'POST');
        }
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        Coach__c coach = (Coach__c)so;
        Coach__c oldCoach = (Coach__c)oldSo;

        if (CalloutBuffer.hasIntegrationFieldChanged(coach, oldCoach) && coach.Program__c != null && coach.Contact__c != null) {
            enqueue(coach, 'PUT');

        }
    }

    public void afterDelete(SObject so) {
        Coach__c coach = (Coach__c)so;

        if (coach.Program__c != null && coach.Contact__c != null) {
            enqueue(coach, 'DELETE');
        }
    }

    public void afterUnDelete(SObject so) {
        Coach__c coach = (Coach__c)so;

        if (coach.Program__c != null && coach.Contact__c != null) {
            enqueue(coach, 'POST');
        }
    }

    public void andFinally() {
        if (!objectsToEnqueue.isEmpty()) {
            CalloutBuffer.enqueueObjects(objectsToEnqueue);
        }
    }

    private void enqueue(SObject so, String action) {
        objectsToEnqueue.actionType = action;
        objectsToEnqueue.objects.add(so);
    }
}