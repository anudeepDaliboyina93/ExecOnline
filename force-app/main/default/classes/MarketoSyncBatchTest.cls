@isTest
private class MarketoSyncBatchTest {

    @TestSetup
    static void testData(){
        Account account = new Account(Name = 'Test Account');
        insert account;

        List<Contact> contactList = new List<Contact>();
        Contact contact = new Contact(Lastname='Name', FirstName='Test', AccountId = account.Id, Marketo_Sync__c = false, Email = 'testname@test.com');
        Contact contact2 = new Contact(Lastname='Name', FirstName='Test1', AccountId = account.Id, Marketo_Sync__c = true, Email= 'testname2@test.com');
        Contact noStudents = new Contact(Lastname='Name', FirstName='Test2', AccountId = account.Id, Marketo_Sync__c = false, Email= 'testname3@test.com');
        contactList.add(contact);
        contactList.add(contact2);
        contactList.add(noStudents);
        insert contactList;

        List<Program__c> programList = new List<Program__c>();
        Date disable = Date.today().addMonths(-16);
        Program__c oldProgram = new Program__c(Friendly_Name__c = 'Test', Short_Name__c = 'Test', Course_End_Date__c = disable);
        programList.add(oldProgram);
        Program__c newProgram = new Program__c(Friendly_Name__c = 'Test2', Short_Name__c = 'Test2', Course_End_Date__c = Date.today());
        programList.add(newProgram);

        insert programList;
      

        List<Student__c> studentList = new List<Student__c>();
        Student__c oldStudent = new Student__c(contact__c = contact.Id, Program__c = oldProgram.Id);
        studentList.add(oldStudent);
        Student__c newStudent = new Student__c(contact__c = contact.Id, Program__c = newProgram.Id);
        studentList.add(newStudent);
        Student__c studentToDisable = new Student__c(contact__c = contact2.Id, Program__c = oldProgram.Id);
        studentList.add(studentToDisable);

        insert studentList;
    }
    @isTest static void syncContacts() {

        Test.startTest();
        MarketoSyncBatch msb = new MarketoSyncBatch();
        Id marketoBatch = Database.executeBatch(msb);
        Test.stopTest();
        

    }

}