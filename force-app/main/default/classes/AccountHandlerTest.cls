@isTest
private class AccountHandlerTest {

	@isTest static void acctUpdateDeleteUndeleteTests() {

        TriggerConfiguration__c tc = new TriggerConfiguration__c( Enable_AccountTrigger__c=TRUE );
        insert tc;

		List<Account> myAccounts = new List<Account>();        
		myAccounts.add(new Account(name = 'Test Account1', Type = 'Business School'));
		myAccounts.add(new Account(name = 'Test Account2', Type = 'Channel Partner'));
		myAccounts.add(new Account(name = 'Test Account3', Type = 'Client'));
		myAccounts.add(new Account(name = 'Test Account4', Type = 'Client Non Enterprise'));
		myAccounts.add(new Account(name = 'Test Account5', Type = 'Lapsed Client'));
		myAccounts.add(new Account(name = 'Test Account6', Type = 'Visited'));
		insert myAccounts;

		myAccounts = [select id, name from Account order by name];
		
		myAccounts[0].name = 'Test Account1 Updated';
		myAccounts[1].name = 'Test Account2 Updated';
		myAccounts[2].name = 'Test Account3 Updated';
		myAccounts[3].name = 'Test Account4 Updated';
		myAccounts[4].name = 'Test Account5 Updated';
		myAccounts[5].name = 'Test Account6 Updated';
		
		myAccounts[0].Type = 'Visited';
		myAccounts[0].Type = 'Business School';
		myAccounts[0].Type = 'Channel Partner';
		myAccounts[0].Type = 'Client';
		myAccounts[0].Type = 'Client Non Enterprise';
		myAccounts[0].Type = 'Lapsed Client';
		update myAccounts;

		delete myAccounts[0];

		undelete myAccounts[0];
	}

	@isTest
	static void testAccountDeleteTriggerBlockError() {
		Account testAccount = TestDataFactory.getAccount();
		insert testAccount;
		Contact testContact = TestDataFactory.getContact(testAccount.Id);
		insert testContact;
		Student__c testStudent = TestDataFactory.getStudent(testContact.Id);
		insert testStudent;

		insert new TriggerConfiguration__c(Enable_AccountTrigger__c = true);

		String expectedErrorMsg;
		try {
			Test.startTest();
			delete testAccount;
			Test.stopTest();
		} catch(Exception e) {
			expectedErrorMsg = e.getMessage();
		}
		System.assert(expectedErrorMsg.contains(AccountService.ACCOUNT_DELETE_ERROR));
		
	}

	@isTest
	static void testAccountToStudentFieldSync() {
		Account testAccount = TestDataFactory.getAccount();
		testAccount.EPC_Autocalculation_Enabled__c = false;
		insert testAccount;
		Contact testContact = TestDataFactory.getContact(testAccount.Id);
		insert testContact;
		Student__c testStudent = TestDataFactory.getStudent(testContact.Id);
		testStudent.Status__c = 'Prospect';
		insert testStudent;

		insert new TriggerConfiguration__c(Enable_AccountTrigger__c = true);

		Test.startTest();
		testAccount.Org_Tech_Survey_Req_Text__c = 'testdata';
		update testAccount;
		Test.stopTest();

		Student__c testResultStudent = [SELECT Id, Org_Tech_Survey_Req_Text__c FROM Student__c WHERE Id = :testStudent.Id LIMIT 1];
		System.assertEquals(testAccount.Org_Tech_Survey_Req_Text__c, testResultStudent.Org_Tech_Survey_Req_Text__c);
	}

	@isTest
	static void testStudentFromAccountFieldSyncInsert() {
		Account testAccount = TestDataFactory.getAccount();
		testAccount.Org_Tech_Survey_Req_Text__c = 'testdata';
		testAccount.EPC_Autocalculation_Enabled__c = false;
		insert testAccount;
		Contact testContact = TestDataFactory.getContact(testAccount.Id);
		insert testContact;

		insert new TriggerConfiguration__c(Enable_AccountTrigger__c = true);

		Test.startTest();
		Student__c testStudent = TestDataFactory.getStudent(testContact.Id);
		insert testStudent;
		Test.stopTest();

		Student__c testResultStudent = [SELECT Id, Org_Tech_Survey_Req_Text__c FROM Student__c WHERE Id = :testStudent.Id LIMIT 1];
		System.assertEquals(testAccount.Org_Tech_Survey_Req_Text__c, testResultStudent.Org_Tech_Survey_Req_Text__c);
	}

	@isTest
	static void testStudentFromAccountFieldSyncUpdate() {
		Account testAccount = TestDataFactory.getAccount();
		testAccount.Org_Tech_Survey_Req_Text__c = 'testdata';
		testAccount.EPC_Autocalculation_Enabled__c = false;
		insert testAccount;
		Contact testContact = TestDataFactory.getContact(testAccount.Id);
		insert testContact;
		Student__c testStudent = TestDataFactory.getStudent(testContact.Id);
		insert testStudent;

		insert new TriggerConfiguration__c(Enable_AccountTrigger__c = true);

		Test.startTest();
		testStudent.Status__c = 'Prospect';
		update testStudent;
		Test.stopTest();

		Student__c testResultStudent = [SELECT Id, Org_Tech_Survey_Req_Text__c FROM Student__c WHERE Id = :testStudent.Id LIMIT 1];
		System.assertEquals(testAccount.Org_Tech_Survey_Req_Text__c, testResultStudent.Org_Tech_Survey_Req_Text__c);
	}

}