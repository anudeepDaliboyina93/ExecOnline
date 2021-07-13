@isTest
public class DealDeskHandlerTest {

    @testSetup static void setupTestData() {

        Account acc = TestDataFactory.getAccount();
        insert acc;
        Opportunity opp = TestDataFactory.getContractRenewalOpportunity(acc.Id);
        insert opp;

        Commercial_Account_Hold__c dd = new Commercial_Account_Hold__c();

        dd.Account__c = acc.Id;
        dd.Opportunity__c = opp.Id;
        dd.CAR_Type__c = 'Pricing';
        dd.Query__c = 'Test deal desk';

        insert dd;
    }

    @isTest
    static void testDealDeskToSlack(){

        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

        Commercial_Account_Hold__c dd = new Commercial_Account_Hold__c();

        dd.Account__c = opp.AccountId;
        dd.Opportunity__c = opp.Id;
        dd.CAR_Type__c = 'Pricing';
        dd.Query__c = 'Test deal desk';

        
        insert dd;

        
    }

    @isTest
    static void testDealDeskToSlackSummary(){

        Commercial_Account_Hold__c dd = [SELECT Id FROM Commercial_Account_Hold__c LIMIT 1];

        
        DealDeskScheduledSummary schBatch = new DealDeskScheduledSummary();
        schBatch.execute(null);

       
    }
}