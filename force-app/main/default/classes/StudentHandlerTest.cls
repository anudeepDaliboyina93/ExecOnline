@isTest
private class StudentHandlerTest
{

    @testSetup static void setupTestData() {

        Test.startTest();
 
        Account              a1               = new Account();
        Account              a2               = new Account();
        Program__c           program          = TestDataFactory.getProgram();
        List<Account>        accountsToInsert = new List<Account>();
        List<Contact>        contactsToInsert = new List<Contact>();
        List<Student__c>     studentsToInsert = new List<Student__c>();
        Campaign             newCampaign      = new Campaign();
        CampaignMemberStatus cmStatus         = new CampaignMemberStatus(); 

        a1.Name     = 'Test Account 1';
        a1.Industry = 'Education';
        a2.Name     = 'Test Account 2';
        a2.Industry = 'Education';

        accountsToInsert.add(a1);
        accountsToInsert.add(a2);

        insert accountsToInsert;
        insert program;

        for (Integer i = 0; i < 20; ++i) {

            Contact con = new Contact();
    
            con.FirstName = 'Test' + i;
            con.LastName  = 'Contact' + i;
            con.Email     = 'testContact'+i+'@test.com';

            if (i < 10){

                con.AccountId             = a1.Id;
                con.Manager_s_Email__c    = 'testManager1@test.com';
                con.Manager_First_Name__c = 'Test1';
                con.Manager_Last_Name__c  = 'Manager1';
                con.Manager_s_Title__c    = 'Test Manager ';

            }

            else {
                
                con.AccountId             = a2.Id;
                con.Manager_s_Email__c    = 'testManager2@test.com';
                con.Manager_First_Name__c = 'Test2';
                con.Manager_Last_Name__c  = 'Manager2';
                con.Manager_s_Title__c    = 'Test Manager ';
        }

        contactsToInsert.add(con);
            
        }

        insert contactsToInsert;

        for (Contact con : contactsToInsert){

            Student__c newStudent = new Student__c();

            newStudent.Program__c = program.Id;
            newStudent.Contact__c = con.Id;
            newStudent.Status__c  = 'Enrolled';
            newStudent.Manager__c = null;

            studentsToInsert.add(newStudent);
        }
        
        insert studentsToInsert;
        Test.stopTest();

    }

    @isTest
    static void updateStudentWithoutManager(){
        Test.startTest();

        List<Student__c> listOfStudents = [SELECT Id, Manager__c, Contact__c, Contact__r.Manager_s_Email__c FROM Student__c];

        List<CampaignMember> cmList = [SELECT Id FROM CampaignMember];
      
        for (Student__c student : listOfStudents){

            student.Manager__c = null;

        }

        update listOfStudents;

        Test.stopTest(); 

       List<Student__c> studentsWithManagers = [SELECT Id, Manager__c FROM Student__c WHERE Manager__c != null];
      
 
       System.assertEquals(20, studentsWithManagers.size());
    }

    @isTest
    static void updateManagerCampaignNotParticipating(){

        Campaign c = [SELECT Id, Name FROM Campaign LIMIT 1];

        Contact testManager1 = [SELECT Id, Email FROM Contact WHERE Email = 'testManager1@test.com' LIMIT 1];
        Map<Id, Student__c> students = new Map<Id, Student__c>([SELECT Id, Status__c, Manager__c, Manager_Email_Reported__c FROM Student__c WHERE Manager_Email_Reported__c ='testManager1@test.com']);

        for (Student__c student : students.values()){
            student.Status__c = 'Dropped Out';
        }

        CampaignMember manager = [SELECT Id, Status, CampaignId, ContactId FROM CampaignMember WHERE ContactId =:testManager1.Id LIMIT 1];
     
        Test.startTest();

        StudentHandler sh = new StudentHandler();

        sh.managerContactsIds.add(testManager1.Id);
        sh.campaignSet.add(c.Id);
        sh.campaignStudentMap.put(c.Id, null);

        update students.values();

        sh.updateCampaignMembersStatus();

        Test.stopTest();

        CampaignMember managerUpdated = [SELECT Id, Status, CampaignId FROM CampaignMember WHERE ContactId =:testManager1.Id LIMIT 1];
        List<CampaignMember> members = [SELECT Id, Status, CampaignId FROM CampaignMember WHERE CampaignId =:c.Id];

        Integer active   = 0;
        Integer inactive = 0;

        for (CampaignMember cm : members){
            if (cm.Status == 'Sent'){
                active = active +1;
            }

            else if (cm.Status == 'Not Participating'){

                inactive = inactive +1;

            }
        }

        System.assertEquals('Not Participating', managerUpdated.Status);
        System.assertEquals(active, inactive);
    }

    @isTest
    static void updateManagerCampaignReEnrolled(){

        Campaign c = [SELECT Id, Name FROM Campaign LIMIT 1];

        Contact testManager1 = [SELECT Id, Email FROM Contact WHERE Email = 'testManager1@test.com' LIMIT 1];

        CampaignMember manager = [SELECT Id, Status, CampaignId, ContactId FROM CampaignMember WHERE ContactId =:testManager1.Id LIMIT 1];
        Student__c student = [SELECT Id, Status__c FROM Student__c WHERE Manager_Email_Reported__c ='testManager1@test.com' LIMIT 1];

        student.Status__c = 'Not Participating';

        manager.Status = 'Not Participating';

        update manager;

        CampaignMember oldManager = [SELECT Id, Status, CampaignId, ContactId FROM CampaignMember WHERE ContactId =:testManager1.Id LIMIT 1];
        String oldManagerStatus = oldManager.Status;
       
        Test.startTest();

        StudentHandler sh = new StudentHandler();

        sh.managerReEnrolled.add(testManager1.Id);
        sh.campaignSet.add(c.Id);
        sh.campaignStudentMap.put(c.Id, null);

        update student;

        sh.updateCampaignMembersStatus();

        Test.stopTest();

        CampaignMember updatedManager = [SELECT Id, Status, ContactId, CampaignId FROM CampaignMember WHERE ContactId=:testManager1.Id AND CampaignId=:c.Id];

        String updatedManagerStatus = updatedManager.Status;

        System.assertNotEquals(oldManagerStatus, updatedManagerStatus);
        System.assertEquals('Sent', updatedManagerStatus);
    }

    @isTest
    static void testInsertStudentRegTagsIfNew() {
        // TODO use TestDataFactory
        insert new Tag__c(Name = 'testTag1', Name_External_Id__c = 'testTag1');

        Test.startTest();
        StudentHandler testStudentHandler = new StudentHandler();
        testStudentHandler.allTriggerStudentRegTagStringSet.add('testTag1');
        testStudentHandler.allTriggerStudentRegTagStringSet.add('testTag2');
        testStudentHandler.insertStudentRegTagsIfNew();
        Test.stopTest();

        List<Tag__c> allTestTags = [SELECT Name FROM Tag__c ORDER BY CreatedDate ASC];

        System.assertEquals(2, allTestTags.size());
 
    }

    @isTest
    static void testRegistrationTagCreateAndDelete() {
        TriggerConfiguration__c triggerConfig = TriggerConfiguration__c.getInstance();    
        triggerConfig.Enable_Student_Trgr_Mgr_Campaign__c= false;
        triggerConfig.Enable_Auto_Calculate_EPC_Utilization__c = false;
        triggerConfig.Enable_AccountTrigger__c = false;
        upsert triggerConfig;

        List<Tag__c> testTags = new List<Tag__c>();
        testTags.add(TestDataFactory.getTag('Written feedback'));
        testTags.add(TestDataFactory.getTag('Final feedback'));
        insert testTags;

        Program__c testProgram = TestDataFactory.getProgram();
        insert testProgram;
        Contact testContact = TestDataFactory.getContact();
        insert testContact;
       
        Student__c testStudent = new Student__c(Contact__c = testContact.Id, Program__c = testProgram.Id, Status__c = 'Enrolled', Registration_Tags__c = testTags[0].Name);
        insert testStudent;
        insert new Student_Tag__c(Student__c = testStudent.Id, Tag__c = testTags[0].Id);
        Student__c changedStudent = testStudent.clone();
        changedStudent.Id = testStudent.Id;
        changedStudent.Registration_Tags__c = testTags[1].Name;

        Test.startTest();
        StudentHandler handler = new StudentHandler();
        handler.handleStudentRegistrationTag(new Map<Id, Student__c>{changedStudent.Id => changedStudent}, new Map<Id, Student__c>{testStudent.Id => testStudent});
        
        Test.stopTest();

        List<Student_Tag__c> studentTags = [SELECT Id, Student__c, Tag__r.Name FROM Student_Tag__c WHERE Student__c = :testStudent.Id];

        System.assertEquals(1, studentTags.size());
        System.assertEquals(testTags[1].Name, studentTags[0].Tag__r.Name);
       
    }

    @isTest
    static void updateAccountAsLoading() {

        TriggerConfiguration__c triggerConfig = TriggerConfiguration__c.getInstance();    
        triggerConfig.Enable_Student_Trgr_Mgr_Campaign__c=TRUE;
        triggerConfig.Enable_Auto_Calculate_EPC_Utilization__c = true;
        upsert triggerConfig;

        Student__c student = [SELECT Id, Import_Uuid__c, Contact__r.Account.Id, Contact__c, Program__c FROM Student__c LIMIT 1];

        Account  studentAccount = new Account();
        Set<Id>  students       = new Set<Id>();

       students.add(student.Id);
       student.Import_Uuid__c = 'test value';
       studentAccount.Id = student.Contact__r.Account.Id;
       studentAccount.EPC_Autocalculation_Enabled__c = true;
       studentAccount.Is_Loading_Students__c = false;

       update studentAccount;

        Test.startTest();

        StudentHandler sh = new StudentHandler();

        update student;

        Student__c updatedStudent = [SELECT Id, Import_Uuid__c FROM Student__c WHERE Id=: student.Id];

        sh.updateAccountsAsLoadingStudents(students);

        updatedStudent.Import_Uuid__c = 'new test value';

        update updatedStudent;

        Test.stopTest();

        System.assertEquals('new test value', updatedStudent.Import_Uuid__c);

    }

    @isTest
    static void deleteAndUndeleteStudent() {

        TriggerConfiguration__c triggerConfig = TriggerConfiguration__c.getInstance();    
        triggerConfig.Enable_Student_Trgr_Mgr_Campaign__c=TRUE;
        triggerConfig.Enable_Auto_Calculate_EPC_Utilization__c = false;
        upsert triggerConfig;

        Student__c student = [SELECT Id, Contact__c, Program__c FROM Student__c LIMIT 1];

        Contact contact = [SELECT Id, Contact_Type__c FROM Contact WHERE Contact_Type__c != 'Manager' LIMIT 1];

        Test.startTest();

        StudentHandler sh = new StudentHandler();

        Student__c newStudent = TestDataFactory.getStudent(contact.Id);

        insert newStudent;

        delete newStudent;

        undelete newStudent;

        Test.stopTest();

        Student__c undeletedStudent = [SELECT Id, Contact__c, Program__c FROM Student__c WHERE Id =:newStudent.Id LIMIT 1];

        System.assertEquals(newStudent.Id, undeletedStudent.Id);

    }
}