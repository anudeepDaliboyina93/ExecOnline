trigger StudentEvent on Student_Event__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run();
}