@isTest
public class ProgramHandlerTest {

    @isTest
     static void testProgramHandler() {

        Program__c program = new Program__c(friendly_name__c = 'test', short_name__c = 'test');
        insert program;

        program =  [select Id, Name, Manager_Campaign__c from Program__c where Id = :program.Id];
        delete program;

    }

    @isTest
    static void testProgramPeriod(){

        Program_Period__c period = new Program_Period__c(Name= 'test period', Start_Date__c = Date.newInstance(2020, 11, 25), End_Date__c = Date.newInstance(2020, 11, 30));
        insert period;

        Program__c programWithPeriod    = new Program__c(Name = 'test program' ,friendly_name__c = 'test', short_name__c = 'test', Course_Start_Date__c = Date.newInstance(2020, 11, 25));

        Test.startTest();
        insert programWithPeriod;
        Test.stopTest();

        Program__c updateWithPeriod    = [SELECT Id, Program_Period__c FROM Program__c WHERE Id =: programWithPeriod.Id LIMIT 1];

        System.assertEquals(period.Id, updateWithPeriod.Program_Period__c);

        updateWithPeriod.Program_Period__c = null;

        update updateWithPeriod;

        Program__c updateWithPeriodUpdated   = [SELECT Id, Program_Period__c FROM Program__c WHERE Id =: updateWithPeriod.Id LIMIT 1];

        System.assertEquals(null, updateWithPeriodUpdated.Program_Period__c);

    }
}