@isTest
public class AccountEpcBalanceControllerTest {

    @isTest
    static void testJsonResultAmountAndBalance() {
        Program_Family__c programFamily = TestDataFactory.getProgramFamily();
        insert programFamily;
        Program_Period__c programPeriod = TestDataFactory.getWinterProgramPeriod();
        insert programPeriod;
        Program__c program = TestDataFactory.getProgramForProgramPeriod('testProgram', programPeriod, programFamily);
        insert program;

        Account testAccount = TestDataFactory.getAccount();
        insert testAccount;
        Opportunity testOpp = TestDataFactory.getNewBusinessOpportunity(testAccount.Id);
        testOpp.CloseDate = programPeriod.Start_Date__c.addDays(-10);
        insert testOpp;

        List<EPC_Utilization__c> epcus = new List<EPC_Utilization__c>();
        epcus.add(new EPC_Utilization__c(Account__c = testAccount.Id, Type__c = 'Provisioned', EPCs_Utilized__c = 10, Opportunity__c = testOpp.Id));
        epcus.add(new EPC_Utilization__c(Account__c = testAccount.Id, Type__c = 'Actual', EPCs_Utilized__c = 2, Program__c = program.Id));
        epcus.add(new EPC_Utilization__c(Account__c = testAccount.Id, Type__c = 'Actual', EPCs_Utilized__c = 1, Program__c = program.Id));
        insert epcus;

        Test.startTest();
        String jsonResult = AccountEpcBalanceController.getJsonBalanceLineItemsForAccountId(testAccount.Id);
        Test.stopTest();

        List<AccountEpcBalanceController.EpcBalanceLineItem> resultLineItems = (List<AccountEpcBalanceController.EpcBalanceLineItem>)JSON.deserialize(jsonResult, List<AccountEpcBalanceController.EpcBalanceLineItem>.class);
        System.assertEquals(2, resultLineItems.size());
        System.assertEquals(-3, resultLineItems[0].amount);
        System.assertEquals(7, resultLineItems[0].balance);

    }

}