global with sharing class currentStudentBatch implements Database.Batchable<sObject> {

    global currentStudentBatch() {
        
   system.debug('starting batch');
    
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Current_Student__c, Current_HIC_Student__c, Current_NM_Student__c FROM Contact WHERE Student_Count__c > 0 ORDER BY AccountId';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Contact> scope) {

        Set<Id> scopeSet = new Set<Id>();
        List<Contact> contactsToUpdate = new List<Contact>();

        for (Contact con : scope){
            scopeSet.add(con.Id);
        }
        Set<String> ACTIVE_STUDENT_STATUS_VALUES = new Set<String>{'Prospect','Registered','Enrolled'};
        List<Student__c> students = [SELECT Id, Student_Type__c, Status__c, Contact__c FROM Student__c WHERE Contact__c IN:scopeSet AND Status__c LIKE:ACTIVE_STUDENT_STATUS_VALUES];

Map<Id,Id> currentStudentMap = new Map<Id,Id>();
Map<Id,Id> currentHICStudentMap = new Map<Id,Id>();
Map<Id,Id> currentNMStudentMap = new Map<Id,Id>();

for (Student__c student : students){
    switch on student.Student_Type__c {
        when 'Current Student' {
            currentStudentMap.put(student.Contact__c, student.Id);
        }
        when 'Current HIC Student' {
            currentHICStudentMap.put(student.Contact__c, student.Id);

        }
        when 'Current NM Student' {
             currentNMStudentMap.put(student.Contact__c, student.Id);

        }
    }
}

for (Contact con : scope){
    
con.Current_Student__c = currentStudentMap.get(con.Id);
con.Current_HIC_Student__c = currentHICStudentMap.get(con.Id);
con.Current_NM_Student__c = currentNMStudentMap.get(con.Id);

contactsToUpdate.add(con);
}



update contactsToUpdate;
    }

    global void finish(Database.BatchableContext BC) {

      
      
    }
}