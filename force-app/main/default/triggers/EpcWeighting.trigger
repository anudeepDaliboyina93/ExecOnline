trigger EpcWeighting on EPC_Weighting__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run();
}