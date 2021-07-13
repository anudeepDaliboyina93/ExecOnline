public with sharing class SectionHandler implements ITrigger {
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
        Section__c section = (Section__c)so;

        if (section.Section_Name__c != null) {
            enqueue(section, 'POST');
        }
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        Section__c section = (Section__c)so;
        Section__c oldSection = (Section__c)oldSo;

        if (CalloutBuffer.hasIntegrationFieldChanged(section, oldSection) && section.Section_Name__c != null) {
            enqueue(section, 'PUT');
        }
    }

    public void afterDelete(SObject so) {
        Section__c section = (Section__c)so;

        if (section.Section_Name__c != null) {
            enqueue(section, 'DELETE');
        }
    }

    public void afterUnDelete(SObject so) {
        Section__c section = (Section__c)so;

        if (section.Section_Name__c != null) {
            enqueue(section, 'POST');
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