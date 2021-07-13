@isTest
public class AnonymizeContactsForPurgeBatchTest {
    
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

        
    }
    @isTest static void anonymizeContacts() {

        List<Contact> contacts = [SELECT Id FROM Contact];
        Set<Id> idSet = new Set<Id>();

        for (Contact c : contacts){

            idSet.add(c.Id);
        }

        Test.startTest();
        AnonymizeContactsForPurgeBatch acpb = new AnonymizeContactsForPurgeBatch(idSet);
        Id anonymizeBatch = Database.executeBatch(acpb);
        Test.stopTest();
        

    }
}