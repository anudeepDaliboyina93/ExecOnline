@isTest
public class test_updateresponsetimefromcase {

    static testMethod void updateresponsetimefromcase_Test() {
    
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
        insert cse;
        
        Response_Time__c rpt = new Response_Time__c();
        rpt.Case__c = cse.id;
        rpt.Inquiry_Time__c = system.now();
        insert rpt;
        
        emailmessage em = new emailmessage();
        em.incoming = true;
        em.toaddress = 'test1@test.com';
        em.subject = 'Test Email';
        em.textbody = 'testing';
        em.parentid = cse.id;
        insert em;
        
        
        Response_Time__c rpt2 = new Response_Time__c();
        rpt2.Case__c = cse.id;
        rpt2.Inquiry_Time__c = system.now();
        rpt2.response_time__c = system.now();
        insert rpt2;
        
        
        
        emailmessage em2 = new emailmessage();
        em2.incoming = true;
        em2.toaddress = 'test1@test.com';
        em2.subject = 'Test Email';
        em2.textbody = 'testing';
        em2.parentid = cse.id;
        em2.status = '0';
        insert em2;
    
    }

}