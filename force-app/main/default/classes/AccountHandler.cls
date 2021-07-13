/**
 * AccountHandler.cls
 * Copyright 2015 Wired Triangle, LLC
 * http://www.wiredtriangle.com
 */
public with sharing class AccountHandler implements ITrigger {

    Set<Id> accountIdsToTouchContacts = new Set<Id>();
    private CalloutBuffer.ObjectsToEnqueueWrapper objectsToEnqueue = new CalloutBuffer.ObjectsToEnqueueWrapper();
    public static TriggerConfiguration__c triggerConfig = TriggerConfiguration__c.getInstance();
    private Set<Id> accountsToCalculateEpc = new Set<Id>();
    public static Boolean enableAutoCalculateEPCUtilization = triggerConfig.Enable_Auto_Calculate_EPC_Utilization__c;
    
    Map<Id, Account> deletedAccountsMap;
    Map<Id, Account> accountsToSyncFieldsToStudentsMap = new Map<Id, Account>();
    Set<Id> accountIdsToRecalcInFuture = new Set<Id>();

    public void bulkBefore() {
        if(Trigger.isDelete) {
            deletedAccountsMap = (Map<Id,Account>)Trigger.oldMap;
        }
    }

    public void bulkAfter() {
    }

    public void beforeInsert(SObject so) {

    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        Account account = (Account) so;
        Account oldAccount = (Account) oldSo;

        if(account.Is_Loading_Students__c && account.Is_Loading_Students__c != oldAccount.Is_Loading_Students__c && account.EPC_Autocalculation_Enabled__c) {
            account.EPC_Autocalculation_Enabled__c = false;
        }
    }

    public void beforeDelete(SObject so) {
    }

    public void beforeUnDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
        Account account = (Account) so;

        if (account.Name != null && AccountService.accountTypePlatformSynced(account.Type)) {
            enqueue(account, 'POST');
        }

    }

    public void afterUpdate(SObject oldSo, SObject so) {
        Account account = (Account) so;
        Account oldAccount = (Account) oldSo;

        if(account.Reg_Semester__c != oldAccount.Reg_Semester__c) {
            accountIdsToTouchContacts.add(account.Id);
        }

        if(account.Org_Tech_Survey_Req_Text__c != oldAccount.Org_Tech_Survey_Req_Text__c) {
            accountsToSyncFieldsToStudentsMap.put(account.Id, account);
        }

        if (CalloutBuffer.hasIntegrationFieldChanged(account, oldAccount) && AccountService.accountTypePlatformSynced(account.Type)) {
            enqueue(account, 'PUT');
        }
        if (enableAutoCalculateEPCUtilization &&
            EpcServiceV2.shouldFireEpcCalcFromFieldChange(oldAccount, account)) {
            accountsToCalculateEpc.add(account.Id);
        }
    }

    public void afterDelete(SObject so) {
        Account account = (Account) so;

        if (account.Name != null && AccountService.accountTypePlatformSynced(account.Type)) {
            enqueue(account, 'DELETE');
        }
    }

    public void afterUnDelete(SObject so) {
        Account account = (Account) so;

        if (account.Name != null && AccountService.accountTypePlatformSynced(account.Type)) {
            enqueue(account, 'POST');
        }
    }

    public void andFinally() {
        if (!accountIdsToTouchContacts.isEmpty()) {
            AccountService.handleAccountIdsToTouchContacts(accountIdsToTouchContacts);
        }

        if (!accountsToSyncFieldsToStudentsMap.isEmpty()) {
            AccountService.syncAccountFieldsToStudents(accountsToSyncFieldsToStudentsMap);
        }

        if (!objectsToEnqueue.isEmpty()) {
            CalloutBuffer.enqueueObjects(objectsToEnqueue);
        }
        
        if (!accountsToCalculateEpc.isEmpty()) {
            System.Debug('accountsToCalculateEpc.size()='+accountsToCalculateEpc.size());
            EpcServiceV2 epcHelper = new EpcServiceV2(accountsToCalculateEpc);
            ID jobID = System.enqueueJob(epcHelper);
        }

        if(deletedAccountsMap != null) {
            AccountService.handleDeletedAccounts(deletedAccountsMap);
        }
    }


    private void enqueue(SObject so, String action) {
        objectsToEnqueue.actionType = action;
        objectsToEnqueue.objects.add(so);
    }

}