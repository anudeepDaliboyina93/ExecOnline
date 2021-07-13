/**
 * TouchContactBatch.cls
 * Copyright 2015 Wired Triangle, LLC
 * http://www.wiredtriangle.com
 */
global with sharing class TouchContactBatch implements Database.Batchable<sObject> {

    List<Contact_For_Sync__c> contactsForSync = new List<Contact_For_Sync__c>();
    List<Id> contactIdsToTouch = new List<Id>();

    global TouchContactBatch() {
        contactsForSync = [select id, contact__c from Contact_For_Sync__c order by createddate asc];
        for (Contact_For_Sync__c contactForSync : contactsForSync) {
            contactIdsToTouch.add(contactForSync.Contact__c);
        }
    
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'select id from Contact where id in :contactIdsToTouch';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Contact> scope) {
      update scope;

      List<Contact_For_Sync__c> deleteContactsForSync = [SELECT Id, contact__c FROM Contact_For_Sync__c WHERE contact__c IN:scope];

    if (!deleteContactsForSync.isEmpty()){
        delete deleteContactsForSync;
        database.emptyRecycleBin(deleteContactsForSync);
      }
    }

    global void finish(Database.BatchableContext BC) {
      
    }
}