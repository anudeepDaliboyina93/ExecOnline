public class AccountService {

    public static final Set<String> TEST_ACCOUNT_NAMES = new Set<String>{'QA - org','ExecOnline, Inc.'};
    public static final String ACCOUNT_DELETE_ERROR = 'You can not delete an Account that has Students';

    public static boolean accountTypePlatformSynced(String accountType) {
    	if (accountType == 'Business School' || 
             accountType == 'Channel Partner' ||
             accountType == 'Client' ||
             accountType == 'Client Non Enterprise' ||
             accountType == 'Lapsed Client' ||
             accountType == 'Visited'
           ) {
            return(TRUE);
        }
    	return(FALSE);
    }

    public static void handleDeletedAccounts(Map<Id, Account> deletedAccountsMap) {
        if(!UserUtility.isSysAdmin() || Test.isRunningTest()) { 
            verifyDeletedAccountsHaveNoStudents(deletedAccountsMap);
        }
    }

    static void verifyDeletedAccountsHaveNoStudents(Map<Id, Account> deletedAccountsMap) {
        // if there are students related to an account, do not delete if not sys admin
        // this is to prevent sync issues with external the platform
        List<AggregateResult> studentAr = [SELECT COUNT(Id), Contact__r.AccountId accId FROM Student__c WHERE Contact__r.AccountId IN :deletedAccountsMap.keySet() GROUP BY Contact__r.AccountId];
        for(AggregateResult ar : studentAr) {
            deletedAccountsMap.get((Id)ar.get('accId')).addError(ACCOUNT_DELETE_ERROR);
        } 
    }

    public static void handleAccountIdsToTouchContacts(Set<Id> accountIdsToTouchContacts) {
        Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id FROM Contact WHERE AccountId IN :accountIdsToTouchContacts]);
        List<Id> contactIdList = new List<Id>();

        contactIdList.addAll(contactMap.keySet());
        ContactService.pushToContactSync(contactIdList);
    }

    public static void syncAccountFieldsToStudents(Map<Id, Account> accountsMap) {
        // get related students
        List<Student__c> studentList = [SELECT Id, Contact__r.AccountId FROM Student__c WHERE Contact__r.AccountId IN :accountsMap.keyset() AND Status__c IN :StudentHandler.ACTIVE_STUDENT_STATUS_VALUES AND Contact__r.Account.Name NOT IN :TEST_ACCOUNT_NAMES];
        syncAccountFieldsToStudents(accountsMap, studentList, true);
    }

    public static void syncAccountFieldsToStudents(List<Student__c> studentList) {
        // pull out contact ids to query for parent account obj info
        Set<Id> contactIds = new Set<Id>();
        for(Student__c s : studentList) {
            contactIds.add(s.Contact__c);
        }
        Map<Id, Account> accountsMap = new Map<Id, Account>();
        Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, AccountId, Account.Org_Tech_Survey_Req_Text__c FROM Contact WHERE Id IN :contactIds AND Account.Name NOT IN :TEST_ACCOUNT_NAMES]);
        for(Student__c s : studentList) {
            Contact studentsContact = contactMap.get(s.Contact__c);
            if(studentsContact != null) {
                // set the relational Contact__r to the Contact record
                s.Contact__r = studentsContact;
                accountsMap.put(studentsContact.AccountId, studentsContact.Account);
            }
        }
        
        syncAccountFieldsToStudents(accountsMap, studentList, false);
    }

    // need to sync this field to provide the account level data to each student to leverage in Survey Gizmo bc Survery Gizmo cant traverse relational data
    // only need to sync on active students bc it is irrelevant on historic students
    public static void syncAccountFieldsToStudents(Map<Id, Account> accountsMap, List<Student__c> studentList, Boolean doUpdate) {
        for(Student__c s : studentList) {
            if(s.Contact__r.AccountId != null) {
                s.Org_Tech_Survey_Req_Text__c = accountsMap.get(s.Contact__r.AccountId).Org_Tech_Survey_Req_Text__c;
            }
        }
        if(doUpdate) {
            StudentHandler.bypassTriggerLogic = true;
            update studentList;
            StudentHandler.bypassTriggerLogic = false;
        }
    }
}