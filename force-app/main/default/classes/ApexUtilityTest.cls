@isTest
private class ApexUtilityTest {

	@isTest static void getObjectNameFromIdTest() {
		Account acc = new Account(Name='Acme');
		insert acc;
		System.AssertEquals('Account', ApexUtility.getObjectNameFromId(acc.id));
	}

	@isTest static void isValidId() {
		Account acc = new Account(Name='Acme');
		insert acc;
		System.Assert(ApexUtility.isValidId(acc.id));
		String badId = (String)(acc.id);
		System.Assert(!ApexUtility.isValidId(badId.substring(10)));
		String badId2 = (String)(acc.id);
		badId2 += ' ';
		System.Assert(!ApexUtility.isValidId(badId2));
		String badId3 = 'asdfasdfasdfsadfad';
		System.Assert(!ApexUtility.isValidId(badId3));
	}

	@isTest static void joinStringListTest() {
		List<String> myList = new List<String>{'a','b','c'};
		System.assertEquals('a;b;c', ApexUtility.join(myList,';'));
	}

	@isTest static void initApexUtility() {
		ApexUtility wt = new ApexUtility();
	}

	@isTest static void didFieldValueChangeCaseSensitive() {
		Account acc = new Account(Name='Acme');
		insert acc;
		List<Contact> contacts = new List<Contact> ();
		Contact a = new Contact(FirstName = 'Test', LastName= '100001', AccountId = acc.id);
		Contact b = new Contact(FirstName = 'Test', LastName= '100001', AccountId = acc.id);
		Contact c = new Contact(FirstName = 'test', LastName= '100001', AccountId = acc.id);
		Contact d = new Contact(FirstName = 'TEST', LastName= '100001', AccountId = acc.id);
		Contact e = new Contact(FirstName = 'TEST', LastName= '100001', AccountId = acc.id, Email = 'test932489@example.com');
		Contact f = new Contact(FirstName = 'TEST', LastName= '100001', AccountId = acc.id, Email = null);
		contacts.add(a);
		contacts.add(b);
		contacts.add(c);
		contacts.add(d);
		contacts.add(e);
		contacts.add(f);
		insert contacts;
		system.assertEquals(false, ApexUtility.didFieldValueChangeCaseSensitive(a, b, 'FirstName'));
		system.assertEquals(true, ApexUtility.didFieldValueChangeCaseSensitive(a, c, 'FirstName'));
		system.assertEquals(true, ApexUtility.didFieldValueChangeCaseSensitive(a, d, 'FirstName'));
		system.assertEquals(false, ApexUtility.didFieldValueChangeCaseSensitive(a, b, 'LastModifiedDate'));
		system.assertEquals(true, ApexUtility.didFieldValueChangeCaseSensitive(d, e, 'Email'));
		system.assertEquals(true, ApexUtility.didFieldValueChangeCaseSensitive(e, f, 'Email'));
		system.assertEquals(false, ApexUtility.didFieldValueChangeCaseSensitive(e, f, 'Title'));
	}

	@isTest static void testPicklistOptions(){

		ApexUtility.customValueWrapper cw = new ApexUtility.customValueWrapper();

		Event e = new Event();

		ApexUtility.getPicklistOptions(e, 'Status__c');
	}

}