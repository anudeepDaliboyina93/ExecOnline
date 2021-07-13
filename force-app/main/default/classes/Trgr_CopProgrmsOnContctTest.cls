@isTest
Public class Trgr_CopProgrmsOnContctTest{

    /*
    **
    */
    Public testmethod static void M1(){
        Account a = new Account(Name = 'Test Account');
        insert a;
        Contact Con = new contact();
        con.accountId = a.id;
        con.firstname = 'fname';
        con.lastname = 'lname';
        con.Preferred_Name__c = 'test';
        con.Email = 'test@test.com';
        con.Contact_Type__c = 'Student';
        insert con;
        
        Contact con2 = new contact();
        con2.accountId = a.id;
        con2.firstname = 'fnameA';
        con2.lastname = 'lnameA';
        con2.Preferred_Name__c = 'testA';
        con2.Email = 'testA@test.com';
        con2.Contact_Type__c = 'Student';
        insert con2;


        Program__c Progrm = new Program__c();
        Progrm.name = 'test';
        Progrm.Friendly_Name__c = 'test';
        Progrm.Short_Name__c = 'test';
        insert Progrm;

        Student__c Stud = new Student__c();
        Stud.Contact__c = con.id;
        Stud.Program__c = Progrm.id;
        Stud.Mailing_List_ID__c = 'Test 1';
        insert Stud;

        Student__c Stud2 = new Student__c();
        Stud2.Contact__c = con2.id;
        Stud2.Program__c = Progrm.id;
        Stud2.Mailing_List_ID__c = 'Test 2';
        insert Stud2;

        delete Stud;
        delete Stud2;


    }
}