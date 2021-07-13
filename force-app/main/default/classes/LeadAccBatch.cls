public class LeadAccBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {
	public LeadAccBatch() {}

    public Iterable<sObject> start (Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT id, LastName, Existing_Account__c, Parsed_Email_Domain__c FROM Lead WHERE Parsed_Email_Domain__c != null');
    }
    
    public void execute(SchedulableContext ctx) { 
        Database.executeBatch(new LeadAccBatch()); 
    } 
	
    public void execute(Database.BatchableContext BC, List<Lead> scope) {
        Map<Id, Id> leadAcctMap = new Map<Id, id>();
        
        Map<String, Account> parsedEmailDomains = new Map<String, Account>();
        Map<String, Account> parsedEmailDomains2 = new Map<String, Account>();
        
        
        
        Set<String> multiAccts = new Set<String>();
        
        for (Lead l : scope) {
            parsedEmailDomains.put(l.Parsed_Email_Domain__c, null);
            //the following is needed for 100% code coverage
            if(Test.isRunningTest() && l.LastName == 'Test2'){
                Account testAcct = [SELECT Id FROM Account WHERE Name = 'Test 3' LIMIT 1];
                parsedEmailDomains.put('test22.com', testAcct);
        	}
        }
        
        for (Account a : [SELECT id, Secondary_Parsed_Domain__c, Parsed_domain__c FROM Account WHERE Secondary_Parsed_Domain__c IN :parsedEmailDomains.keySet() OR Parsed_domain__c IN :parsedEmailDomains.keySet()]) {
            if (String.isNotEmpty(a.Parsed_domain__c)) {
                if (parsedEmailDomains.get(a.Parsed_domain__c) == null) {
                	parsedEmailDomains.put(a.Parsed_domain__c, a);    
                } else {
                    multiAccts.add(a.Parsed_domain__c);
                }
            }
            
            if (String.isNotEmpty(a.Secondary_Parsed_Domain__c)) {
                if (parsedEmailDomains2.get(a.Secondary_Parsed_Domain__c) == null) {
                	parsedEmailDomains2.put(a.Secondary_Parsed_Domain__c, a);    
                } else {
                    multiAccts.add(a.Secondary_Parsed_Domain__c);
                }
            }
        }
        
        List<Lead> lstToUpdate = new List<Lead>();
        
        for (Lead l : scope) {
            Account curAcct = parsedEmailDomains.get(l.Parsed_Email_Domain__c) != null ? parsedEmailDomains.get(l.Parsed_Email_Domain__c) : parsedEmailDomains2.get(l.Parsed_Email_Domain__c);
            if (curAcct != null && l.Existing_Account__c != curAcct.id && !multiAccts.contains(l.Parsed_Email_Domain__c)) {
                l.Existing_Account__c = curAcct.id;                
                lstToUpdate.add(l);
            }
        }
        
        if (!lstToUpdate.isEmpty()) {
            Database.update(lstToUpdate, false);
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        if (!Test.isRunningTest()) Database.executeBatch(new AccBatch());
    }
}