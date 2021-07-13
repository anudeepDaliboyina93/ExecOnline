public class EpcCalcMarkedAccounts_SchBatch implements Schedulable, Database.Batchable<sObject> {

    public void execute(SchedulableContext sc) {
        EpcCalcAllAccounts_SchBatch b = new EpcCalcAllAccounts_SchBatch();
        Database.executeBatch(b, 10);
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id FROM Account WHERE EPCs_Purchased__c > 0 AND EPC_Autocalculation_Enabled__c = false AND Is_Loading_Students__c = true';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Account> accounts) {
        enableEpcCalcForAccounts(accounts);
        Map<Id, Account> accountMap = new Map<Id, Account>(accounts);
        EpcServiceV2 epcHelper = new EpcServiceV2(accountMap.keySet());
        System.enqueueJob(epcHelper);
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Finished EpcCalcAllAccounts_SchBatch');
    }

    private void enableEpcCalcForAccounts(List<Account> accounts) {
        for(Account acc : accounts) {
            acc.EPC_Autocalculation_Enabled__c = true;
            acc.Is_Loading_Students__c = false;
        }
        update accounts;
    }

    public static void rescheduleRecalcJob() {
        Datetime withinTwoMinutes = System.now().addMinutes(2);
        Boolean needToReschedule = false;
        List<CronTrigger> existingJobs = [SELECT Id, NextFireTime FROM CronTrigger WHERE CronJobDetail.Name LIKE 'EpcCalcMarkedAccounts_SchBatch%' AND State = 'WAITING'];
        for(CronTrigger job : existingJobs) {
            if(job.NextFireTime < withinTwoMinutes) {
                System.abortJob(job.Id);
                needToReschedule = true;
            }
        }
        if(needToReschedule || existingJobs.isEmpty()) {
            System.scheduleBatch(new EpcCalcMarkedAccounts_SchBatch(), 'EpcCalcMarkedAccounts_SchBatch_' + System.now(), 10, 10);
        }
    }

}