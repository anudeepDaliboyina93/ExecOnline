trigger DealDesk on Commercial_Account_Hold__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run();
}