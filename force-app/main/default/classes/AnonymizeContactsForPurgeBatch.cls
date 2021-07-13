public class AnonymizeContactsForPurgeBatch implements Database.Batchable<sObject>, Database.Stateful {

    String query;
    List<String> contactExceptions;
    List<String> firstNames;
    List<String> lastNames;
    Set<Id> contactIds;
    Integer contactCasesSize;
    String earliestCreatedDate;
    String latestCreatedDate;
    String submittingUserEmail = UserInfo.getUserEmail();
    Integer taskSize;
    String csvHeader = 'RecordId, Object, Comment \n';
    String finalString = csvHeader;
    Set<Id> relatedStudentIds = new Set<Id>();

    public AnonymizeContactsForPurgeBatch(Set<Id> contactsToPurge) {

        firstNames = AnonymizeService.randomFirstNames;
        lastNames = AnonymizeService.randomLastNames;
        contactIds = contactsToPurge;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
      
        query =  'SELECT ID, FirstName, LastName, Email, Anonymous__c, Preferred_Name__c FROM Contact Where Id IN:contactIds';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Contact> contacts) {

        Set<Id> deleteRelatedRecords = new Set<Id>();
        for (Contact c : contacts) {
            c.firstname = AnonymizeService.randomValue(firstNames);
            c.lastname = AnonymizeService.randomValue(lastNames);
            c.Preferred_Name__c = c.firstname + ' ' + c.lastname;
            c.email = c.firstname + '.' + c.lastname + '+' + c.id + '@' + AnonymizeService.emailSuffix;
            c.Anonymous__c = true;

            String objectType = 'Contact';

            String record = c.Id + ',' + objectType + ', Delete from backups' + '\n';

            finalString = finalString + record;

            deleteRelatedRecords.add(c.Id);
        }

        update contacts;

        if (!deleteRelatedRecords.isEmpty()){

          List<Case>       contactCases = [SELECT Id, CreatedDate FROM Case WHERE ContactId IN:deleteRelatedRecords ORDER BY CreatedDate];
          List<Student__c> students     = [SELECT Id FROM Student__c WHERE Contact__c IN:deleteRelatedRecords];

            for (Student__c s : students){

                relatedStudentIds.add(s.Id);

            }
                if (!contactCases.isEmpty()){

                    contactCasesSize    = contactCases.size() - 1;
                    earliestCreatedDate = contactCases[0].CreatedDate.format('MMMMM dd, yyyy');
                    latestCreatedDate   = contactCases[contactCasesSize].CreatedDate.format('MMMMM dd, yyyy');
                }
                    

            for (Case c : contactCases){

                
                String objectType = 'Case';
    
                String record = c.Id + ',' + objectType + ', Delete from backups' + '\n';
    
                finalString = finalString + record;
            }

                            delete contactCases;

            List<EventRelation> eventRealtions = [SELECT Id, EventId FROM EventRelation WHERE RelationId IN:deleteRelatedRecords];

            Set<Id> eventSet = new Set<Id>();
            for (EventRelation er : eventRealtions){

                eventSet.add(er.EventId);

            }

            List<Event> eventsToDelete = [SELECT Id FROM Event WHERE Id IN:eventSet];

            taskSize = eventsToDelete.size();

            delete eventsToDelete;
            
            List<Task> tasksToDelete = [SELECT Id FROM Task WHERE WhoId IN:deleteRelatedRecords];
                        

            List<TaskRelation> tr = [SELECT Id, TaskId FROM TaskRelation WHERE RelationId IN:deleteRelatedRecords];
            Set<Id> relatedTasks = new Set<Id>();

            for (TaskRelation t : tr){

                relatedTasks.add(t.TaskId);

            }

            List<Task> moreTaskToDelete = [SELECT Id FROM Task WHERE Id IN:relatedTasks];
            tasksToDelete.addAll(moreTaskToDelete);
            taskSize = taskSize + tasksToDelete.size();

            for (Task t: tasksToDelete){

                String objectType = 'Task';
    
                String record = t.Id + ',' + objectType + ', Delete from backups' + '\n';
    
                finalString = finalString + record;
            }
            
            
                            delete tasksToDelete;


                List<ContactHistory> conHistory = [SELECT Id FROM ContactHistory WHERE ContactId IN:deleteRelatedRecords];

                            for (ContactHistory hist : conHistory){
                
                                
                                String objectType = 'ContactHistory';
                    
                                String record = hist.Id + ',' + objectType + ', Delete from backups' + '\n';
                    
                                finalString = finalString + record;
                            }
                
                            delete conHistory;

                List<Student__History> studHistory = [SELECT Id FROM Student__History WHERE ParentId IN:relatedStudentIds];

                        for (Student__History hist : studHistory){
                
                                
                            String objectType = 'Student__History';
        
                            String record = hist.Id + ',' + objectType + ', Delete from backups' + '\n';
        
                            finalString = finalString + record;
                }
    
                            delete studHistory;

        }

    }

    public void finish(Database.BatchableContext BC) {
        
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        blob csvBlob = Blob.valueOf(finalString);
        string csvname= 'GDPRRequest.csv';
        csvAttc.setFileName(csvname);
        csvAttc.setBody(csvBlob);
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {submittingUserEmail};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Anonymizing contacts has finished! ');
        String Message = String.valueOf(contactIds.size()) + ' contacts have been processed and marked anonymous. <br/ >';
        Message += String.valueOf(contactCasesSize) + ' cases have been purged! <br />';
        Message += 'The case date range purged is from ' + String.valueOf(earliestCreatedDate) + ' - ' + String.valueOf(latestCreatedDate) + '<br />';
        Message += String.valueOf(taskSize) + ' emails/activities have been deleted.';
        mail.setHTMLBody( Message);
        mail.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });


    }

}