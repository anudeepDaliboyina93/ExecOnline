@isTest
public class EpcWeightingTriggerHandlerTest {

    @isTest
    static void testEpcWeightingAccountRecalcInsert() {
        Account testAccount = TestDataFactory.getAccount();
        testAccount.EPC_Autocalculation_Enabled__c = true;
        insert testAccount;

        Test.startTest();
        insert new EPC_Weighting__c(Account__c = testAccount.Id);
        Test.stopTest();

        testAccount = [SELECT Id, EPC_Utilization_Last_Recalc__c FROM Account WHERE Id = :testAccount.Id LIMIT 1];
        System.assertEquals(null, testAccount.EPC_Utilization_Last_Recalc__c, 'Account last recalc not null');
    }

    @isTest
    static void testEpcWeightingAccountRecalcUpdate() {
        Account testAccount = TestDataFactory.getAccount();
        testAccount.EPC_Autocalculation_Enabled__c = true;
        insert testAccount;
        EPC_Weighting__c testWeighting = new EPC_Weighting__c(Account__c = testAccount.Id);
        insert testWeighting;

        Test.startTest();
        update testWeighting;
        Test.stopTest();

        testAccount = [SELECT Id, EPC_Utilization_Last_Recalc__c FROM Account WHERE Id = :testAccount.Id LIMIT 1];
        System.assertEquals(null, testAccount.EPC_Utilization_Last_Recalc__c, 'Account last recalc not null');
    }

    @isTest
    static void testEpcWeightingAccountRecalcDelete() {
        Account testAccount = TestDataFactory.getAccount();
        testAccount.EPC_Autocalculation_Enabled__c = true;
        insert testAccount;
        EPC_Weighting__c testWeighting = new EPC_Weighting__c(Account__c = testAccount.Id);
        insert testWeighting;

        Test.startTest();
        delete testWeighting;
        Test.stopTest();

        testAccount = [SELECT Id, EPC_Utilization_Last_Recalc__c FROM Account WHERE Id = :testAccount.Id LIMIT 1];
        System.assertEquals(null, testAccount.EPC_Utilization_Last_Recalc__c, 'Account last recalc not null');
    }

}