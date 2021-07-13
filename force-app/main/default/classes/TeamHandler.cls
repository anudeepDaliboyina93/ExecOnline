public with sharing class TeamHandler implements ITrigger {
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
        Team__c team = (Team__c)so;

        if (team.Team_Name__c != null) {
            enqueue(team, 'POST');
        }
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        Team__c team = (Team__c)so;
        Team__c oldTeam = (Team__c)oldSo;

        if (CalloutBuffer.hasIntegrationFieldChanged(team, oldTeam) && team.Team_Name__c != null) {
            enqueue(team, 'PUT');
        }
    }

    public void afterDelete(SObject so) {
        Team__c team = (Team__c)so;

        if (team.Team_Name__c != null) {
            enqueue(team, 'DELETE');
        }
    }

    public void afterUnDelete(SObject so) {
        Team__c team = (Team__c)so;

        if (team.Team_Name__c != null) {
            enqueue(team, 'POST');
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