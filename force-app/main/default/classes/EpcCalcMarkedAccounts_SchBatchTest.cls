@isTest
public class EpcCalcMarkedAccounts_SchBatchTest {
    @TestSetup
    static void makeData(){
        Account testAccount = TestDataFactory.getAccount();
        insert testAccount;

        Opportunity testOpp = TestDataFactory.getNewBusinessOpportunity(testAccount.Id);
        insert testOpp;

        Product2 epcProduct = TestDataFactory.getEpcProduct();
        insert epcProduct;

        PricebookEntry epcPbe = new PricebookEntry(Pricebook2Id = Test.getStandardPricebookId(), Product2Id = epcProduct.Id, UnitPrice=100, isActive=true);
        insert epcPbe;

        insert new OpportunityLineItem(OpportunityId = testOpp.Id, Product2Id = epcProduct.Id, Quantity = 20, TotalPrice = 100);
        
        testOpp.StageName = 'Closed/Won';
        update testOpp;
    }

    @isTest
    static void testBatchSchedulesAndExecutes() {
		Account testAccount = [SELECT Id FROM Account LIMIT 1];
        testAccount.EPC_Autocalculation_Enabled__c = true;
        update testAccount;
		insert new TriggerConfiguration__c(Enable_AccountTrigger__c = true);
		Contact testContact = TestDataFactory.getContact(testAccount.Id);
		insert testContact;

        Test.startTest();
		Student__c testStudent = TestDataFactory.getStudent(testContact.Id);
        testStudent.Import_Uuid__c = '1234';
		insert testStudent;
        EpcCalcMarkedAccounts_SchBatch b = new EpcCalcMarkedAccounts_SchBatch();
        b.execute(null);
        Test.stopTest();
        
        List<EPC_Utilization__c> newEpcus = [SELECT Id, Type__c, EPCs_Utilized__c FROM EPC_Utilization__c WHERE Account__c = :testAccount.Id];
        System.assertEquals('Provisioned', newEpcus[0].Type__c);
        System.assertEquals(20, newEpcus[0].EPCs_Utilized__c);
    }
}