/**
 * TouchContactBatchTest.cls
 * Copyright 2015 Wired Triangle, LLC
 * http://www.wiredtriangle.com
 */
@isTest
private class TouchContactBatchTest {

    @isTest static void test_account_update() {

        Account account = new Account(Name = 'Test Account');
        insert account;

        Contact contact = new Contact(Lastname='Name', FirstName='Test', AccountId = account.Id);
        insert contact;
        Program__c program = new Program__c(Friendly_Name__c = 'Test', Short_Name__c = 'Test');
        insert program;

        Student__c student = new Student__c(contact__c = contact.Id, Program__c = program.Id);
        insert student;

        List<Contact> contacts = new List<Contact>();
        contacts.add(contact);

        Integer count = ([select id from Contact_For_Sync__c]).size();
        //system.assertEquals(3, count);

        Test.startTest();
        Database.executeBatch(new TouchContactBatch());
        Test.stopTest();
        count = ([select id from Contact_For_Sync__c]).size();
        system.assertEquals(0, count);

    }

    @isTest static void test_batch_no_records() {
        // There should be no error
        Database.executeBatch(new TouchContactBatch());
    }

}