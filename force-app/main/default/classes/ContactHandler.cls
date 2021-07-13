global with sharing class ContactHandler implements ITrigger {
    private CalloutBuffer.ObjectsToEnqueueWrapper objectsToEnqueue = new CalloutBuffer.ObjectsToEnqueueWrapper();

    Set<String> contactTypesToBuffer = ContactService.contactTypesToBuffer;
	private Set<Id> accountsToCalculateEpc = new Set<Id>();
    global static TriggerConfiguration__c triggerConfig = TriggerConfiguration__c.getInstance();
    global static Boolean enableAutoCalculateEPCUtilization = triggerConfig.Enable_Auto_Calculate_EPC_Utilization__c;
    private Map<Id, String> contactAccountTypeMap = new Map<Id, String>();
    private Set<Id> accountChanged = new Set<Id>();
    public static Id userProfileId = userinfo.getProfileId();
    public static String currentProfileName = [Select Id,Name from Profile where Id=:userProfileId].Name;

    public void bulkBefore() {
    }

    public void bulkAfter() {
   		Set<Id> ids = new Set<Id>();
        if (!Trigger.isDelete) {
            ids=Trigger.newMap.keySet();
        } else {
            ids=Trigger.oldMap.keySet();
        }
		List<Contact> triggerContacts = new List<Contact>([SELECT Id, Account.Type from Contact WHERE Id IN :ids]);
		for (Contact c:triggerContacts) {
			contactAccountTypeMap.put(c.id, c.Account.Type);
		}
    }

    public void beforeInsert(SObject so) {

    }

    public void beforeUpdate(SObject oldSo, SObject so) {

        Contact con    = (Contact) so;
        Contact oldCon = (Contact) oldSo;

        if (con.AccountId != oldCon.AccountId){

            accountChanged.add(con.Id);
        }

    }

    public void beforeDelete(SObject so) {
    }

    public void beforeUnDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
        Contact contact = (Contact) so;
        if (contact.Email != null && 
          CalloutBufferService.doCalloutForContactType(contact) && 
          AccountService.accountTypePlatformSynced(contactAccountTypeMap.get(contact.Id))) {
            enqueue(contact, 'POST');
        }
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        Contact contact = (Contact)so;
        Contact oldContact = (Contact)oldSo;
		Integer count = 0;
        
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        count++;
        	
        if (
          CalloutBuffer.hasIntegrationFieldChanged(contact, oldContact) && 
          contact.Email != null && 
          CalloutBufferService.doCalloutForContactType(contact) && 
          AccountService.accountTypePlatformSynced(contactAccountTypeMap.get(contact.Id)) && !System.isBatch()
        ) {
            enqueue(contact, 'PUT');
        }
        
		if (enableAutoCalculateEPCUtilization &&
			EpcServiceV2.shouldFireEpcCalcFromFieldChange(oldContact, contact) && !System.isBatch()
        ) {
			accountsToCalculateEpc.add(oldContact.AccountId);
			accountsToCalculateEpc.add(contact.AccountId);
		}

    }

    public void afterDelete(SObject so) {
        Contact contact = (Contact)so;
    }

    public void afterUnDelete(SObject so) {
        Contact contact = (Contact) so;
        if (contact.Email != null && 
        CalloutBufferService.doCalloutForContactType(contact) && 
        AccountService.accountTypePlatformSynced(contactAccountTypeMap.get(contact.Id))) {
            //enqueue(contact, 'POST');
        }
    }

    public void andFinally() {
        if (!objectsToEnqueue.isEmpty()) {
            CalloutBuffer.enqueueObjects(objectsToEnqueue);
		}
        if (!accountsToCalculateEpc.isEmpty()) {
        	System.Debug('accountsToCalculateEpc.size()='+accountsToCalculateEpc.size());
        	EpcServiceV2 epcHelper = new EpcServiceV2(accountsToCalculateEpc);
        	ID jobID = System.enqueueJob(epcHelper);
        }

        if (!accountChanged.isEmpty() && currentProfileName != 'System Administrator'){

            List<Student__c> studentsExist = [SELECT Id, Contact__c FROM Student__c WHERE Contact__c IN:accountChanged];

            if (!studentsExist.isEmpty()){
                Trigger.new[0].addError('You can not change the Account for a Contact that has related Student records.');
            }
        }
    }

    private void enqueue(SObject so, String action) {
        objectsToEnqueue.actionType = action;
        objectsToEnqueue.objects.add(so);
    }

}