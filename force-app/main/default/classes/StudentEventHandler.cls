public class StudentEventHandler extends TriggerHandler {

    public override void afterInsert(Map<Id, SObject> newItemMap) {
        setStudentsPrevAndNextSessions((List<Student_Event__c>)newItemMap.values());
        populateRollups((List<Student_Event__c>)newItemMap.values());
    }

    public override void afterUpdate(Map<Id, SObject> newItemMap, Map<Id, SObject> oldItemMap) {
        setStudentsPrevAndNextSessions((List<Student_Event__c>)newItemMap.values());
        populateRollups((List<Student_Event__c>)newItemMap.values());
    }

    public override void afterDelete(Map<Id, SObject> oldItemMap) {
        setStudentsPrevAndNextSessions((List<Student_Event__c>)oldItemMap.values());
    }

    private void setStudentsPrevAndNextSessions(List<Student_Event__c> studentEvents) {
        Set<Id> studentIds = ApexUtility.getIdSetFromList(studentEvents, 'Student__c');
        List<Student__c> students = getStudentsNextScheduledEvent(studentIds);

        List<Student__c> studentsToUpdate = new List<Student__c>();
        for(Student__c s : students) {
            Student_Event__c nextScheduledEvent = s.Student_Events__r.isEmpty() ? new Student_Event__c() : s.Student_Events__r[0];
            
            if(s.Next_Session__c != null && eventWasAttended(s.Next_Session__r)) {
                setPreviousSessionDataFromNextSessionData(s);
                setNextSessionData(s, nextScheduledEvent);
                studentsToUpdate.add(s);
            } else if(s.Next_Session__c != nextScheduledEvent.Id || s.Next_Session_Date__c != nextScheduledEvent.Start_Time__c) {
                setNextSessionData(s, nextScheduledEvent);
                studentsToUpdate.add(s);
            }
        }

        if(studentsToUpdate.size() > 0) {
            update studentsToUpdate;
        }
    }

    private Boolean eventWasAttended(Student_Event__c event) {
        return event.Status__c == 'Completed' || event.Status__c.startsWith('attended');
    }

    private void setPreviousSessionDataFromNextSessionData(Student__c student) {
        // don't overwrite a prev value with null
        if(student.Next_Session__c == null) {
            return;
        }
        student.Previous_Session__c = student.Next_Session__c;
        student.Previous_Session_Date__c = student.Next_Session__r.Start_Time__c;
        student.Previous_Session_Status__c = student.Next_Session__r.Status__c;
    }

    private void setNextSessionData(Student__c student, Student_Event__c event) {
        student.Next_Session__c = event.Id;
        student.Next_Session_Date__c = event.Start_Time__c;
        student.Next_Session_Status__c = event.Status__c;
    }

    private List<Student__c> getStudentsNextScheduledEvent(Set<Id> studentIds) {
        return [SELECT Id, Next_Session_Date__c, Next_Session__c, Next_Session__r.Start_Time__c,  Next_Session__r.Status__c,
                    (SELECT Id, Event_Type__c, Start_Time__c,  Status__c
                    FROM Student_Events__r 
                    WHERE Status__c IN ('Scheduled','not_set') AND Start_Time__c > :System.now() AND Event_Type__c = 'Coaching'
                    ORDER BY Start_Time__c ASC LIMIT 1)
                FROM Student__c
                WHERE Id IN :studentIds];
    }

    private void populateRollups(List<Student_Event__c> studentEvents){

        Map<Id, Student__c> studentsToUpdate = new Map<Id, Student__c>();
        Set<Id> studentIds = ApexUtility.getIdSetFromList(studentEvents, 'Student__c');

        List<Student__c> studentSessionsScheduled = new List<Student__c>();
        List<Student__c> studentSessionsUtilized  = new List<Student__c>();

        studentSessionsScheduled = [SELECT Id, (SELECT Id, Status__c FROM Student_Events__r WHERE Status__c != 'Removed'), Number_of_Sessions_Scheduled__c, Number_of_Sessions_Utilized__c FROM Student__c WHERE Id IN:studentIds];
        studentSessionsUtilized  = [SELECT Id, (SELECT Id, Status__c FROM Student_Events__r WHERE Status__c IN ('attended_video', 'attended_phone', 'attended_audio', 'absent', 'canceled')), Number_of_Sessions_Scheduled__c, Number_of_Sessions_Utilized__c FROM Student__c WHERE Id IN:studentIds];

        for (Student__c s : studentSessionsScheduled){

            if (studentsToUpdate.get(s.Id) == null){

                Student__c student  = new Student__c();

                student.Id = s.Id;
                student.Number_of_Sessions_Scheduled__c = s.Student_Events__r.size();
                student.Number_of_Sessions_Utilized__c  = s.Number_of_Sessions_Utilized__c;
    
                studentsToUpdate.put(student.Id, student);
            }
        }

        for (Student__c s : studentSessionsUtilized){

            if (studentsToUpdate.get(s.Id) == null){

                Student__c student  = new Student__c();

                student.Id = s.Id;
                student.Number_of_Sessions_Utilized__c = s.Student_Events__r.size();
    
                studentsToUpdate.put(student.Id, student);
            }

            else if (studentsToUpdate.get(s.Id) != null){

                studentsToUpdate.get(s.Id).Number_of_Sessions_Utilized__c = s.Student_Events__r.size();

            }
        }

        update studentsToUpdate.values();
    }

}