@isTest
public class LeadAccBatchTest {
    static testMethod void testLeadAccBatch() {
        Account a = new Account(Name='test_Testing123', website='test.com', Secondary_Domain__c='test2.com');
        insert a;
        
        Account a2 = new Account(Name='Test 2', website='test22.com', Secondary_Domain__c='test23.com');
        insert a2;
        
        Account a3 = new Account(Name='Test 3', website='test22.com', Secondary_Domain__c='test23.com');
        insert a3;
        
        Lead l = new Lead(Status='New', LastName='Test',email='test@test.com', Company='test', LeadSource = 'Website', MQL__c=true);
        insert l;
        
        Lead l2 = new Lead(Status='New', LastName='Test', email='test@test2.com', Company='test', LeadSource = 'Website', MQI__c=true);
        insert l2;
        
        Lead l3 = new Lead(Status='New', LastName='Test2', email='test@test22.com', Company='test', LeadSource = 'Website', MQI__c=true);
        insert l3;
        
        Contact c = new Contact(LastName = 'Test', email='test3@test.com', AccountId = a.id, MQL__c = true);
        insert c;
        
        Contact c2 = new Contact(LastName = 'Test2', email='test4@test.com', AccountId = a.id, MQI__c = true);
        insert c2;
        
        Database.executeBatch(new LeadAccBatch());
        Database.executeBatch(new AccBatch());
        Database.executeBatch(new AcctEngStatusBatch());
        
        Test.startTest();
        LeadAccBatch lab = new LeadAccBatch();
        String sch = '0 0 23 * * ?';
        System.schedule('Test LeadAccBatch', sch, lab);
        Test.stopTest();
    }
}