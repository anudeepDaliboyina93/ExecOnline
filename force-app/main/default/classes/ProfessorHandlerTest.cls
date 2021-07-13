@isTest
public class ProfessorHandlerTest {

    public static testMethod void testProfessorHandler() {
        Program__c program = new Program__c(friendly_name__c='test', short_name__c='test');
        insert program;
        Account acct = new Account(Name = 'Test Account');
		insert acct;
        Contact contact = new Contact(firstname = 'test', lastname = 'test', accountid = acct.id);
        insert contact;

        Professor__c professor = new Professor__c(Program__c= program.Id, Contact__c=contact.id);
        insert professor;

        delete professor;

        undelete professor;
    }
}