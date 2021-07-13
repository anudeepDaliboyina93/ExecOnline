@isTest
public class test_updateResponsetimeonCaseClose {

    static testMethod void updateResponsetimeonCaseClose_Test() {

        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Website = 'www.testwebsite.com';
        acc.Phone = '123456789';
        insert acc;

        Contact con = new Contact();
        con.LastName = 'Test Contact';
        con.Preferred_Name__c = 'Test Preferred Name';
        con.Accountid = acc.id;
        insert con;

        Case cse = new Case();
        cse.Contactid = con.id;
        cse.Accountid = acc.id;
        cse.Status =  'New';
        cse.Origin = 'Email';
        cse.Issue_Type__c = 'Account Management';
        cse.Topic_Count__c = 1;
        insert cse;

        Response_Time__c rpt = new Response_Time__c();
        rpt.Case__c = cse.id;
        rpt.Inquiry_Time__c = system.now();
        //rpt.response_time__c = system.now();
        insert rpt;

        cse.Status =  'Closed';
        update cse;


    }

}