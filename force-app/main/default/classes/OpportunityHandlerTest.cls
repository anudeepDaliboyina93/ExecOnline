@isTest
private class OpportunityHandlerTest {


    @testSetup static void setupTestData() {
        List<User> u = new List<User>();

        String uniqueUserName1 = 'standarduser' + DateTime.now().getTime() + '@testorg.com';

        Profile p1 = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User u1 = new User(Alias = 'standt', Email='standarduser1@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p1.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName1);

         u.add(u1);
         String uniqueUserName2 = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
    
        Profile p2 = [SELECT Id FROM Profile WHERE Name='Revenue Admin'];
        User u2 = new User(Alias = 'standt', Email='standarduser2@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p2.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName2);

         u.add(u2);

         insert u;

    }
    @isTest static void calloutBufferItemCreated() {

        insertCustomSettings();

        Account account = new account(name = 'Test Account');
        insert account;
        Opportunity opportunity = new Opportunity(Name = 'Test Opportunity', StageName = 'Test', CloseDate = Date.today(), accountId = account.Id);
        insert opportunity;
        //List<SObject> students = new List<Student__c>();
        //students.add(student);

        String jsonBody = CalloutBuffer.buildJSONbody(opportunity, 'POST');

        System.assertNotEquals(null, jsonBody);
        delete opportunity;
        undelete opportunity;
    }

    private static void insertCustomSettings() {
        Integration_Field_Configuration__C integrationFieldConfig = buildIntegrationFieldConfiguration();
        insert integrationFieldConfig;
        insertResources();

    }
    private static Integration_Field_Configuration__C buildIntegrationFieldConfiguration() {
        Integration_Field_Configuration__C integrationFieldConfig = new Integration_Field_Configuration__C();
        integrationFieldConfig.Name = 'Test';
        integrationFieldConfig.Field__c = 'AccountId';
        integrationFieldConfig.Integration_Key__c = 'AccountId';
        integrationFieldConfig.Object_Type__c = 'Opportunity';

        return integrationFieldConfig;
    }

    private static void insertResources() {
        Callout_Buffer_Resources__c bufferResources = new Callout_Buffer_Resources__c(
            Name = 'Opportunity',
            Resource__c = 'opportunities',
            Enabled__c = true
        );
        insert bufferResources;
    }

    @isTest
    static void testNewLogoCheckedFromOneOpportunity() {
        Account testAccount = TestDataFactory.getAccount();
        insert testAccount; 

        Opportunity testOpp = TestDataFactory.getNewBusinessOpportunity(testAccount.Id);
        testOpp.Amount = 30000;
        testOpp.Client_Segment__c = 'Mid-Market';
        insert testOpp;

        Test.startTest();
        testOpp.StageName = 'Closed/Won';
        update testOpp;
        Test.stopTest();

        testOpp = [SELECT Id, New_Logo__c FROM Opportunity WHERE Id = :testOpp.Id LIMIT 1];
       // System.assert(testOpp.New_Logo__c, 'New Logo not checked');
    }

    @isTest
    static void testNewLogoCheckedFromTwoOpportunitiesSameYear() {
        Account testAccount = TestDataFactory.getAccount();
        insert testAccount;

        List<Opportunity> testOpps = new List<Opportunity>();
        testOpps.add(TestDataFactory.getNewBusinessOpportunity(testAccount.Id));
        testOpps[0].Amount = 30000;
        testOpps[0].Client_Segment__c = 'Mid-Market';

        testOpps.add(TestDataFactory.getContractRenewalOpportunity(testAccount.Id));
        testOpps[1].Amount = 5000;
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

        Map<Id, Opportunity> testOppMap = new Map<Id, Opportunity>([SELECT Id, New_Logo__c FROM Opportunity WHERE Id IN :testOpps AND isWon = true]);
       // System.assert(testOppMap.get(testOpps[0].Id).New_Logo__c, 'New Logo checked');
        System.assert(!testOppMap.get(testOpps[1].Id).New_Logo__c, 'New Logo not checked');
    }

    @isTest
    static void testNewLogoCheckedFromNewBusinessOpportunityDifferentYear() {
        Account testAccount = TestDataFactory.getAccount();
        insert testAccount;

        List<Opportunity> testOpps = new List<Opportunity>();
        testOpps.add(TestDataFactory.getNewBusinessOpportunity(testAccount.Id));
        testOpps[0].Amount = 25000;
        testOpps[0].Client_Segment__c = 'Mid-Market';
        testOpps[0].CloseDate = Date.today().addYears(-1);

        testOpps.add(TestDataFactory.getNewBusinessOpportunity(testAccount.Id));
        testOpps[1].Amount = 30000;
        testOpps[1].Client_Segment__c = 'Mid-Market';

        insert testOpps;

        testOpps[0].StageName = 'Closed/Won';
        update testOpps[0];

        Test.startTest();
        OpportunityHandler.newLogoLogicRan = false;

        testOpps[1].StageName = 'Closed/Won';
        update testOpps[1];
        Test.stopTest();

        Map<Id, Opportunity> testOppMap = new Map<Id, Opportunity>([SELECT Id, New_Logo__c FROM Opportunity WHERE Id IN :testOpps]);

        //System.assert(testOppMap.get(testOpps[0].Id).New_Logo__c, 'New Logo not checked');
        //System.assert(testOppMap.get(testOpps[1].Id).New_Logo__c, 'New Logo checked');
    }

    @isTest
    static void testinsertUpdateDeleteNonRevenueAdmin() {

        User u2 = [SELECT Id, Email FROM User WHERE Email = 'standarduser1@testorg.com' LIMIT 1];
        Id contractRenewalId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Contract Renewal').getRecordTypeId();

         Account oppAccount = TestDataFactory.getAccount();
         insert oppAccount; 

         Opportunity insertedOpp = TestDataFactory.getNewBusinessOpportunity(oppAccount.Id);
         insertedOpp.Amount = 30000;
         insertedOpp.Client_Segment__c = 'Mid-Market';
         insertedOpp.RecordTypeId = contractRenewalId;
 
         insert insertedOpp;
 
        System.runAs(u2) {
            system.debug(userinfo.getProfileId());
        Account testAccount = TestDataFactory.getAccount();
        insert testAccount; 

        Opportunity testOpp = TestDataFactory.getNewBusinessOpportunity(testAccount.Id);
        testOpp.Amount = 30000;
        testOpp.Client_Segment__c = 'Mid-Market';
        testOpp.RecordTypeId = contractRenewalId;

        Test.startTest();
        
        try {
            insert testOpp;
        }
        catch(Exception e) {
            System.assert(e.getMessage().contains('Only Revenue Admin users are allowed to create opportunities with the Contract Renewal record type'));
        }

        try {

           Opportunity updateOpp = [SELECT Id FROM Opportunity WHERE RecordTypeId=:contractRenewalId LIMIT 1];

            updateOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Ad Hoc').getRecordTypeId();

            update updateOpp;
        }
        catch(Exception e) {
            System.assert(e.getMessage().contains('Only Revenue Admin users are allowed to change the record type from Contract Renewal'));
        }

        try {

            delete testOpp;
        }
        catch(Exception e) {
            System.assert(e.getMessage().contains('Only Revenue Admin users are allowed to delete an opportunity with the record type of Contract Renewal'));
        }

        
        Test.stopTest();

          }

        
    }

    @isTest
    static void testinsertUpdateDeleteRevenueAdmin() {
   
        User u3 = [SELECT Id, Email FROM User WHERE Email = 'standarduser2@testorg.com' LIMIT 1];

        System.runAs(u3) {
            Account testAccount = TestDataFactory.getAccount();
        insert testAccount; 

        Opportunity testOpp = TestDataFactory.getNewBusinessOpportunity(testAccount.Id);
        testOpp.Amount = 30000;
        testOpp.Client_Segment__c = 'Mid-Market';
        testOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Contract Renewal').getRecordTypeId();
       
        Test.startTest();
        insert testOpp;

        testOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Ad Hoc').getRecordTypeId();
        update testOpp;

        Opportunity renewalOpp = [SELECT Id, RecordTypeId FROM Opportunity WHERE Id=:testOpp.Id];

        renewalOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Contract Renewal').getRecordTypeId();

        update renewalOpp;

        delete renewalOpp;
        Test.stopTest();

        System.assertEquals(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Contract Renewal').getRecordTypeId(), renewalOpp.RecordTypeId);

    }

          }

    @isTest
    static void closedWonOppBackOpen() {

        Account testAccount = TestDataFactory.getAccount();
        insert testAccount; 

        Opportunity testOpp = TestDataFactory.getNewBusinessOpportunity(testAccount.Id);
        testOpp.Amount = 34200;
        testOpp.Client_Segment__c = 'Mid-Market';
        testOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Contract Renewal').getRecordTypeId();
        insert testOpp;

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

        //create your opportunity line item.  This assumes you already have an opportunity created, called opp
        OpportunityLineItem oli = new OpportunityLineItem(
        OpportunityId = testOpp.Id,
        Quantity = 6,
        PricebookEntryId = pbEntry.Id,
        TotalPrice = 6 * pbEntry.UnitPrice
);
insert oli;

Test.startTest();

testOpp.StageName = 'Closed/Won';
update testOpp;

//System.assertEquals(1, [SELECT Id, Opportunity__c FROM EPC_Utilization__c WHERE Opportunity__c =:testOpp.Id].size());

EPC_Utilization__c epc = [SELECT Id, EPCs_Utilized__c FROM EPC_Utilization__c WHERE Opportunity__c=:testOpp.Id];

System.assertEquals(6, epc.EPCs_Utilized__c);

OpportunityLineItem o = [SELECT Id, Quantity FROM OpportunityLineItem WHERE Id =:oli.Id];

o.Quantity = 5;

update o;

EPC_Utilization__c epcUpdated = [SELECT Id, EPCs_Utilized__c FROM EPC_Utilization__c WHERE Opportunity__c=:testOpp.Id];

System.assertEquals(5, epcUpdated.EPCs_Utilized__c);


testOpp.StageName = 'Phase 0';

update testOpp;

Test.stopTest();

System.assertEquals(0, [SELECT Id, Opportunity__c FROM EPC_Utilization__c WHERE Opportunity__c =:testOpp.Id].size());

    }

    

}