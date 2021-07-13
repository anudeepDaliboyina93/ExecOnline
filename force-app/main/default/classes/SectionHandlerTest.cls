@isTest
public class SectionHandlerTest {

    public static testMethod void testSectionHandler() {
        Program__c program = new Program__c(friendly_name__c = 'test', short_name__c = 'test');
        insert program;

        //Contact contact = new Contact(firstname = 'test', lastname = 'test');
        //insert contact;

        Section__c section = new Section__c(Program__c = program.Id);
        insert section;


        delete section;

        undelete section;
    }
}