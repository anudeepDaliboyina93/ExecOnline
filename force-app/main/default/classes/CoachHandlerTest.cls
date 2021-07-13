@isTest
public class CoachHandlerTest {

    public static testMethod void testCoachHandler() {
        Program__c program = new Program__c(friendly_name__c = 'test', short_name__c = 'test');
        insert program;
        Account acct = new Account(Name = 'Test Account');
		insert acct;
        Contact contact = new Contact(firstname = 'test', lastname = 'test', accountid = acct.id);
        insert contact;

        Coach__c coach = new Coach__c(Program__c = program.Id, Contact__c = contact.id);
        insert coach;

        delete coach;

        undelete coach;
    }
}