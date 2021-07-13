@istest
public class Trg_createsemester_Test {
    public static testmethod void method1() {
        Account acc = new account();
        acc.name = 'Test Account';
        acc.Website = 'www.abc.com';
        acc.Phone = '11111111';
        acc.Industry = 'Agriculture';

        insert acc;


        Account acc2 = new account();
        acc2.name = 'Test Account 2';
        acc2.Website = 'www.abc.com';
        acc2.Phone = '11111111';
        acc2.Industry = 'Agriculture';
        acc2.Account_Status__c = 'Active';

        insert acc2;

    }
}