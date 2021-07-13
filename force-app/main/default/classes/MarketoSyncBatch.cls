global with sharing class MarketoSyncBatch implements Database.Batchable<sObject> {

    global MarketoSyncBatch() {
        
      
    
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'select id, Marketo_Sync__c, Student_Count__c, AccountId, Email, Manager__c, Last_Marketo_Sync_Update__c from Contact WHERE Email != null ORDER BY AccountId';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Contact> scope) {

        List<Contact> contactsToUpdate = new List<Contact>();
        Map<Id, Contact> mapOfContactsToUpdate = new Map<Id, Contact>();
        Set<Id> scopeSet = new Set<Id>();
        Set<String> INACTIVE_STUDENT_STATUS_VALUES = new Set<String>{'Dropped Out', 'Withdrawal', 'Not Participating'};

        Map<Id, Boolean> contactsToSetSync = new Map<Id,Boolean>();
        Map<Id,Id> contactManagerMap = new Map<Id,Id>();
        Marketo_Batch_Sync_Setting__mdt mbss = [SELECT Id, Active_Months__c FROM Marketo_Batch_Sync_Setting__mdt WHERE DeveloperName = 'Active_Months' LIMIT 1];
        Integer activeMonths = integer.valueOf(mbss.Active_Months__c);
        Date activeDate = Date.today().addMonths(-activeMonths);

        for (Contact con : scope){
            scopeSet.add(con.Id);
            system.debug(con.Manager__c);
            if (con.Manager__c != null){
                contactManagerMap.put(con.Id, con.Manager__c);
            }
            

            if (con?.Student_Count__c == null || con?.Student_Count__c == 0 && !con?.Email.contains('@execonline.com')){


                if (contactsToSetSync.get(con.Id) == null && contactManagerMap.get(con.Id) == null){
                    contactsToSetSync.put(con.Id, true);
                }

                if (contactsToSetSync.get(contactManagerMap.get(con.Id)) == null && contactManagerMap.get(con.Id) != null){
                    contactsToSetSync.put(contactManagerMap.get(con.Id), true);

                }
                
                
            }
        }

        system.debug(contactManagerMap.size());
        List<Student__c> students = [SELECT Id, Program__r.Course_End_Date__c, Contact__c FROM Student__c WHERE Contact__c IN:scopeSet AND Status__c NOT IN:INACTIVE_STUDENT_STATUS_VALUES ORDER BY Program__r.Course_End_Date__c DESC];
     
        for (Student__c student : students){
            Date courseEndDate = student.Program__r.Course_End_Date__c;
            Id managerId = contactManagerMap.get(student.Contact__c);
            Id studentContactId = student.Contact__c;
            if (courseEndDate >= activeDate || courseEndDate == null){
                system.debug('setting ' + studentContactId + ' true');
                system.debug(contactsToSetSync.get(studentContactId));
                if (contactsToSetSync.get(studentContactId) == null){
                    contactsToSetSync.put(studentContactId, true);
                }
                system.debug(contactsToSetSync.get(managerId));
                if (contactsToSetSync.get(managerId) == null){
                    contactsToSetSync.put(managerId, true);
                }
                
            }
            else if (contactsToSetSync.get(studentContactId) == null){contactsToSetSync.put(studentContactId, false);

                if (contactsToSetSync.get(managerId) == null && managerId != null){
                    contactsToSetSync.put(managerId, false);
                    system.debug('adding ' + managerId + ' manager to sync');
                }
                system.debug('setting ' + studentContactId + ' false');}
            
        }

        List<Contact> managers = [SELECT Id, Marketo_Sync__c, Last_Marketo_Sync_Update__c FROM Contact WHERE Id IN:contactManagerMap.values()];

        for (Contact manager : managers){

            Boolean syncValue = contactsToSetSync.get(manager.Id) != null ? contactsToSetSync.get(manager.Id) : false;

            if (manager.Marketo_Sync__c != syncValue && manager.Last_Marketo_Sync_Update__c != Date.today()){
                manager.Marketo_Sync__c = syncValue;
                manager.Last_Marketo_Sync_Update__c = Date.today();

                if (mapOfContactsToUpdate.get(manager.Id) == null){
                    mapOfContactsToUpdate.put(manager.Id, manager);
                }

            }
        }

        for (Contact con : scope){

            Boolean syncValue = contactsToSetSync.get(con.Id) != null ? contactsToSetSync.get(con.Id) : false;

            if (con.Marketo_Sync__c != syncValue && con.Last_Marketo_Sync_Update__c != Date.today()){
                con.Marketo_Sync__c = syncValue;
                con.Last_Marketo_Sync_Update__c = Date.today();

                if (mapOfContactsToUpdate.get(con.Id) == null){
                    mapOfContactsToUpdate.put(con.Id, con);
                }
               
            }
        }

        if (!mapOfContactsToUpdate.isEmpty()){
            system.debug(mapOfContactsToUpdate.size());
            update mapOfContactsToUpdate.values();
        }
    }

    global void finish(Database.BatchableContext BC) {

      
    }
}