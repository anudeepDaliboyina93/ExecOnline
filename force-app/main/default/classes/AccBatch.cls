public class AccBatch implements Database.Batchable<sObject>, Database.Stateful {
  public AccBatch() {}

    public Iterable<sObject> start (Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT id,of_Opportunities_Closed_Won__c,of_MQL_Leads__c,of_MQI_Leads__c,of_MQI_Contacts__c,of_MQL_Contacts__c FROM Account');
    }

    public void execute(Database.BatchableContext BC, List<Account> scope) {
        Set<Id> acctIds = new Set<id>();
        Map<Id, Integer> mqlMap = new Map<Id, Integer>();
        Map<Id, Integer> mqiMap = new Map<Id, Integer>();        
        Map<Id, Integer> mqlContactMap = new Map<Id, Integer>();
        Map<Id, Integer> mqiContactMap = new Map<Id, Integer>();    
        
        for (Account a : scope) {
            acctIds.add(a.id);
            mqlMap.put(a.id, 0);
            mqiMap.put(a.id, 0);
            mqlContactMap.put(a.id, 0);
            mqiContactMap.put(a.id, 0);
        }

        for (Lead l : [SELECT MQL__c, MQI__c, Existing_Account__c FROM Lead where Existing_Account__c IN :acctIds]) {
            if (l.MQL__c) {
                mqlMap.put(l.Existing_Account__c, mqlMap.get(l.Existing_Account__c) + 1);
            }
            
            if (l.MQI__c) {
                mqiMap.put(l.Existing_Account__c, mqiMap.get(l.Existing_Account__c) + 1);
            }
        }
        
        for (Contact c : [SELECT MQL__c, MQI__c, AccountId FROM Contact where AccountId IN :acctIds]) {
            if (c.MQL__c) {
                mqlContactMap.put(c.AccountId, mqlContactMap.get(c.AccountId) + 1);
            }
            
            if (c.MQI__c) {
                mqiContactMap.put(c.AccountId, mqiContactMap.get(c.AccountId) + 1);
            }
        }
        
        List<Account> lstToUpdate = new List<Account>();
        
        for (Account a : scope) {
            if (a.of_MQI_Leads__c != mqiMap.get(a.id) || a.of_MQL_Leads__c != mqlMap.get(a.id) || a.of_MQL_Contacts__c != mqlContactMap.get(a.id) || a.of_MQI_Contacts__c != mqiContactMap.get(a.id)) {
                a.of_MQI_Leads__c = mqiMap.get(a.id);
                a.of_MQL_Leads__c = mqlMap.get(a.id);
                a.of_MQL_Contacts__c = mqlContactMap.get(a.id);
                a.of_MQI_Contacts__c = mqiContactMap.get(a.id);
                lstToUpdate.add(a);
            }
        }
        
        if (!lstToUpdate.isEmpty()) {
            Database.update(lstToUpdate, false);
        }
    }
    
    public void finish(Database.BatchableContext BC) {}
}