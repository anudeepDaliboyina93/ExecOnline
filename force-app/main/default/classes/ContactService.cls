/**
 * ContactService.cls
 * Copyright 2016 Wired Triangle, LLC
 * http://www.wiredtriangle.com
 */
public class ContactService
{
	public static void pushToContactSync(List<Id> contactIdsForSync)
	{
		List<Contact_For_Sync__c> contactsForSync = new List<Contact_For_Sync__c>();
		for (Id contactId : contactIdsForSync) {
			Contact_For_Sync__c contactForSync = new Contact_For_Sync__c(Contact__c=contactId);
			contactsForSync.add(contactForSync);
		}
		insert contactsForSync;
	}

	public static Set<String> contactTypesToBuffer {
		get {
			if (contactTypesToBuffer == null) {
				contactTypesToBuffer = new Set<String> {
					'Student',
					'Student - Repeat',
					'Coach',
					'Professor',
					'Auditor'
				};
				return contactTypesToBuffer;
			}
			else {
				return contactTypesToBuffer;
			}
		}
	}
}