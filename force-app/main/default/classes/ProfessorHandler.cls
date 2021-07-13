public with sharing class ProfessorHandler implements ITrigger {
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
        Professor__c professor = (Professor__c)so;

        if (professor.Program__c != null && professor.Contact__c != null) {
            enqueue(professor, 'POST');
        }
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        Professor__c professor = (Professor__c)so;
        Professor__c oldProfessor = (Professor__c)oldSo;

        if (CalloutBuffer.hasIntegrationFieldChanged(professor, oldProfessor) && professor.Program__c != null && professor.Contact__c != null) {
            enqueue(professor, 'PUT');
        }
    }

    public void afterDelete(SObject so) {
        Professor__c professor = (Professor__c)so;

        if (professor.Program__c != null && professor.Contact__c != null) {
            enqueue(professor, 'DELETE');
        }
    }

    public void afterUnDelete(SObject so) {
        Professor__c professor = (Professor__c)so;

        if (professor.Program__c != null && professor.Contact__c != null) {
            enqueue(professor, 'POST');
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