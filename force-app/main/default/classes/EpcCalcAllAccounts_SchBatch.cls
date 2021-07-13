public class EpcCalcAllAccounts_SchBatch implements Schedulable, Database.Batchable<sObject> {

    public void execute(SchedulableContext sc) {
        EpcCalcAllAccounts_SchBatch b = new EpcCalcAllAccounts_SchBatch();
        Database.executeBatch(b, 20);
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id FROM Account WHERE EPCs_Purchased__c > 0 AND EPC_Autocalculation_Enabled__c = true';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Account> accounts) {
        Map<Id, Account> accountMap = new Map<Id, Account>(accounts);
        EpcServiceV2 epcHelper = new EpcServiceV2(accountMap.keySet());
        System.enqueueJob(epcHelper);
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Finished EpcCalcAllAccounts_SchBatch');
    }

}