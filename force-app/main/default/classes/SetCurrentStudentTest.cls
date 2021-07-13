@isTest
private class SetCurrentStudentTest {

	@isTest static void test_method_one() {
		Account acct = new Account(Name = 'Test Account');
		insert acct;
        Contact contact = new Contact(lastname='test', AccountId = acct.id);
        insert contact;
        Program__c program = new Program__c(Friendly_Name__c = 'Test', Short_Name__c = 'Test');
        insert program;
        Student__c student = new Student__c(contact__c = contact.Id, Program__c = program.Id);
        insert student;

        List<ID> programIds = new List<Id>();
        programIds.add(program.Id);
		SetCurrentStudent.execute(programIds);
        contact = [Select current_student__c from contact where id = :student.contact__c];
        //System.assertEquals(student.Id, contact.Current_Student__c);
	}


}