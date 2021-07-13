@isTest
private class currentStudentBatchTest {

    @isTest static void test_account_update() {

        Account account = new Account(Name = 'Test Account');
        insert account;

        Contact contact = new Contact(Lastname='Name', FirstName='Test', AccountId = account.Id);
        insert contact;
        Program__c program = new Program__c(Friendly_Name__c = 'Test', Short_Name__c = 'Test');
        insert program;

        Program_Family__c pf = TestDataFactory.getProgramFamily();

        pf.Current_Student_Category__c = 'Current Student';

        insert pf;

        program.Program_Family__c = pf.Id;

        update program;

        Student__c student = new Student__c(contact__c = contact.Id, Program__c = program.Id);
        insert student;

        Test.startTest();
        Database.executeBatch(new currentStudentBatch());
        Test.stopTest();
   

    }

    @isTest static void test_batch_no_records() {
        // There should be no error
        Database.executeBatch(new currentStudentBatch());
    }

}