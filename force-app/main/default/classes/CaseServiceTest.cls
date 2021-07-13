@isTest
private class CaseServiceTest {

	@isTest(seeAllData=true)
	static void testApplyAssignmentRule() {
		Case c = new Case();
		CaseService.applyAssignmentRule(c);
		Id existingAssignRuleId = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1].id;
		Id caseAssignRuleId = c.getOptions().AssignmentRuleHeader.AssignmentRuleId;
		System.assertEquals(caseAssignRuleId, existingAssignRuleId);
	}
	@isTest
	static void testGetDefaultEntitlement() {
		Account acc = new Account(Name='Acme', Account_Type__c = '2. Key');
		insert acc;
		Entitlement en = new Entitlement();
    	en.Name = 'TestEntitlement';
    	en.AccountId = acc.Id;
    	insert en;

		TriggerConfiguration__c tc = new TriggerConfiguration__c( Case_Entitlement__c=en.id);
		insert tc;

		Contact contact = new Contact(firstname = 'test', lastname = 'test', AccountId = acc.id);
        insert contact;
		tc = [select Case_Entitlement__c, Id from TriggerConfiguration__c where case_entitlement__c != null limit 1];
		Case c = new Case(ContactId=contact.id);
		insert c;
		c = [select id, EntitlementId from Case where id = :c.id limit 1];
		System.assertEquals(tc.Case_Entitlement__c.substring(0,15), String.valueOf(c.EntitlementId).substring(0,15));
	}
	@isTest
	static void testGetDefaultEntitlement_DNE() {
		Account acc = new Account(Name='Acme', Account_Type__c = '2. Key');
		insert acc;

		Contact contact = new Contact(firstname = 'test', lastname = 'test', AccountId = acc.id);
        insert contact;

		Case c = new Case(ContactId=contact.id);
		insert c;
		c = [select id, EntitlementId from Case where id = :c.id limit 1];
		System.assertEquals(null, c.EntitlementId);
	}
}