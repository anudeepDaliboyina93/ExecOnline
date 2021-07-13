@isTest
public class StudentEventHandlerTest {

    @isTest
    static void testNextSessionInsert() {
        Contact testContact = TestDataFactory.getContact();
        insert testContact;
        Student__c student = TestDataFactory.getStudent(testContact.Id);
        insert student;
        Student_Event__c studentEvent =TestDataFactory.getStudentEventCoaching(student.Id);

        Test.startTest();
        insert studentEvent;
        Test.stopTest();

        student = [SELECT Id, Next_Session__c, Previous_Session__c FROM Student__c WHERE Id = :student.Id LIMIT 1];
        System.assertEquals(studentEvent.Id, student.Next_Session__c);
    }

    @isTest
    static void testSessionAttendedSetNext() {
        Contact testContact = TestDataFactory.getContact();
        insert testContact;
        Student__c student = TestDataFactory.getStudent(testContact.Id);
        insert student;
        List<Student_Event__c> studentEvents = new List<Student_Event__c>();
        studentEvents.add(TestDataFactory.getStudentEventCoaching(student.Id));
        studentEvents.add(TestDataFactory.getStudentEventCoaching(student.Id));
        insert studentEvents;

        Test.startTest();
        studentEvents[0].Status__c = 'attended';
        update studentEvents[0];
        Test.stopTest();

        student = [SELECT Id, Next_Session__c, Previous_Session__c FROM Student__c WHERE Id = :student.Id LIMIT 1];
        System.assertEquals(studentEvents[0].Id, student.Previous_Session__c);
        System.assertEquals(studentEvents[1].Id, student.Next_Session__c);
    }

    @isTest
    static void testNextSessionDeleted() {
        Contact testContact = TestDataFactory.getContact();
        insert testContact;
        Student__c student = TestDataFactory.getStudent(testContact.Id);
        insert student;
        List<Student_Event__c> studentEvents = new List<Student_Event__c>();
        studentEvents.add(TestDataFactory.getStudentEventCoaching(student.Id));
        studentEvents.add(TestDataFactory.getStudentEventCoaching(student.Id));
        insert studentEvents;

        Test.startTest();
        delete studentEvents[0];
        Test.stopTest();

        student = [SELECT Id, Next_Session__c, Previous_Session__c FROM Student__c WHERE Id = :student.Id LIMIT 1];
        System.assertEquals(null, student.Previous_Session__c);
        System.assertEquals(studentEvents[1].Id, student.Next_Session__c);
    }

    @isTest
    static void testPopulateRollups() {
        Contact testContact = TestDataFactory.getContact();
        insert testContact;
        Student__c student = TestDataFactory.getStudent(testContact.Id);
        insert student;
        Student_Event__c studentEvent =TestDataFactory.getStudentEventCoaching(student.Id);

        Test.startTest();
        insert studentEvent;

        Student_Event__c event = new Student_Event__c();

        event.Id = studentEvent.Id;
        event.Status__c = 'attended_phone';

        update event;
        Test.stopTest();

        student = [SELECT Id, Number_of_Sessions_Scheduled__c, Number_of_Sessions_Utilized__c FROM Student__c WHERE Id = :student.Id LIMIT 1];
        System.assertEquals(1, student.Number_of_Sessions_Scheduled__c);
        System.assertEquals(1, student.Number_of_Sessions_Utilized__c);
    }
}