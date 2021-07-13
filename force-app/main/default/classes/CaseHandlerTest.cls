@isTest
private class CaseHandlerTest {

	@isTest(seeAllData=true)
	static void testAutoCloseMilestone() {
		Account acc = new Account(Name='Acme' + System.now().millisecond(), Account_Type__c = '2. Key');
		insert acc;
		Entitlement en = new Entitlement();
    	en.Name = 'TestEntitlement';
    	en.AccountId = acc.Id;
    	insert en;

		Contact contact = new Contact(firstname = 'test' + System.now().millisecond(), lastname = 'test', accountId = acc.id);
        insert contact;
		TriggerConfiguration__c tc = [select Case_Entitlement__c, Id from TriggerConfiguration__c where case_entitlement__c != null limit 1];
		Case c = new Case(ContactId=contact.id, Status = 'Our Turn', EntitlementId = en.id, Topic_Count__c = 1);
		insert c;
		c.Status = 'Closed';
		update c;
	}
}