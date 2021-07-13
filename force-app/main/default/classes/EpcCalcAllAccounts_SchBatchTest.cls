@isTest
public class EpcCalcAllAccounts_SchBatchTest {
    @TestSetup
    static void makeData(){
        Account testAccount = TestDataFactory.getAccount();
        testAccount.EPC_Autocalculation_Enabled__c = true;
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
        Test.startTest();
        EpcCalcAllAccounts_SchBatch b = new EpcCalcAllAccounts_SchBatch();
        b.execute(null);
        Test.stopTest();

        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<EPC_Utilization__c> newEpcus = [SELECT Id, Type__c, EPCs_Utilized__c FROM EPC_Utilization__c WHERE Account__c = :testAccount.Id];
        System.assertEquals('Provisioned', newEpcus[0].Type__c);
        System.assertEquals(20, newEpcus[0].EPCs_Utilized__c);
    }
}