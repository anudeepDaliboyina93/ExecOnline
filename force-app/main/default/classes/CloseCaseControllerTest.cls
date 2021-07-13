@isTest
private class CloseCaseControllerTest
{
	@isTest
	static void itShould()
	{
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

		ApexPages.currentPage().getParameters().put('c',c.id);
        ApexPages.StandardController stdCaseCtrl = new ApexPages.StandardController(c);
        CloseCaseController myCloseCaseController = new CloseCaseController(stdCaseCtrl);

        myCloseCaseController.save();


	}
}