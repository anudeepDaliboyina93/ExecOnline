@isTest
public class ProgramFamilyHandlerTest {

    @isTest
    static void testPrimaryServiceCreation(){

        Program_Family__c programFamily = new Program_Family__c();

        programFamily.Name                = 'PG-Family';
        programFamily.Service_Category__c = 'All';

        Test.startTest();

        insert programFamily;

        Test.stopTest();

        Service__c newService = [SELECT Id, Name FROM Service__c LIMIT 1];
        Program_Family__c pf  = [SELECT Id, Primary_Service__c FROM Program_Family__c LIMIT 1];

        System.assertEquals('Core Program - PG-Family', newService.Name);
        System.assertEquals(newService.Id, pf.Primary_Service__c);
    }

    @isTest
    static void testAEPWeightingsInserted(){

        Account testAccount = TestDataFactory.getAccount();
        insert testAccount; 

        Opportunity testOpp = TestDataFactory.getNewBusinessOpportunity(testAccount.Id);
        testOpp.Amount = 34200;
        testOpp.Client_Segment__c = 'Mid-Market';
        insert testOpp;

        Id pricebookId = Test.getStandardPricebookId();

        Product2 prod = new Product2(
        Name = 'AEP',
        ProductCode = 'AEP',
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

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli = new OpportunityLineItem(
        OpportunityId = testOpp.Id,
        Quantity = 6,
        PricebookEntryId = pbEntry.Id,
        TotalPrice = 6 * pbEntry.UnitPrice,
        Product_Code__c = 'AEP'
);
        insert oli;

        testOpp.StageName = 'Closed/Won';
        update testOpp;
      
          Opportunity testOpp2 = [SELECT Id, Number_of_AEP_Products__c FROM Opportunity WHERE Id=:testOpp.Id];
     
          Decimal count = testOpp2.Number_of_AEP_Products__c;

        OpportunityLineItem aepProducts2 = [SELECT Id, ProductCode, Opportunity.Number_of_AEP_Products__c FROM OpportunityLineItem WHERE ProductCode LIKE '%AEP'LIMIT 1];

        Test.startTest();

        Program_Family__c programFamily = new Program_Family__c();
        programFamily.Name                = 'Testing AEP';
        programFamily.Service_Category__c = 'All';

        insert programFamily;

       Program_Family__c updatedProgramFamily = [SELECT Id, Name FROM Program_Family__c LIMIT 1];

       Test.stopTest();
      
        Service__c service = [SELECT Id FROM Service__c LIMIT 1];
        EPC_Weighting__c ew = [SELECT Id, Opportunity__c, Service__c, Program_Family__c, Is_Unlimited__c FROM EPC_Weighting__c LIMIT 1];

        System.assertEquals(service.Id, ew.Service__c);
        System.assertEquals(programFamily.Id, ew.Program_Family__c);
        System.assertEquals(true, ew.Is_Unlimited__c);
    }
}