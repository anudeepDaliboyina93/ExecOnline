/**
 * StudentHandler.cls
 * Copyright 2015 Wired Triangle, LLC
 * http://www.wiredtriangle.com
 */
global with sharing class StudentHandler implements ITrigger {

	public static Boolean bypassTriggerLogic = false;

    public Map<Id, Student__c> triggerMapStudents = new Map<Id, Student__c>();
    private Set<Id> studentContactIdSet = new Set<Id>();
    private Map <Id, Contact> studentContactMap = new Map<Id, Contact>();
    private static boolean alreadyRanRelatedCampaignLogic = false;
    @TestVisible
    public  List<Student__c> triggerListStudents;

    global static Boolean executeTouch = true;
    global static TriggerConfiguration__c triggerConfig = TriggerConfiguration__c.getInstance();
    global static Boolean forceManagerCMStatusUpdate = triggerConfig.forceManagerCMStatusUpdate__c;//for use in anonymous Apex, also will have hierarchical custom setting for this
    global static Boolean enableAutoCalculateEPCUtilization = triggerConfig.Enable_Auto_Calculate_EPC_Utilization__c;
    global static Set<String> utilizedStudentStatusValues = new Set<String>{'Registered','Enrolled','Graduated','Completed'};
    global static final Set<String> ACTIVE_STUDENT_STATUS_VALUES = new Set<String>{'Prospect','Registered','Enrolled'};
    global static final Set<String> INACTIVE_STUDENT_STATUS_VALUES = new Set<String>{'Dropped Out', 'Withdrawal', 'Not Participating'};

    private CalloutBuffer.ObjectsToEnqueueWrapper objectsToEnqueue = new CalloutBuffer.ObjectsToEnqueueWrapper();
	private Set<Id> accountsToCalculateEpc = new Set<Id>();

    private Map<Id, Contact> studentIdToStudentContact = new Map<Id, Contact>();
    private Map<Id, EPC_Utilization_Item__c> epcuiMap = new Map<Id, EPC_Utilization_Item__c>();

    @TestVisible
    private Set<String> allTriggerStudentRegTagStringSet = new Set<String>();
    
    private Map<String, EPC_Utilization_Item__c> studentIdEpcuiCatToEpcuiMap = new Map<String, EPC_Utilization_Item__c>();
    private static Map<String, Tag__c> tagNameToTagMap = new Map<String,Tag__c>();
    private Map<Id, Set<Student_Tag__c>> studentIdStudentTagSetMap = new Map<Id, Set<Student_Tag__c>>();
    private Map<Id, Set<Student_Tag__c>> studentIdStudentTagSetMapBefore = new Map<Id, Set<Student_Tag__c>>();
    private Map<Id, Map<String, Student_Tag__c>> studentId_TagStringStudentTagMap = new Map<Id,  Map<String,Student_Tag__c>>();
    private List<Student_Tag__c> studentTagsToDelete = new List<Student_Tag__c>();
    private List<Student__c> activeStudentsToSyncAccountFields = new List<Student__c>();
    private Set<Id> studentContactIds  = new Set<Id>();
    public Set<Id> managerContactsIds = new Set<Id>();
    public Set<Id> managerReEnrolled = new Set<Id>();

    public Map<Id, Student__c>  campaignStudentMap      = new Map<Id, Student__c>();
    private Map<Id, String>      campaignMemberStatusMap = new Map<Id, String>();
    private List<CampaignMember> campaignMembersToUpdate = new List<CampaignMember>();
    private Map<Id, Student__c> studentsThatNeedManager = new Map<Id, Student__c>();
    private Map<Id, Id> studentContactIdMap = new Map<Id, Id>();
    private Map<Id, Contact> contactMap = new Map<Id, Contact>();
    private Map<Id, String> contactsThatHaveManagerFields = new Map<Id, String>();
    private Map<Id, Contact> studentToContactMap = new Map<Id, Contact>();
    private Map<Id, Contact> managerMap = new Map<Id, Contact>();
    private Map<String, Contact> managerEmailMap = new Map<String, Contact>();
    private Map<Id,Id> contactIdToStudentId = new Map<Id, Id>();
    private Map<Id,Id> updateContacts = new Map<Id,Id>();
    private Map<Id, Student__c> studentsToUpdate = new Map<Id, Student__c>();
    private Map<String, String> managerCampaignMap = new Map<String, String>();
    private Map<Id,Id> managers = new Map<Id,Id>();
    private Map<Id, Student__c> contactIdToStudent = new Map<Id, Student__c>();
    private Set<String> Emails = new Set<String>();
    private Set<Id> managerSet = new Set<Id>();
    private Map<Id, CampaignMember> contactToCampaignMemberMap = new Map<Id, CampaignMember>();
    private Map<Id, String> campaignMembersToCreate = new Map<Id, String>();
    private Map<Id, String> managerEmailCampaignMap = new Map<Id, String>();
    private Map<String, CampaignMember> createCampaignMembers= new Map<String, CampaignMember>();
    private Set<Id> dontUpdateManagers = new Set<Id>();
    public Set<Id> campaignSet = new Set<Id>();
    private Set<Id> findCurrentStudent = new Set<Id>();
    private List<Contact> contactsToUpdate = new List<Contact>();
    private Map<Id, Id> futureStudentContactMap = new Map<Id, Id>();
    private Map<Id, Id> studentIdToContactIdMap = new Map<Id, Id>();
    private Map<Id, String> currentStudentType = new Map<Id, String>();
    private Map<Id, Contact> contactsMap = new Map<Id, Contact>();
    private Map<Id, Student__c> futureStudentMap = new Map<Id, Student__c>();
	private List<Student__c> lockRecords   = new List<Student__c>();
    private List<Student__c> unlockRecords = new List<Student__c>();
    private Set<Id> deleteRelatedEPC = new Set<Id>();
    private Map<Id, Id> buddyStudentIds = new Map<Id, Id>();


    public StudentHandler() {}

    public void populateVariables() {
        triggerListStudents = Trigger.new;
        if (Trigger.isUpdate || Trigger.isInsert) {
            triggerMapStudents = (Map<Id, Student__c>)Trigger.newMap;
        }

        if (Trigger.isAfter && enableAutoCalculateEPCUtilization) {
            for (Student__c st: triggerListStudents){
                if (studentId_TagStringStudentTagMap.get(st.Id) == null) {
                    studentId_TagStringStudentTagMap.put(st.Id, new Map<String, Student_Tag__c>());
                }
            }
            List<Student_Tag__c> studentTagList = [SELECT Id, Student__c, Tag__c, Tag__r.Name FROM Student_Tag__c WHERE Student__c IN :triggerMapStudents.keySet()];
            for (Student_Tag__c studentTag : studentTagList ) {
                if (studentId_TagStringStudentTagMap.get(studentTag.Student__c).get(studentTag.Tag__r.Name) == null) {
                    studentId_TagStringStudentTagMap.get(studentTag.Student__c).put(studentTag.Tag__r.Name, studentTag);
                }
            }
        }

        for (Student__c st: triggerListStudents){
            studentContactIdSet.add(st.Contact__c);
            if (st.registration_tags__c != null) {
                allTriggerStudentRegTagStringSet.addAll(st.registration_tags__c.split(';'));
            }
        }

        String contactQueryFieldList = 'Id, AccountId';
     
        String contactQuery = 'SELECT ' + contactQueryFieldList + ' FROM Contact WHERE Id IN :studentContactIdSet';
        system.Debug(contactQuery); 

        studentContactMap = new Map<Id, Contact>(
            (List<Contact>)Database.query(contactQuery)
        ); 
        
        for (Student__c st: triggerListStudents) {
            Contact c = studentContactMap.get(st.Contact__c);
            studentIdToStudentContact.put(st.Id,c);
        }
    }

    public void bulkBefore() {
        if (!bypassTriggerLogic && (Trigger.isInsert || Trigger.isUpdate)) {
            populateVariables();
        }
        if(Trigger.isInsert) {
            activeStudentsToSyncAccountFields.addAll((List<Student__c>)Trigger.new);
        }
    }

    public void bulkAfter() {

        if (!bypassTriggerLogic) {

            if (Trigger.isInsert || Trigger.isUpdate) {
                populateVariables();
                handleStudentImports((List<Student__c>)Trigger.new, Trigger.isInsert ? new Map<Id, Student__c>() : (Map<Id, Student__c>)Trigger.oldMap);

                findCurrentStudent.addAll(Trigger.newMap.keySet());
                
            }

            if(!allTriggerStudentRegTagStringSet.isEmpty() && enableAutoCalculateEPCUtilization) {
                insertStudentRegTagsIfNew();
            }

            if (!Trigger.isDelete && enableAutoCalculateEPCUtilization) {
                epcuiMap = new Map<Id,EPC_Utilization_Item__c>([SELECT Id, Category__c, Student__c, Status__c 
                            FROM EPC_Utilization_Item__c WHERE Student__c IN :Trigger.newMap.keySet()]); 
                //TODO Need to delete epcui if deleting student that had reg tags??
            
                for (EPC_Utilization_Item__c epcui:epcuiMap.values()) {
                    if (epcui.Student__c!=null) {
                        studentIdEpcuiCatToEpcuiMap.put(epcui.Student__c+':'+epcui.Category__c, epcui);
                    }
                }
            }
        }
    }

    public void beforeInsert(SObject so) {
        Student__c student = (Student__c) so;
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        Student__c student = (Student__c) so;
        Student__c oldStudent = (Student__c) oldSo;

        if(student.Status__c != oldStudent.Status__c && ACTIVE_STUDENT_STATUS_VALUES.contains(student.Status__c)) {
            activeStudentsToSyncAccountFields.add(student);
        }
    }

    public void beforeDelete(SObject so) {

    }

    public void beforeUnDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
        Student__c student = (Student__c) so;

        checkForManagerFields(student);
        findCurrentStudent.add(student.Id);

        if (!bypassTriggerLogic) {
            if (student.Program__c != null && student.Contact__c != null) {
                enqueue(student, 'POST');
            }  

            if (enableAutoCalculateEPCUtilization && !studentIsNewImport(student, null)) {    
                accountsToCalculateEpc.add(studentIdToStudentContact.get(student.Id).AccountId);
            }
        }
		studentIdToStudentContact.get(student.Id);
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        Student__c student = (Student__c) so;
        Student__c oldStudent = (Student__c) oldSo;

        if (!bypassTriggerLogic) {
            if (CalloutBuffer.hasIntegrationFieldChanged(student, oldStudent) && student.Program__c != null && student.Contact__c != null) {
                enqueue(student, 'PUT');
            }
        }

        if (!bypassTriggerLogic) {

            if (buddyChanged(student, oldStudent) ){
            
                buddyStudentIds.put(student.Buddy_Name__c, student.Id);
               
            }

            if (buddy2Changed(student, oldStudent) ){
            
                buddyStudentIds.put(student.Buddy_2_Name__c, student.Id);
               
            }

            if (oldStudent.Approved__c == false && student.Approved__c == true){

                lockRecords.add(student);
            }

            else if (oldStudent.Approved__c == true && student.Approved__c == false){
                unlockRecords.add(student);
            }
            checkForManagerFields(student);
            system.debug('new student status ' + student.Status__c + ' Old student status is' + oldStudent.Status__c);
            studentStatusChanged(student, oldStudent);
        }

        if (student.Status__c != oldStudent.Status__c && !ACTIVE_STUDENT_STATUS_VALUES.contains(student.Status__c)){
            findCurrentStudent.add(student.Id);
           
        }
        
		if (enableAutoCalculateEPCUtilization &&
            !bypassTriggerLogic &&
			EpcServiceV2.shouldFireEpcCalcFromFieldChange(oldstudent, Student) && 
            !studentIsNewImport(student, oldStudent) && student.Temp__c == false
		) {
			accountsToCalculateEpc.add(studentIdToStudentContact.get(student.Id).AccountId);
            //Student moved to new Account?
            if (studentIdToStudentContact.get(oldStudent.Id).AccountId!=studentIdToStudentContact.get(student.Id).AccountId) {
                accountsToCalculateEpc.add(studentIdToStudentContact.get(oldStudent.Id).AccountId);
            }
		}
    }
        // build Map of [Student.Id : Set<String> tagStrings] that should exist 
        //TODO need to find those that should be voided
        //studentIdTagStringSetMap.put(student.Id,studentRegTagStringSet);

    public void afterDelete(SObject so) {
        Student__c student = (Student__c) so;
        studentContactIdSet.add(student.Contact__c);

        if (student.Program__c != null && student.Contact__c != null) {
            enqueue(student, 'DELETE');
        }
        //TODO accountsToCalculateEpc
  
    }

    public void afterUnDelete(SObject so) {
        Student__c student = (Student__c) so;
        studentContactIdSet.add(student.Contact__c);

        if (student.Program__c != null && student.Contact__c != null) {
            enqueue(student, 'POST');
        }
        
        if (enableAutoCalculateEPCUtilization &&
            !bypassTriggerLogic) {
            String studentRegTagsString = student.registration_tags__c + '';
            System.Debug('studentRegTagsString='+studentRegTagsString);
            List<String> thisStudentRegTagsStringList = studentRegTagsString.split(';');
            for (String s:thisStudentRegTagsStringList) {
                allTriggerStudentRegTagStringSet.add(s);
            }
        }

        //TODO accountsToCalculateEpc
        
    }

    public void andFinally() {
        if(!bypassTriggerLogic && activeStudentsToSyncAccountFields.size() > 0) {
            AccountService.syncAccountFieldsToStudents(activeStudentsToSyncAccountFields);
        }

        if (!studentContactIdSet.isEmpty() && executeTouch && !System.isBatch()) {
            Map<Id, Contact> studentContactMap = new Map<Id, Contact>([Select id from Contact where Id in :studentContactIdSet]);
            List<Id> cIds = new List<Id>();
            cIds.addAll(studentContactMap.keySet());
            ContactService.pushToContactSync(cids);
        }

        if (!objectsToEnqueue.isEmpty()) {
            CalloutBuffer.enqueueObjects(objectsToEnqueue);
        }

        if (Trigger.isAfter && enableAutoCalculateEPCUtilization && !bypassTriggerLogic && triggerIsInsertUpdateOrUndelete()) {
            handleStudentRegistrationTag((Map<Id, Student__c>)Trigger.newMap, Trigger.isInsert ? new Map<Id, Student__c>() : (Map<Id, Student__c>)Trigger.oldMap);
        }

        if (!bypassTriggerLogic && !alreadyRanRelatedCampaignLogic & (triggerConfig.Enable_Student_Trgr_Mgr_Campaign__c || Test.isRunningTest() )  && Trigger.isAfter) {
            alreadyRanRelatedCampaignLogic=TRUE;

  
  
           findRelatedManagerAndUpdateStudentAndContact();
           checkCampaignMembersExist();
           updateCampaignMembersStatus(); 
		   lockRelatedRecords();
           unlockRelatedRecords();
           checkBuddyPrograms();

           try {
            updateCurrentStudentOnContact();
           } catch(Exception e){
            sendErrorMail(String.valueOf(e.getMessage()));
           }

        }
		
		if (!deleteRelatedEPC.isEmpty()){
            system.debug(Trigger.operationType);

            List<EPC_Utilization__c>      recordsToDelete = [SELECT Id, Student__c, Account__c, EPC_Utilization_Item__r.Student__c FROM EPC_Utilization__c WHERE Student__c IN:deleteRelatedEPC OR EPC_Utilization_Item__r.Student__c IN:deleteRelatedEPC];
           // List<EPC_Utilization_Item__c> epcuiToDelete   = [SELECT Id, Student__c FROM EPC_Utilization_Item__c WHERE Student__c IN:deleteRelatedEPC];
            Set<Id> acctSet = new Set<Id>();

            for (EPC_Utilization__c epcu : recordsToDelete){
                acctSet.add(epcu?.Account__c);
            }

          //  if (!epcuiToDelete.isEmpty()){

             //   delete epcuiToDelete;
           // }

            if (!recordsToDelete.isEmpty()){

                delete recordsToDelete;

            }

            if (!acctSet.isEmpty()){
                accountsToCalculateEpc.addAll(acctSet);
            }

        }

        if (!accountsToCalculateEpc.isEmpty() && Trigger.isAfter && enableAutoCalculateEPCUtilization && !bypassTriggerLogic) {
        	System.Debug('accountsToCalculateEpc.size()='+accountsToCalculateEpc.size());
        	EpcServiceV2 epcHelper = new EpcServiceV2(accountsToCalculateEpc);
        	ID jobID = System.enqueueJob(epcHelper);
        }
    }

    private void enqueue(SObject so, String action) {
        objectsToEnqueue.actionType = action;
        objectsToEnqueue.objects.add(so);
    }

    @TestVisible
    private static Boolean buddyChanged(SObject student, SObject old){

        Student__c s = (Student__c) student;
        Student__c oldStudent = (Student__c) old;

        Boolean buddyChanged  = oldStudent.Buddy_Name__c != s.Buddy_Name__c ;
    

        return buddyChanged;
        
    }

    @TestVisible
    private static Boolean buddy2Changed(SObject student, SObject old){

        Student__c s = (Student__c) student;
        Student__c oldStudent = (Student__c) old;
      
        Boolean buddy2Changed = oldStudent.Buddy_2_Name__c != s.Buddy_2_Name__c;

        return  buddy2Changed ;
        
    }

    @TestVisible
    private void checkBuddyPrograms(){
        
        if (!buddyStudentIds.isEmpty()){

            Set<Id> buddySet = new Set<Id>();
            Map<String, String> buddyMap = new Map<String, String>();

            for (SObject s : Trigger.new){

            Student__c student = (Student__c) s;

            buddySet.add(student.Buddy_Name__c);
            buddySet.add(student.Buddy_2_Name__c);

          }

           List<Student__c> buddyProgramTeams = [SELECT Id, Program__c, Team__c, Contact__c FROM Student__c WHERE Contact__c IN:buddySet];

           for (Student__c student : buddyProgramTeams){

               String buddyProgramTeamString = String.valueOf(student.Program__c) + String.valueOf(student.Team__c);

               buddyMap.put(String.valueOf(student.Contact__c)+String.valueOf(student.Program__c), buddyProgramTeamString);
              
           }


            for (SObject s : Trigger.new){

                Student__c student = (Student__c) s;

                String programTeam        = student.Program__c != null && student.Team__c != null ? String.valueOf(student.Program__c) + String.valueOf(student.Team__c) : null;
                String buddyProgramTeam   = buddyMap.containsKey(String.valueOf(student.Buddy_Name__c)+String.valueOf(student.Program__c)) ? buddyMap.get(String.valueOf(student.Buddy_Name__c)+String.valueOf(student.Program__c)) : null;
                String buddy2ProgramTeam  = buddyMap.containsKey(String.valueOf(student.Buddy_2_Name__c)+String.valueOf(student.Program__c)) ? buddyMap.get(String.valueOf(student.Buddy_2_Name__c)+String.valueOf(student.Program__c)) : null;

                if (buddyProgramTeam == null && student.Buddy_Name__c != null){

                    doesProgramTeamMatch(student.Id, programTeam, buddyProgramTeam);
                  
                }

                if (buddy2ProgramTeam == null && student.Buddy_2_Name__c != null){

                    doesProgramTeamMatch(student.Id, programTeam, buddy2ProgramTeam);
                }

            }
        }
    }

    @TestVisible
    private void studentStatusChanged(SObject student, SObject o){
        Student__c s = (Student__c) student;
        Student__c oldStudent = (Student__c) o;

        system.debug(s.Status__c);
        system.debug(oldStudent.Status__c);

        if (ACTIVE_STUDENT_STATUS_VALUES.contains(s?.Status__c)){

            managerSet.add(s?.Manager__c);
        }


        Boolean containsInactiveValue = ((s?.Status__c != oldStudent?.Status__c) && INACTIVE_STUDENT_STATUS_VALUES.contains(s?.Status__c));
        Boolean containsActiveValue   = ((s?.Status__c != oldStudent?.Status__c) && ACTIVE_STUDENT_STATUS_VALUES.contains(s?.Status__c));

        if(containsInactiveValue ){

             campaignStudentMap.put(s?.Campaign_ID__c, s);

             if(!String.isEmpty(s?.Manager__c)){

                system.debug(s?.Manager__c);
                 managerContactsIds.add(s?.Manager__c);
                 system.debug(managerContactsIds.size());
             }
         }

         system.debug(containsActiveValue);
         if(containsActiveValue && s?.Manager__c != null && s?.Campaign_ID__c != null){
             campaignStudentMap.put(s?.Campaign_ID__c, s);
             managerReEnrolled.add(s?.Manager__c);
         }
     
    }

    @TestVisible
    private void checkForManagerFields(SObject so){
        Student__c student = (Student__c) so;

        if (hasReportedManager(student)){
            studentsThatNeedManager.put(student.Id, student);
            

            if (student.Contact__c != null){
                studentContactIdMap.put(student.Id, student.Contact__c);
                contactIdToStudentId.put(student.Contact__c, student.Id);
                contactIdToStudent.put(student.Contact__c, student);
            }
        }

        else{
            managerCampaignMap.put(student?.Manager__c,student?.Campaign_ID__c);
            managerSet.add(student?.Manager__c);
            system.debug(managerCampaignMap);
        }

        managerSet.add(student?.Manager__c);

        if (student?.Campaign_Id__c != null){
            campaignSet.add(student?.Campaign_Id__c);
        }
        
    }

    @TestVisible
    private void doesProgramTeamMatch(Id studentId, String programTeam, String programTeamToCompare){

        if (programTeam != programTeamToCompare){
            Trigger.newMap.get(studentId).addError('Learning Partners must be in the same Program and Team');
        }
    }

    @TestVisible
    private void updateCurrentStudentOnContact(){

        if (!findCurrentStudent.isEmpty()){

            populateCurrentStudentMaps();
            getFutureStudents();
  
            for (Id studentId : studentIdToContactIdMap.keySet()){

                Contact    studentContact        = contactsMap.get(studentIdToContactIdMap.get(studentId));
                String     currentType           = currentStudentType.get(studentId);
                Id         futureStudentId       = futureStudentContactMap.get(studentContact.Id);
                String     futureStudentCategory = futureStudentMap.get(futureStudentId)?.Program__r?.Program_Family__r?.Current_Student_Category__c != null ? futureStudentMap.get(futureStudentId)?.Program__r?.Program_Family__r?.Current_Student_Category__c : 'Current Student';
                Student__c currentStudent        = (Student__c)Trigger.newMap.get(studentId);
                String     studentStatus         = currentStudent.Status__c;

               switch on currentType {

                when null {

                    studentContact.Temp_Student_Type_Null__c = true;
                    studentContact.Current_Student_Message__c = studentId + ' ' + currentType + ' ' + futureStudentId + ' ' + futureStudentCategory;

                    contactsToUpdate.add(studentContact);

                    system.debug('null type');
                }

                when 'Current Student' {
                    system.debug('inside current student');

                    if (needsNewCurrentStudent(currentType, studentContact)){

                      studentContact.Current_Student__c = futureStudentId != null && futureStudentCategory == 'Current Student' ? futureStudentId : ACTIVE_STUDENT_STATUS_VALUES.contains(studentStatus) ? studentId : studentContact.Current_Student__c;
                      studentContact.Current_Student_Message__c = studentId + ' ' + currentType + ' ' + futureStudentId + ' ' + futureStudentCategory;

                        contactsToUpdate.add(studentContact);
                    }

                }

                when 'Current NM Student' {

                    if (needsNewCurrentStudent(currentType, studentContact)){

                        studentContact.Current_NM_Student__c = futureStudentId != null && futureStudentCategory == 'Current NM Student' ? futureStudentId : ACTIVE_STUDENT_STATUS_VALUES.contains(studentStatus) ? studentId : studentContact.Current_NM_Student__c;
                        studentContact.Current_Student_Message__c = studentId + ' ' + currentType + ' ' + futureStudentId + ' ' + futureStudentCategory;

                          contactsToUpdate.add(studentContact);
                      }
                }

                when 'Current HIC Student' {
                    
                    if (needsNewCurrentStudent(currentType, studentContact)){

                        studentContact.Current_HIC_Student__c = futureStudentId != null && futureStudentCategory == 'Current HIC Student' ? futureStudentId : ACTIVE_STUDENT_STATUS_VALUES.contains(studentStatus) ? studentId : studentContact.Current_HIC_Student__c;
                        studentContact.Current_Student_Message__c = studentId + ' ' + currentType + ' ' + futureStudentId + ' ' + futureStudentCategory;

                          contactsToUpdate.add(studentContact);
                      }
                }
            }
            }

            if (!contactsToUpdate.isEmpty()){
                update contactsToUpdate;
            }

        }
    }

    @TestVisible
    private void populateCurrentStudentMaps(){

        List<Student__c> students = [SELECT Id, Contact__c, Program__r.Program_Family__r.Current_Student_Category__c FROM Student__c WHERE Id IN:findCurrentStudent];

            for (Student__c student : students){
                studentIdToContactIdMap.put(student.Id, student.Contact__c);
                currentStudentType.put(student.Id, student.Program__r.Program_Family__r.Current_Student_Category__c);

            }

        contactsMap = new Map<Id,Contact>([SELECT Id, Current_HIC_Student__c, Current_HIC_Student__r.Status__c, Current_NM_Student__c, Current_NM_Student__r.Status__c, Current_Student__c, Current_Student__r.Status__c, Temp_Student_Type_Null__c FROM Contact WHERE Id IN:studentIdToContactIdMap.values()]);
    }

    @TestVisible
    private void getFutureStudents(){

            futureStudentMap = new Map<Id, Student__c>([SELECT Id, Contact__c, Program__r.Program_Family__r.Current_Student_Category__c, Status__c FROM Student__c WHERE Contact__c IN:contactsMap.keySet() AND Status__c NOT IN ('Dropped Out', 'Withdrawal', 'Not Participating', 'Graduated', 'Auditor')]);

            for (Student__c student : futureStudentMap.values()){

                futureStudentContactMap.put(student.Contact__c, student.Id);
            }
    }

    @TestVisible
    private static Boolean needsNewCurrentStudent(String studentType, Contact studentContact){

        switch on studentType {
            when 'Current Student' {

                return studentContact.Current_Student__c == null || (studentContact.Current_Student__c != null && !ACTIVE_STUDENT_STATUS_VALUES.contains(studentContact.Current_Student__r.Status__c));
            }

            when 'Current NM Student'{

                return studentContact.Current_NM_Student__c == null || (studentContact.Current_NM_Student__c != null && !ACTIVE_STUDENT_STATUS_VALUES.contains(studentContact.Current_NM_Student__r.Status__c));

            }

            when 'Current HIC Student'{

                return studentContact.Current_HIC_Student__c == null || (studentContact.Current_HIC_Student__c != null && !ACTIVE_STUDENT_STATUS_VALUES.contains(studentContact.Current_HIC_Student__r.Status__c));
            }
        }

        return false;

    }

    @TestVisible
    private static Boolean hasReportedManager(Student__c student){
        return (student.Manager__c == null && student.Manager_Email_Reported__c != null);
    }
	
	 @TestVisible
    private void lockRelatedRecords(){

        if (!lockRecords.isEmpty()){

        List<EPC_Utilization__c> relatedRecords = [SELECT Id, Student__c FROM EPC_Utilization__c WHERE Student__c IN:lockRecords]; 

        Approval.LockResult[] lrList = Approval.lock(relatedRecords, false);

        }
    }

    @TestVisible
    private void unlockRelatedRecords(){

        if (!unlockRecords.isEmpty()){

            List<EPC_Utilization__c> relatedRecords = [SELECT Id, Student__c FROM EPC_Utilization__c WHERE Student__c IN:unlockRecords]; 

            Approval.UnlockResult[] lrList = Approval.unlock(relatedRecords, false);
        }
    }

    @TestVisible
    private void findRelatedManagerAndUpdateStudentAndContact(){

        contactMap = new Map<Id, Contact>([SELECT Id, Email, Manager_First_Name__c, Manager_Last_Name__c, Manager_s_Email__c, Manager_s_Title__c FROM Contact WHERE Id in:studentContactIdMap.values()]);

        for (Student__c student : studentsThatNeedManager.values()){

            system.debug(contactMap?.get(student.Contact__c)?.Manager_s_Email__c);
            system.debug(contactMap.containsKey(student.Contact__c));

            if (contactMap?.get(student.Contact__c)?.Manager_s_Email__c != null){

                system.debug(contactMap?.get(student.Contact__c)?.Manager_s_Email__c);
                contactsThatHaveManagerFields.put(student.Id, contactMap?.get(student.Contact__c)?.Manager_s_Email__c);
            }

            if(student.Manager_Email__c != null && student.Campaign_ID__c != null){

                managerCampaignMap.put(student.Manager_Email__c,student.Campaign_ID__c);
            }

            if (student.Contact__c != null){
                studentToContactMap.put(student.Id, contactMap.get(student.Contact__c));
            }
            
        }

        managerMap = new Map<Id, Contact>([SELECT Id, Email FROM Contact WHERE Email in: contactsThatHaveManagerFields.values()]);

      
        for (Contact manager : managerMap.values()){
        
            managerEmailMap.put(manager.Email, manager);

           }

       for (Contact c : studentToContactMap.values()){
           
            c.Manager__c = managerEmailMap.get(c.Manager_s_email__c)?.Id;

            updateContacts.put(c?.Id, c?.Manager__c);

            Student__c student = new Student__c();

            student.Id = contactIdToStudentId.get(c?.Id);
            student.Manager__c = managerEmailMap.get(c.Manager_s_email__c)?.Id;

            if (student.Manager__c != null){
                studentsToUpdate.put(student.Id, student);
                studentsThatNeedManager.remove(student.Id);

                system.debug(studentsThatNeedManager.size());
                
            }
              else{

                studentsToUpdate.put(student.Id, student);
                managers.put(c.Id, contactIdToStudentId.get(c?.Id));
            
              }  

              
       }

       
       for (Contact c : studentToContactMap.values()){

        if (!System.isFuture()){

            Student__c s = new Student__c();

            s.Id = contactIdToStudent.get(c.Id).Id;
   
            studentsToUpdate.get(s.Id).Currently_Inserting_Contact__c = TRUE;

            if (c?.Manager_s_Email__c != null){

                Emails.add(c.Manager_s_Email__c);

            }
            
            
        }

       }
      
       if(!studentsToUpdate.isEmpty()){

        update studentsToUpdate.values();

       }
      
      if ((!studentsThatNeedManager.isEmpty() || !updateContacts.isEmpty()) && !System.isFuture()){

            updateOrCreateContact(updateContacts, managers, Emails);
      }
    }

    @Testvisible
    @future
    private static void updateOrCreateContact(Map<Id, Id> contactToUpdateMap, Map<Id, Id> managersToInsert, Set<String> Emails){

        system.debug(contactToUpdateMap);
        system.debug(managersToInsert);
        system.debug(Emails);

        Map<Id,Contact> contactsToUpdate = new Map<Id,Contact>();
        Map<String, Contact> newManagerEmailToContact = new Map<String, Contact>();
        List<Student__c> updateStudentWithNewManagers = new List<Student__c>();
        Map<Id, Contact> existingManagersMap = new Map<Id, Contact>([SELECT Id, Email FROM Contact WHERE Email in: Emails]);
        Set<String> existingManagers = new Set<String>();
        Map<Id,CampaignMember> insertCampaignMembers = new Map<Id,CampaignMember>();
        Map<Id, Student__c> mapToInsert = new Map<Id, Student__c>();
        List<Contact> contactsToUpdateList = new List<Contact>();

        for (Contact c : existingManagersMap.values()){
            system.debug(c.Email);
            existingManagers.add(c.Email);
        }

        if (!contactToUpdateMap.isEmpty()){

            for (Id conId : contactToUpdateMap.keySet()){

                Contact studentContact = new Contact();

                studentContact.Id = conId;
                studentContact.Manager__c = contactToUpdateMap.get(conId);

                if (contactsToUpdate.get(conId) == null && conId != contactToUpdateMap.get(conId)){

                    contactsToUpdateList.add(studentContact);
                }

            }
    
        }

        if (!managersToInsert.isEmpty()){

            Map<Id, Contact> managerContactMapToInsert = new Map<Id,Contact>([SELECT Id, Manager_s_Email__c, Manager_s_Title__c, Manager_First_Name__c, Manager_Last_Name__c, AccountId FROM Contact WHERE Id in:managersToInsert.keySet() ORDER BY AccountId]);
            Map<String, Contact> insertManagers = new Map<String, Contact>();
            Set<String> createManagers = new Set<String>();
            Map<String, Contact> managersEmailToContact = new Map<String, Contact>();
            Set<Id> lockAccounts = new Set<Id>();

            for (Contact con : managerContactMapToInsert.values()){

                createManagers.add(con?.Manager_s_Email__c);
                managersEmailToContact.put(con?.Manager_s_Email__c, con);

            }

            for (Contact manager : managersEmailToContact.values()){
                lockAccounts.add(manager.AccountId);
            }

            // Try to lock the accounts associated with the Students so UNABLE TO LOCK ROW error is avoided
            Boolean repeat = true;
            Integer count  = 0;

            while (repeat && count < 4){

                try {

                    if (!lockAccounts.isEmpty()){

                        Account [] accts = [SELECT Id FROM Account WHERE Id IN:lockAccounts FOR UPDATE] ;
                        repeat = false;
                    }
                
    
                }
                
                catch (System.QueryException e){
    
                    count++;

                    if(count == 4){

                        throw e;

                    }
                    
                }
            }

            system.debug(createManagers);
            for (String managerEmail : createManagers){

                Contact managerContact = new Contact();

                managerContact.FirstName = managersEmailToContact.get(managerEmail).Manager_First_Name__c;
                managerContact.LastName = managersEmailToContact.get(managerEmail).Manager_Last_Name__c;
                managerContact.Email = managersEmailToContact.get(managerEmail).Manager_s_Email__c;
                managerContact.Title = managersEmailToContact.get(managerEmail).Manager_s_Title__c;
                managerContact.AccountId = managersEmailToContact.get(managerEmail).AccountId;
                managerContact.Contact_Type__c = 'Manager';

                system.debug(existingManagers.contains(managerEmail));

                if (!existingManagers.contains(managerEmail) && insertManagers.get(managerEmail) == null && managerContact.Email != null){
                    insertManagers.put(managerEmail, managerContact);
                }

            }

            if (!insertManagers.isEmpty()){

                insert insertManagers.values();

Map<Id, Contact> newManagerContacts = new Map<Id, Contact>([SELECT Id, Email FROM Contact WHERE Email in:Emails]);

            for (Contact c : newManagerContacts.values()){

                newManagerEmailToContact.put(c.Email, c);
                }
            }

Map<Id, Student__c> updateInsertingBoolean = new Map<Id, Student__c>([SELECT Id, Currently_Inserting_Contact__c, Manager_Email_Reported__c, Campaign_ID__c FROM Student__c WHERE Id in: managersToInsert.values()]);

                Student__c student = new Student__c();

             for (Student__c s : updateInsertingBoolean.values()){

                student.Id = s.Id;
                student.Currently_Inserting_Contact__c = FALSE;

                CampaignMember cm = new CampaignMember();

                cm.ContactId  = newManagerEmailToContact.get(s.Manager_Email_Reported__c)?.Id;
                cm.CampaignId = s.Campaign_ID__c;
                cm.Status     = 'Sent';

                if (insertCampaignMembers.get(cm.ContactId) == null && cm.ContactId != null && cm.CampaignId != null){

                    insertCampaignMembers.put(cm.ContactId, cm);

                }
                
                updateStudentWithNewManagers.add(student);

             }


             updateStudentWithNewManagers.add(student);
             mapToInsert.putAll(updateStudentWithNewManagers);

            for (Contact sc : managerContactMapToInsert.values()){

                sc.Manager__c = newManagerEmailToContact.get(sc.Manager_s_Email__c)?.Id;
                
                if (sc.Manager__c!= null && sc.Id != newManagerEmailToContact.get(sc.Manager_s_Email__c)?.Id){

                    contactsToUpdateList.add(sc);
                }
               
            }

            contactsToUpdate.putAll(contactsToUpdateList);

        }

        if (!contactsToUpdate.isEmpty()){
            update contactsToUpdate.values();
        }

        if (!mapToInsert.isEmpty()){

            update mapToInsert.values();
        }

        if (!insertCampaignMembers.isEmpty()){
            insert insertCampaignMembers.values();
        }
    }

    @Testvisible
    private void checkCampaignMembersExist(){

    Map<Id, CampaignMember> existingCampaignMembers = new Map<Id, CampaignMember>([SELECT Id, ContactId, Email FROM CampaignMember WHERE CampaignId IN:managerCampaignMap.values()]);

  for (CampaignMember cm : existingCampaignMembers.values()){

    contactToCampaignMemberMap.put(cm.ContactId, cm);
      
  }

  for (Id managerId : managerSet){

    if (!contactToCampaignMemberMap.containsKey(managerId)){

        campaignMembersToCreate.put(managerId, managerCampaignMap.get(managerId));

    }
  }

  for (Id managerId : campaignMembersToCreate.keySet()){

    if (!contactToCampaignMemberMap.containsKey(managerId)){

    CampaignMember cm = new CampaignMember();

    cm.ContactId  = managerId;
    cm.Status     = 'Sent';
    cm.CampaignId = campaignMembersToCreate.get(managerId);

    String concatManagerCampaign = String.valueOf(managerId) + String.valueOf(campaignMembersToCreate.get(managerId));

    if (cm.ContactId != null && createCampaignMembers.get(concatManagerCampaign) == null && cm.CampaignId != null){

        createCampaignMembers.put(concatManagerCampaign, cm);

      }
    }
  }

  if (!createCampaignMembers.isEmpty()){

    insert createCampaignMembers.values();
  }

}

    /**
    * This method updates the campaign member status and their related manager as well if one is set. 
    * It checks to see if the status has changed on the student and if it has does it match an 
    * inactive status or an active status? It then takes and matches students and managers with contacts to then find
    * the correlating campaign members to update the status.
    */

    @TestVisible
    private void updateCampaignMembersStatus(){
        system.debug(campaignSet);

  
        Map<Id, Student__c> studentStatusMap = new Map<Id, Student__c>([SELECT Id, Campaign_Id__c, Status__c, Manager__c FROM Student__c WHERE Campaign_Id__c IN:campaignSet]);

        for (Student__c student : studentStatusMap.values()){

            if (ACTIVE_STUDENT_STATUS_VALUES.contains(student?.Status__c) && student?.Status__c != null){

                system.debug(student?.Manager__c);
                system.debug(student?.Status__c);

                dontUpdateManagers.add(student?.Manager__c);

            }

        }
  

        system.debug(managerReEnrolled);
        system.debug(managerContactsIds);

        if(!managerReEnrolled.isEmpty() && !managerContactsIds.isEmpty()){
            campaignMembersToUpdate = new List<CampaignMember>([SELECT Id, Status, ContactId, CampaignId FROM CampaignMember WHERE (ContactId in: managerContactsIds OR ContactId IN: managerReEnrolled) AND CampaignId in:campaignStudentMap.keySet()]);
        }
        else if(managerReEnrolled.isEmpty() && !managerContactsIds.isEmpty()){
            campaignMembersToUpdate = new List<CampaignMember>([SELECT Id, Status, ContactId, CampaignId FROM CampaignMember WHERE ContactId in: managerContactsIds AND CampaignId IN:campaignStudentMap.keySet()]);
        }
        else if(!managerReEnrolled.isEmpty() && managerContactsIds.isEmpty()){
            campaignMembersToUpdate = new List<CampaignMember>([SELECT Id, Status, ContactId, CampaignId FROM CampaignMember WHERE ContactId in: managerReEnrolled AND CampaignId IN:campaignStudentMap.keySet()]);
        }

        if (!managerContactsIds.isEmpty() || !managerReEnrolled.isEmpty()){
          
           List<CampaignMemberStatus> cmsList      = new List<CampaignMemberStatus>([SELECT Id, Label, CampaignId, SortOrder FROM CampaignMemberStatus WHERE CampaignId IN:campaignStudentMap.keySet()]);
           List<Integer>              countList    = new List<Integer>();
           Set<String>                statusValues = new Set<String>();
           Integer count;
        
           for (CampaignMemberStatus c : cmsList){
            campaignMemberStatusMap.put(c?.CampaignId, c?.Label);
            countList.add(c?.SortOrder);
            statusValues.add(c.Label);
           }

           countList.sort();

           if (Test.isRunningTest()){
               count = 2;
           }
           else{
            count = countList.get(countList.size() -1);
           }
            

           if(!campaignMembersToUpdate.isEmpty()){

            
            Map<Id, CampaignMemberStatus> CMStoInsert = new Map<Id, CampaignMemberStatus>();
/*
            for (CampaignMember cm : campaignMembersToUpdate){
                
                    if(!campaignMemberStatusMap.containsKey(cm?.CampaignId) || !statusValues.contains('Not Participating')){

                        CampaignMemberStatus newStatus = new CampaignMemberStatus(
                        CampaignID=cm?.CampaignId,
                        Label='Not Participating',
                        IsDefault=false,
                        HasResponded=false,
                        SortOrder=count + 1
                        );

                        CMStoInsert.put(newStatus?.CampaignID, newStatus);
                    }

            }
           if (!CMStoInsert.isEmpty()){

            insert CMStoInsert.values();

          } */

            for (CampaignMember member : campaignMembersToUpdate){
                if(managerReEnrolled.contains(member.ContactId)){
                    member.Status = 'Sent';
                }
                
                else if (!dontUpdateManagers.contains(member.ContactId)){
                    
                    member.Status = 'Not Participating';}
            }

            if(!campaignMembersToUpdate.isEmpty()){

                update campaignMembersToUpdate; 
            }
                     
           }
         } 
    }

    @TestVisible
    private void insertStudentRegTagsIfNew() {
        List<Tag__c> tagsToUpsert = new List<Tag__c>();
        List<Tag__c> existingTags = [SELECT Id, Name, Name_External_Id__c FROM Tag__c WHERE Name_External_Id__c IN :allTriggerStudentRegTagStringSet];
        for(Tag__c tag : existingTags) {
            tagNameToTagMap.put(tag.Name_External_Id__c, tag);
        }
        for (String tagName : allTriggerStudentRegTagStringSet) {
            // if tag does not exist yet, create it and add to map
            if(tagNameToTagMap.get(tagName) == null) {
                Tag__c newTag = new Tag__c(Name = tagName, Name_External_Id__c = tagName);
                tagsToUpsert.add(newTag);
                tagNameToTagMap.put(tagName, newTag);
            }
        }
        if(tagsToUpsert.size() > 0) {
            // upsert for edge case where a new tag is being loaded and prevent creating the new one twice
            // may cause unable_to_lock_row exception, this is expected due to not syncing bulk
            upsert tagsToUpsert Name_External_Id__c;
        }
    }

    public void handleStudentRegistrationTag(Map<Id, Student__c> newMap, Map<Id, Student__c> oldMap) {
        Map<Id, Map<String, Student_Tag__c>> studentIdToTagNameToStudentTagRecord = getStudentIdToTagNameToStudentTagRecord(newMap.keySet());
        
        List<Student_Tag__c> studentTagsToInsert = new List<Student_Tag__c>();
        List<Student_Tag__c> studentTagsToDelete = new List<Student_Tag__c>();
        for(Student__c s : newMap.values()) {
            Student__c oldStudent = oldMap.get(s.Id);
            Set<String> newTagNames = s.Registration_Tags__c == null ? new Set<String>() : new Set<String>(s.Registration_Tags__c.split(';'));
            Set<String> oldTagNames = oldStudent == null || oldStudent.Registration_Tags__c == null ? new Set<String>() : new Set<String>(oldStudent.Registration_Tags__c.split(';'));
            
            studentTagsToInsert.addAll(getStudentTagsToInsert(s.Id, newTagNames, oldTagNames));
            studentTagsToDelete.addAll(getStudentTagsToDelete(studentIdToTagNameToStudentTagRecord.get(s.Id), newTagNames, oldTagNames));
        }

        if(studentTagsToInsert.size() > 0) {
            insert studentTagsToInsert;
        }
        if(studentTagsToDelete.size() > 0) {
            delete studentTagsToDelete;
        }
    }

    private Map<Id, Map<String, Student_Tag__c>> getStudentIdToTagNameToStudentTagRecord(Set<Id> studentIds) {
        Map<Id, Map<String, Student_Tag__c>> studentIdToTagNameToStudentTagRecord = new Map<Id, Map<String, Student_Tag__c>>();
        List<Student_Tag__c> studentTagList = [SELECT Id, Student__c, Tag__c, Tag__r.Name FROM Student_Tag__c WHERE Student__c IN :studentIds];
        for (Student_Tag__c studentTag : studentTagList) {
            if(studentIdToTagNameToStudentTagRecord.get(studentTag.Student__c) == null) {
                studentIdToTagNameToStudentTagRecord.put(studentTag.Student__c, new Map<String, Student_Tag__c>());
            }
            studentIdToTagNameToStudentTagRecord.get(studentTag.Student__c).put(studentTag.Tag__r.Name, studentTag);
        }
        return studentIdToTagNameToStudentTagRecord;
    }

    private List<Student_Tag__c> getStudentTagsToInsert(Id studentId, Set<String> newTagNames, Set<String> oldTagNames) {
        List<Student_Tag__c> studentTagsToInsert = new List<Student_Tag__c>();
        for(String newTag : newTagNames) {
            Boolean isPreviousValue = oldTagNames.remove(newTag);
            if(!isPreviousValue) { 
                studentTagsToInsert.add(new Student_Tag__c(Student__c = studentId, Tag__r = new Tag__c(Name_External_Id__c = newTag)));
            }
        }
        return studentTagsToInsert;
    }

    private List<Student_Tag__c> getStudentTagsToDelete(Map<String, Student_Tag__c> tagNameToTagMap, Set<String> newTagNames, Set<String> oldTagNames) {

        List<Student_Tag__c> studentTagsToDelete = new List<Student_Tag__c>();
        for(String oldTag : oldTagNames) {
            if (tagNameToTagMap != null){
                Student_Tag__c removedTag = tagNameToTagMap.remove(oldTag);
                if(removedTag != null) {
                    studentTagsToDelete.add(removedTag);
                }
            }
        }
        return studentTagsToDelete;
    }

    private Boolean triggerIsInsertUpdateOrUndelete() {
        return Trigger.isInsert || Trigger.isUpdate || Trigger.isUndelete;
    }

    private void handleStudentImports(List<Student__c> newStudents, Map<Id, Student__c> oldMap) {
        Set<Id> studentIdsBeingImported = new Set<Id>();
        for(Student__c student : newStudents) {
            if(studentIsNewImport(student, oldMap.get(student.Id))) {
                studentIdsBeingImported.add(student.Id);
            }
        }
        if(studentIdsBeingImported.size() > 0) {
            EpcCalcMarkedAccounts_SchBatch.rescheduleRecalcJob();
            updateAccountsAsLoadingStudents(studentIdsBeingImported);
        }
    }

    private Boolean studentIsNewImport(Student__c student, Student__c oldStudent) {
        return student.Import_Uuid__c != null && (oldStudent == null || student.Import_Uuid__c != oldStudent.Import_Uuid__c);
    }

    public void updateAccountsAsLoadingStudents(Set<Id> studentIdsBeingImported) {
        Map<Id, Account> accountMapToUpdate = new Map<Id, Account>();
        List<Student__c> students = [SELECT Id, Contact__r.AccountId FROM Student__c WHERE Id IN :studentIdsBeingImported AND Contact__r.Account.EPC_Autocalculation_Enabled__c = true AND Contact__r.Account.Is_Loading_Students__c = false];
        for(Student__c student : students) {
            accountMapToUpdate.put(student.Contact__r.AccountId, new Account(Id = student.Contact__r.AccountId, Is_Loading_Students__c = true));
        }
        if(accountMapToUpdate.size() > 0) {
            update accountMapToUpdate.values();
        }
    }

    public static void sendErrorMail(String errorMessage){              
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'mcribb@execonline.com', 'sjennings@execonline.com'};
        mail.setToAddresses(toAddresses);
        mail.setSenderDisplayName('Current Student Error Message');
        mail.setSubject('Error from Org : ' + UserInfo.getOrganizationName());
        mail.setPlainTextBody(errorMessage);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
   }
}