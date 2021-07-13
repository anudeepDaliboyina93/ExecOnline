public class epcRecalcBatch implements Database.Batchable<sObject> {

    String query;
    List<String> accountExceptions = new List<String>();

    public epcRecalcBatch(List<String> anonExceptions) {
      
    }


    public Database.QueryLocator start(Database.BatchableContext BC) {
        String accountExceptionCriteria = '';
        accountExceptions.add('name LIKE \'willNotMatch\'');
        for (Integer i = 0; i < accountExceptions.size(); i++) {
            accountExceptionCriteria += (i == accountExceptions.size()-1) ? accountExceptions[i] : accountExceptions[i] + ' OR ';
        }
        //System.Debug(accountExceptionCriteria);
        query =  'SELECT ID, NAME FROM Account Where NOT(' + accountExceptionCriteria + ')';
        return Database.getQueryLocator(query);

    }

    public void execute(Database.BatchableContext BC, List<Account> accounts) {
        
		Set<Id> accountIds = new Set<Id>();
        for (account a: accounts) {
            accountIds.add(a.Id);
        }
        //epcService.CalculateEpcUtilization(accountIds);
    	EpcServiceV2 epcHelper = new EpcServiceV2(accountIds);
    	ID jobID = System.enqueueJob(epcHelper);

    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Finished epcRecalcBatch');


    }

}