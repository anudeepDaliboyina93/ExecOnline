global class SetCurrentStudentBatch implements Database.Batchable<sObject> {

	String query;
	private String programId {get; set;}

	global SetCurrentStudentBatch(String programId) {
		this.programId = programId;
		query = 'Select Contact__c, Contact__r.Current_Student__c from Student__c where Program__c = :programId';
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<sObject> scope) {

		Map<Id, Contact> contactsById = new Map<Id, Contact>();
		for (Student__c student : (List<Student__c>) scope) {
			if (contactsById.get(student.Contact__c) == null) {
				Contact contact = student.Contact__r;
				contact.Current_Student__c = student.Id;
				contactsById.put(contact.Id, contact);
			} else {
				contactsById.get(student.Contact__c).Current_Student__c = student.Id;
			}

		}

		List<Contact> contactsToUpdate = new List<Contact>(contactsById.values());

		if (!contactsToUpdate.isEmpty()) {
			update contactsToUpdate;
		}
	}

	global void finish(Database.BatchableContext BC) {

	}

}