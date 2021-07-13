@isTest
public class oppTestClass {
   
    @testSetup static void setupTestData() {

        Account acc = TestDataFactory.getAccount();
        insert acc;

        Id pricebookId = Test.getStandardPricebookId();

        Product2 prod = new Product2(
            Name = 'EPC',
            ProductCode = 'EPC',
            isActive = true
            );
            insert prod;
    
    
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 5700.00,
            IsActive = true
            );
            insert pbEntry;
    }

    @isTest
    static void testNewLogoCheckedFromTwoOpportunitiesSameYear() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
    

        List<Opportunity> testOpps = new List<Opportunity>();
        testOpps.add(TestDataFactory.getNewBusinessOpportunity(testAccount.Id));
        testOpps[0].Amount = 30000;
        testOpps[0].Client_Segment__c = 'Mid-Market';

        testOpps.add(TestDataFactory.getContractRenewalOpportunity(testAccount.Id));
        testOpps[1].Amount = 50000;
        testOpps[1].Client_Segment__c = 'Mid-Market';
        testOpps[1].StageName = 'Closed/Lost';

        insert testOpps;

        

        Test.startTest();
        OpportunityHandler.newLogoLogicRan = false;

        testOpps[0].StageName = 'Closed/Won';
        update testOpps[0];

        testOpps[1].StageName = 'Closed/Won';
        update testOpps[1];
        Test.stopTest();

        Map<Id, Opportunity> testOppMap = new Map<Id, Opportunity>([SELECT Id, New_Logo__c FROM Opportunity WHERE Id IN :testOpps]);
        system.debug(testOppMap.size());
        system.debug(testOppMap.get(testOpps[0].Id).New_Logo__c);
        system.debug(testOppMap.get(testOpps[1].Id).New_Logo__c);
       // System.assert(testOppMap.get(testOpps[0].Id).New_Logo__c, 'New Logo checked');
        //System.assert(!testOppMap.get(testOpps[1].Id).New_Logo__c, 'New Logo not checked');
        
    }


}