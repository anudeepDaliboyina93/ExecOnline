public with sharing class ManageEPCController {

    @AuraEnabled(cacheable=true)
    public static Boolean canEdit(Id accountId){
 
            Id     userId      = UserInfo.getUserId();
            Id     profileId   = userinfo.getProfileId();
            Account currentAccount;
            String profileName =[SELECT Id,Name FROM Profile WHERE Id=:profileId].Name;
            Boolean EPCManager = FeatureManagement.checkPermission('EPCManager');

            if (accountId == null){

                return profileName == 'System Administrator' || EPCManager ? true : false;
            }

            else {

                currentAccount = [SELECT Id, Enterprise_Program_Manager__c, Client_Success_Manager__c FROM Account WHERE Id=:accountId LIMIT 1];

                Boolean canEdit = (userId == currentAccount.Enterprise_Program_Manager__c || userId == currentAccount.Client_Success_Manager__c);

                return profileName == 'System Administrator' || EPCManager ? true : canEdit;

            }

           
    
    }

    @AuraEnabled
    public static void approveRecords(List<Id> studentIds){
 
            List<Student__c> studentsToUpdate = new List<Student__c>();
            List<Student__c> studentsToApprove = [SELECT Id, Approved__c FROM Student__c WHERE Id IN:studentIds];

            for (Student__c student : studentsToApprove){
                student.Approved__c = true;

                studentsToUpdate.add(student);
            }

            if (!studentsToUpdate.isEmpty()){
                update studentsToUpdate;
            }
            
    }

    @AuraEnabled
    public static void saveStudent(String jsonStringToParse){

        saveStudentWrapper saveWrapper = (saveStudentWrapper)JSON.deserialize(jsonStringToParse, saveStudentWrapper.class);
        List<EPC_Utilization_Item__c> epcuiToUpdate = new List<EPC_Utilization_Item__c>();
        Set<Id> setTempFalse = new Set<Id>();

        Student__c student = [SELECT Id, Temp__c, EPCs_Comped__c, EPCs_Comped_Reason__c, Comped_Reason_Category__c, Contact__r.AccountId, Override_EPCU__c, Program__r.Program_Family__r.Primary_Service__r.List_Weighting__c, Override_Opportunity__c FROM Student__c WHERE Id=:saveWrapper.studentId LIMIT 1];
     

            if (Boolean.valueOf(saveWrapper.overrideBoolean) == true){

                student.Override_Opportunity__c = saveWrapper.oppId;
                student.Override_EPCU__c        = true;
            }
        

            student.EPCs_Comped__c = student.Program__r?.Program_Family__r?.Primary_Service__r?.List_Weighting__c.setScale(3) - saveWrapper?.studentEPC.setScale(3);
            student.Temp__c = true;

            setTempFalse.add(student.Id);
        
        student.EPCs_Comped_Reason__c = saveWrapper.notes;
        student.Comped_Reason_Category__c = saveWrapper.compCategory;

        update student;

        Map<Id, EPC_Utilization_Item__c> epcui = new Map<Id,EPC_Utilization_Item__c>([SELECT Id, EPCs_Comped__c, EPCs_Discounted__c, Service__r.List_Weighting__c FROM EPC_Utilization_Item__c WHERE Student__c=:saveWrapper.studentId]);

        for (Integer i = 0; i < saveWrapper.tags.size(); i++){

            EPC_Utilization_Item__c epcuItem = epcui.get(saveWrapper.tags[i].Id);
            Decimal tagEPC = Decimal.valueOf(saveWrapper.tags[i].tagEpc);
            Decimal startingEPC = Decimal.valueOf(saveWrapper.tags[i].tagStartingEpc);
            String tagNotes = saveWrapper.tags[i].tagNotes;
            String compedReason = saveWrapper.tags[i].compedCategory;

                epcuItem.EPCs_Comped__c = startingEPC - tagEPC;
                epcuItem.Comped_Reason_Category__c = compedReason;
                epcuItem.Notes__c = tagNotes;

                epcuiToUpdate.add(epcuItem);
            
        }

        if (!epcuiToUpdate.isEmpty()){
            update epcuiToUpdate;
        }


    if (!setTempFalse.isEmpty()){

        List<Student__c> studentsToSetFalse = [SELECT Id, Temp__c FROM Student__c WHERE Id IN:setTempFalse];

        for (Student__c s : studentsToSetFalse){
            s.Temp__c = false;
        }

        update studentsToSetFalse;
    }

    Set<Id> acctIds = new Set<Id>();
    
        Map<Id, Student__c> studentsToUpdateMap = new Map<Id, Student__c>();
       // List<EPC_Utilization__c> epcs = [SELECT Id, Opportunity__c, Student__c, Name, EPC_Utilization_Item__r.Student__c, Provisioned_EPCU__c FROM EPC_Utilization__c WHERE Student__c =:student.Id OR EPC_Utilization_Item__r.Student__c =:student.Id];
        EPC_Utilization__c provisionedEPC = [ SELECT Id, Account__c, Name, Type__c, Adjustment_Date__c, Opportunity__c, Opportunity__r.CloseDate
                                                FROM EPC_Utilization__c 
                                                WHERE Opportunity__c =:saveWrapper.oppId AND 
                                                (Type__c='Provisioned' AND EPCs_Utilized__c!=0 AND EPCs_Utilized__c!=null)
                                                ORDER BY Type__c ASC, Opportunity__r.CloseDate ASC LIMIT 1];

            
            acctIds.add(student.Contact__r.AccountId);
           
            LiveEpcService epcService = new LiveEpcService();
            epcService.LiveEpcService(acctIds, student.Id, saveWrapper.oppId, provisionedEPC.Id);

    
           
            
    }

    @AuraEnabled(cacheable=true)
    public static List<StudentWrapper> studentsTree(String jsonStringToParse) {

        studentWire incomingWire = (studentWire)JSON.deserialize(jsonStringToParse, studentWire.class);
        
        Id acctId;
        Set<Id> acctIds = new Set<Id>();

        system.debug(incomingWire.approval);

        if (incomingWire.accountId != null){

            acctId = incomingWire.accountId;
            acctIds.add(acctId);
        }

        system.debug(acctIds.size());
        Date epcUtlizationStart = incomingWire.startDate != null ? incomingWire.startDate : null;
        Date epcUtilizationEnd  = incomingWire.endDate != null ? incomingWire.endDate : null;   

        Map<Id, List<EpcuWrapper>> studentIdToEpcuWrappers = new Map<Id, List<EpcuWrapper>>();
        List<EPC_Utilization__c>   studentEpcs             = new List<EPC_Utilization__c>();
        List<Student__c>           studentAccountsToAdd    = new List<Student__c>();

        if (acctId == null){
            String condition;

            if (incomingWire.startDate != null){

                condition = 'EPC_Utilization_Date__c >=:epcUtlizationStart AND EPC_Utilization_Date__c <=:epcUtilizationEnd AND Approved__c = true';
            }

            else {

                condition = 'EPC_Utilization_Date__c = LAST_N_DAYS:30 AND Approved__c = true';
            }

            String sobj = 'Student__c';
            String cols = 'Id, Contact__r.AccountId, Approved__c';
            String query = 'SELECT '+cols+' FROM '+sobj+' WHERE '+condition;
            studentAccountsToAdd = Database.query(query);

            for (Student__c student : studentAccountsToAdd){
                acctIds.add(student.Contact__r.AccountId);
            }

        }

        ManageEPCController epcController = new ManageEPCController();


            String condition = getCondition(Boolean.valueOf(incomingWire.approval), incomingWire.startDate, acctId);
            studentIdToEpcuWrappers =  epcController.getActualEpcuWrappers(acctIds, Boolean.valueOf(incomingWire.approval));

            String sobj = 'EPC_Utilization__c';
            String cols = 'Id, Student__c, Student__r.Override_EPCU__c, Student__r.EPCs_Comped__c, Student__r.EPCs_Comped_Reason__c,';
                   cols += 'Opportunity__r.Price_Per_EPC_rollup__c, Student__r.Comped_Reason_Category__c, Provisioned_EPCU__c, Opportunity__r.Name,';
                   cols += 'EPCs_Utilized__c, Student__r.EPCs_Utilized__c, Student__r.Student_Name__c, Student__r.Program__r.Program_Family__r.Name,';
                   cols += 'Program__r.Program_Family__r.Primary_Service__r.List_Weighting__c, Student__r.Approved__c, Student__r.Approved_By__r.Name,';
                   cols += 'Student__r.Approval_Date_Time__c, EPC_Utilization_Date__c, Account__c, Account__r.Name, Student__r.Status__c, Student__r.Program__r.Program_Family__c,';
                   cols += 'EPC_Utilization_Item__r.Student__c, EPC_Utilization_Item__r.Student__r.Override_EPCU__c, EPC_Utilization_Item__r.Student__r.EPCs_Utilized__c, EPC_Utilization_Item__r.Student__r.Student_Name__c,';
                   cols += 'EPC_Utilization_Item__r.Student__r.Program__r.Program_Family__r.Name , Program__r.Program_Family__r.Name, Program__r.Program_Family__r.Friendly_Name__c, EPC_Utilization_Item__r.Student__r.Approved__c, EPC_Utilization_Item__r.Student__r.Approved_By__r.Name,';
                   cols += 'EPC_Utilization_Item__r.Student__r.Approval_Date_Time__c, EPC_Utilization_Item__r.Student__r.Status__c, EPC_Utilization_Item__r.Student__r.Program__r.Program_Family__c,';
                   cols += 'EPC_Utilization_Item__r.Student__r.Program__r.Program_Family__r.tagOnly__c, EPC_Utilization_Item__r.Student__r.Comped_Reason_Category__c, EPC_Utilization_Item__r.Student__r.EPCs_Comped_Reason__c, EPC_Utilization_Item__r.Student__r.EPCs_Comped__c';
            String query = 'SELECT '+cols+' FROM '+sobj+' WHERE '+condition;
             studentEpcs = Database.query(query);

        Map<Id,StudentWrapper> studentsW = new Map<Id, StudentWrapper>();
        for (EPC_Utilization__c epc : studentEpcs){

            if (epc?.EPC_Utilization_Item__r?.Student__r?.Program__r?.Program_Family__r?.tagOnly__c == true){

                Decimal epcAfterComp = epc.EPC_Utilization_Item__r.Student__r.EPCs_Comped__c != null ? epc.Program__r.Program_Family__r.Primary_Service__r.List_Weighting__c - epc.EPC_Utilization_Item__r.Student__r.EPCs_Comped__c : epc.Program__r.Program_Family__r.Primary_Service__r.List_Weighting__c;

                StudentWrapper sw  = new StudentWrapper();
                sw.AccountId       = epc.Account__c;
                sw.AccountName     = epc.Account__r.Name;
                sw.StudentId       = epc.EPC_Utilization_Item__r.Student__c;
                sw.name            = epc.EPC_Utilization_Item__r.Student__r.Student_Name__c;
                sw.Service         = epc.EPC_Utilization_Item__r.Student__r.Program__r.Program_Family__r.Name;
                sw.OppId           = epc.Opportunity__c;
                sw.oppName         = epc.Opportunity__r.Name;
                sw.epcuis          = new List<epcui>();
                sw.Approved        = epc.EPC_Utilization_Item__r.Student__r.Approved__c;
                sw.ApprovedBy      = epc.EPC_Utilization_Item__r.Student__r.Approved_By__r.Name;
                sw.ApprovalDate    = epc.EPC_Utilization_Item__r.Student__r.Approval_Date_Time__c;
                sw.UtilizationDate = epc.EPC_Utilization_Date__c;
                sw.price           = epc.Opportunity__r.Price_Per_EPC_rollup__c;
                sw.notes           = epc.EPC_Utilization_Item__r.Student__r.EPCs_Comped_Reason__c;
                sw.compedCategory  = epc.EPC_Utilization_Item__r.Student__r.Comped_Reason_Category__c;
                sw.isOverride      = epc.EPC_Utilization_Item__r.Student__r.Override_EPCU__c;
                sw.StudentStatus   = epc.EPC_Utilization_Item__r.Student__r.Status__c;
                sw.serviceId       = epc.EPC_Utilization_Item__r.Student__r.Program__r.Program_Family__c;
                sw.isAEP           = epc.Program__r.Program_Family__r.Name.contains('AEP') ||  epc.Program__r.Program_Family__r.Friendly_Name__c.contains('AEP')? true : false;
                sw.isComped        = epc.EPC_Utilization_Item__r.Student__r.EPCs_Comped__c != null &&  epc.Student__r.EPCs_Comped__c != 0 ? true : false;
                sw.tagOnly         = true;
                if (!sw.isAEP){
                    studentSW.put(epc.EPC_Utilization_Item__r.Student__c, sw);
                }
                

            }

            else {

                Decimal epcAfterComp = epc.Student__r.EPCs_Comped__c != null ? epc.Program__r.Program_Family__r.Primary_Service__r.List_Weighting__c - epc.Student__r.EPCs_Comped__c : epc.Program__r.Program_Family__r.Primary_Service__r.List_Weighting__c;

                StudentWrapper sw  = new StudentWrapper();
                sw.AccountId       = epc.Account__c;
                sw.AccountName     = epc.Account__r.Name;
                sw.StudentId       = epc.Student__c;
                sw.name            = epc.Student__r.Student_Name__c;
                sw.Service         = epc.Student__r.Program__r.Program_Family__r.Name;
                sw.OppId           = epc.Opportunity__c;
                sw.oppName         = epc.Opportunity__r.Name;
                sw.epcuis          = new List<epcui>();
                sw.Approved        = epc.Student__r.Approved__c;
                sw.ApprovedBy      = epc.Student__r.Approved_By__r.Name;
                sw.ApprovalDate    = epc.Student__r.Approval_Date_Time__c;
                sw.UtilizationDate = epc.EPC_Utilization_Date__c;
                sw.EPC             = epcAfterComp;
                sw.price           = epc.Opportunity__r.Price_Per_EPC_rollup__c;
                sw.notes           = epc.Student__r.EPCs_Comped_Reason__c;
                sw.compedCategory  = epc.Student__r.Comped_Reason_Category__c;
                sw.isOverride      = epc.Student__r.Override_EPCU__c;
                sw.StudentStatus   = epc.Student__r.Status__c;
                sw.serviceId       = epc.Student__r.Program__r.Program_Family__c;
                sw.isAEP           = epc.Program__r.Program_Family__r.Name.contains('AEP') ||  epc.Program__r.Program_Family__r.Friendly_Name__c.contains('AEP') ? true : false;
                sw.isComped        = epc.Student__r.EPCs_Comped__c != null &&  epc.Student__r.EPCs_Comped__c != 0 ? true : false;
                sw.tagOnly         = false;
                if (!sw.isAEP){
                    studentSW.put(epc.Student__c, sw);
                }
                

            }
          
            
        }

        for (Id studentId : studentSW.keySet()){

            StudentWrapper sw = studentsW.get(studentId);
         
            sw.totalEPC = 0;
            sw.cost     = 0;
            sw.tagTotalEPC = 0;

            if (sw.tagOnly){
                sw.EPC = 0;
            }
           
            for (EpcuWrapper ew : studentIdToEpcuWrappers.get(studentId)){

                epcui newEpcui = new epcui();

                newEpcui.tagId           = ew.tagId;
                newEpcui.Tag             = ew.tag;
                newEpcui.StudentId       = ew.StudentId;
                newEpcui.Service         = ew.Service;
                newEpcui.oppName         = ew.OppName;
                newEpcui.EPC             = ew.EpcUtilized;
                newEpcui.Approved        = ew.isApproved;
                newEpcui.UtilizationDate = ew.EpcUtilizationDate;
                newEpcui.cost            = ew.cost;
                newEpcui.price           = ew.price;
              
                sw.epcuis.add(newEpcui);
                sw.tagTotalEPC = ew.tag == true ? sw.tagTotalEPC + ew.EpcUtilized : sw.tagTotalEPC;
                sw.totalEPC = sw.totalEPC.setScale(3) + ew.EpcUtilized.setScale(3);
                sw.cost = ew.cost != null ? sw.cost + ew.cost : sw.cost;
                if (!sw.isAEP){
                    studentsW.put(studentId, sw);
                }
               
            }

        }

        return studentsW.values();
    }

    public Map<Id, List<EpcuWrapper>> getActualEpcuWrappers(Set<Id> accountIds, Boolean approval) {
        Map<Id, List<EpcuWrapper>> studentIdToEpcuWrappers = new Map<Id, List<EpcuWrapper>>();
        List<EpcuWrapper> epcuWrappers = new List<EpcuWrapper>();
        epcuWrappers.addAll(getEpcuWrappers(accountIds, approval));
        for(EpcuWrapper epcuw : epcuWrappers) {
            if(studentIdToEpcuWrappers.get(epcuw.StudentId) == null && epcuw.StudentId != null) {
                studentIdToEpcuWrappers.put(epcuw.StudentId, new List<EpcuWrapper>()); 
            }
            else if (studentIdToEpcuWrappers.get(epcuw.StudentId) == null && epcuw.StudentId == null){
                studentIdToEpcuWrappers.put(epcuw.EpcuiStudentId, new List<EpcuWrapper>()); 
            }
            studentIdToEpcuWrappers.get(epcuw.StudentId).add(epcuw);
        }
        for(List<EpcuWrapper> epcuList : studentIdToEpcuWrappers.values()) {
            // Sort the EPCU Wrappers by Utilization date/Adjustment date
            epcuList.sort();
        }
        return studentIdToEpcuWrappers;
    }

    private static string getCondition(Boolean approval, Date startDate, String acctId){

        String condition;

        if (acctId == null){

            if (startDate != null){

                condition = 'Account__c IN:acctIds AND Student__c != null AND Student__r.Approved__c = true AND (EPC_Utilization_Date__c >=:epcUtlizationStart AND EPC_Utilization_Date__c <=:epcUtilizationEnd) ORDER BY EPC_Utilization_Date__c';

            }
            else {
                condition = 'Account__c IN:acctIds AND Student__c != null AND Student__r.Approved__c = true AND  EPC_Utilization_Date__c = LAST_MONTH ORDER BY EPC_Utilization_Date__c';

            }

        }

        else {
           
            if (approval == false ){

                if (startDate != null){

                    condition = 'Account__c IN:acctIds AND ((Student__c != null AND Student__r.Approved__c = false) OR (EPC_Utilization_Item__r.Student__c != null AND EPC_Utilization_Item__r.Student__r.Approved__c = false AND EPC_Utilization_Item__r.Student__r.Program__r.Program_Family__r.tagOnly__c = true)) AND (EPC_Utilization_Date__c >=:epcUtlizationStart AND EPC_Utilization_Date__c <=:epcUtilizationEnd) ORDER BY EPC_Utilization_Date__c';

                }
                else {
                    condition = 'Account__c IN:acctIds AND ((Student__c != null AND Student__r.Approved__c = false) OR (EPC_Utilization_Item__r.Student__c != null AND EPC_Utilization_Item__r.Student__r.Approved__c = false AND EPC_Utilization_Item__r.Student__r.Program__r.Program_Family__r.tagOnly__c = true)) ORDER BY EPC_Utilization_Date__c';

                }

            }

            else {

                if (startDate != null){

                    condition = 'Account__c IN:acctIds AND ((Student__c != null AND Student__r.Approved__c = true) OR (EPC_Utilization_Item__r.Student__c != null AND EPC_Utilization_Item__r.Student__r.Approved__c = true AND EPC_Utilization_Item__r.Student__r.Program__r.Program_Family__r.tagOnly__c = true)) AND (EPC_Utilization_Date__c >=:epcUtlizationStart AND EPC_Utilization_Date__c <=:epcUtilizationEnd) ORDER BY EPC_Utilization_Date__c';

                }
                else {
                    condition = 'Account__c IN:acctIds AND ((Student__c != null AND Student__r.Approved__c = true) OR (EPC_Utilization_Item__r.Student__c != null AND EPC_Utilization_Item__r.Student__r.Approved__c = true AND EPC_Utilization_Item__r.Student__r.Program__r.Program_Family__r.tagOnly__c = true)) AND EPC_Utilization_Date__c = LAST_N_DAYS:30 ORDER BY EPC_Utilization_Date__c';

                }
            }
        }

        return condition;
    }

    private List<EpcuWrapper> getEpcuWrappers(Set<Id> accountIds, Boolean approval) {
        List<EPC_Utilization__c> Epcus = [
            SELECT Id,  Account__c, EPCs_Utilized__c, Approved__c, Program__r.Program_Family__r.Name, Program__r.Program_Family__r.Primary_Service__c, Student__r.Approved__c, EPC_Utilization_Item__r.Student__r.Approved__c, Student__c, Student__r.Student_Name__c, Opportunity__c, Opportunity__r.Name, EPC_Utilization_Date__c, EPC_Utilization_Item__c, EPC_Utilization_Item__r.Student__c,EPC_Utilization_Item__r.Student__r.Student_Name__c, Service__c, Opportunity__r.Price_Per_EPC_rollup__c
            FROM EPC_Utilization__c 
            WHERE Account__c IN :accountIds AND Type__c IN ('Actual') AND (Student__r.Approved__c =:approval OR  EPC_Utilization_Item__r.Student__r.Approved__c =:approval)
            ORDER BY Account__c
        ];
        
        List<EpcuWrapper> epcuWrappers = new List<EpcuWrapper>();
        for(EPC_Utilization__c epcu : Epcus) {
           

                epcuWrappers.add(new EpcuWrapper(epcu));
            system.debug(epcu.Program__r.Program_Family__r.Name );
            
            
        }
        return epcuWrappers;
    }

    @AuraEnabled(cacheable=true)
    public static List<EPC_Utilization__c> approvedStudents(Id accountId) {

        system.debug(accountId);

        return [SELECT Id, Student__c, EPC_Utilization_Date__c, Opportunity__r.Name, Student__r.Student_Name__c , Student__r.Approved__c, Student__r.Approval_Date_Time__c, Student__r.Approved_By__r.Name, EPCs_Utilized__c, Account__c, Program__r.Program_Family__r.Name FROM EPC_Utilization__c WHERE Account__c =:accountId AND Approved__c = true AND Student__c != null];
    }

    @AuraEnabled(cacheable=false)
    public static List<OppWrapper> getOpps(Id accountId){

        system.debug(accountId);
      
        List<OppWrapper> owList = new List<OppWrapper>();
        Set<Id> acctIdSet = new Set<Id>();
        Map<String, Decimal> provMap = new Map<String, Decimal>();
        Map<String, Decimal> sendToOppWrapper = new Map<String, Decimal>();
        acctIdSet.add(accountId);

        List<EPC_Utilization__c> provisionedEPCs = [SELECT Id, Account__c, Name, Type__c, Adjustment_Date__c, Opportunity__c, Opportunity__r.CloseDate, Opportunity__r.Name, EPCs_Utilized__c, Service_Category__c, Opportunity__r.AEP_Booking_rollup__c 
        FROM EPC_Utilization__c 
        WHERE Account__c = :accountId AND 
            ((Type__c='Provisioned' AND EPCs_Utilized__c!=0 AND EPCs_Utilized__c!=null) OR (Type__c='Provisioned' AND Opportunity__r.AEP_Booking_rollup__c > 0))
        ORDER BY Type__c ASC, Opportunity__r.CloseDate ASC];

        ManageEPCController epcController = new ManageEPCController();
        Map<String, Decimal> oppsWithApprovalsOverrides = epcController.getApprovedOrOverrideCount(accountId);

        for (EPC_Utilization__c provEPC : provisionedEPCs){

            provMap.put(provEPC.Opportunity__c + provEPC.Opportunity__r.Name, provEPC.EPCs_Utilized__c.setScale(2));
        }

        for (String oppId : oppsWithApprovalsOverrides.keySet()){
            
            if (provMap.get(oppId) != null){
               
                provMap.put(oppId, provMap.get(oppId) - oppsWithApprovalsOverrides.get(oppId).setScale(2));
        
            }
        }

        for (String oppName : provMap.keySet()){

            String OpportunityName = oppName.substring(18);

            OppWrapper OW = new OppWrapper();

                OW.OppId   = oppName.substring(0, 18);
                OW.OppName = OpportunityName;
                OW.EPCLeft = provMap.get(oppName);

                owList.add(OW);
        }

        system.debug(owList);
        return owList;

    }

    private class EpcuWrapper implements Comparable {
        Student__c Student;
        EPC_Utilization_Item__c Epcui;
        EPC_Utilization__c Epcu;

        Id StudentId;
        Id EpcuiStudentId;
        Id EpcuId;

        Id AccountId;
        Id ServiceId;
        Date EpcUtilizationDate;
        Decimal EpcUtilized;
        String Service;
        String Name;
        Decimal EpcsComped = 0;
        Decimal cost = 0 ;
        Decimal price = 0;
    
        Boolean isApproved = false;
        Boolean isOverride = false;
        Boolean isAEP      = false;
        
        String OppName;
        Boolean tag;
        Id tagId;

        public EpcuWrapper(EPC_Utilization__c epcu) {
            this.Epcu = epcu;
            this.EpcuId = epcu.Id;
            this.AccountId = epcu.Account__c;
            this.ServiceId = epcu.Program__r.Program_Family__r.Primary_Service__c;
            this.EpcUtilizationDate = epcu.EPC_Utilization_Date__c;
            this.EpcUtilized = epcu.EPCs_Utilized__c != null ? epcu.EPCs_Utilized__c : 0 ;
            this.OppName = epcu.Opportunity__r.Name;
            this.isAEP = epcu.Program__r.Program_Family__r.Name.contains('AEP') ? true : false;

            if (this.EpcsComped > 0){
                this.EpcUtilized = this.EpcUtilized - this.EpcsComped;
            }

            this.price = epcu.Opportunity__r.Price_Per_EPC_rollup__c != null ? epcu.Opportunity__r.Price_Per_EPC_rollup__c : this.price;
            this.cost = epcu.Opportunity__r.Price_Per_EPC_rollup__c != null ? epcu.Opportunity__r.Price_Per_EPC_rollup__c * this.EpcUtilized : null;
            
            if (epcu.Student__c != null){
                this.StudentId = epcu.Student__c;
                this.Name      = epcu.Student__r.Student_Name__c;
                this.Service   = epcu.Program__r.Program_Family__r.Name;
                this.tag       = false;
    
            }

            else {
                this.StudentId      = epcu.EPC_Utilization_Item__r.Student__c;
                this.EpcuiStudentId = epcu.EPC_Utilization_Item__r.Student__c;
                this.Service        = epcu.Service__c;
                this.Name           = epcu.EPC_Utilization_Item__r.Student__r.Student_Name__c;
                this.tag            = true;
                this.tagId          = epcu.EPC_Utilization_Item__c;
            }
            
           
        }

        public Integer compareTo(Object obj){
            EpcuWrapper epcuw = (EpcuWrapper)obj;
            if (this.epcUtilizationDate > epcuw.epcUtilizationDate) {
                return 1;
            }
            return -1;
        }
    }

    public Map<String, Decimal> getApprovedOrOverrideCount(Id accountId){

        List<EPC_Utilization__c> approvedOrOverrideUtilization = [SELECT Id, Student__r.Override_EPCU__c, EPC_Utilization_Item__r.Student__r.Override_EPCU__c,
                                                                        Student__r.Approved__c, EPC_Utilization_Item__r.Student__r.Approved__c, Provisioned_EPCU__c,
                                                                        EPCs_Utilized__c, Opportunity__c, Opportunity__r.Name
                                                                        FROM EPC_Utilization__c 
                                                                        WHERE Account__c =: accountId
                                                                        AND ((Type__c!='Provisioned' AND EPCs_Utilized__c!=0 AND EPCs_Utilized__c!=null)
                                                                        OR (Type__c!='Finance Adjustment' AND EPCs_Utilized__c > 0))
                                                                        AND ((Student__r.Override_EPCU__c = true OR EPC_Utilization_Item__r.Student__r.Override_EPCU__c = true) 
                                                                        OR (Student__r.Approved__c = true OR EPC_Utilization_Item__r.Student__r.Approved__c = true))];

        Map<String, Decimal> provisionedOppsUsed = new Map<String, Decimal>();      
        
        system.debug(approvedOrOverrideUtilization.size());

        for (EPC_Utilization__c epc : approvedOrOverrideUtilization){
            Decimal count = provisionedOppsUsed.get(epc.Opportunity__c + epc.Opportunity__r.Name);

            if (count == null){
                count = epc.EPCs_Utilized__c;
                provisionedOppsUsed.put(epc.Opportunity__c + epc.Opportunity__r.Name, count);
                
            }

            else if (count != null){
                count = count + epc.EPCs_Utilized__c;

                provisionedOppsUsed.put(epc.Opportunity__c + epc.Opportunity__r.Name, count);
            }
        } 
        
        return provisionedOppsUsed;
    }

      //fetch picklist values from custom object in lwc
      @AuraEnabled(cacheable=true)
      public static List < customValueWrapper > getCompedReasonOptions(sObject customObjInfo, string selectPicklistApi) {
         Schema.DescribeSObjectResult objDescribe = customObjInfo.getSObjectType().getDescribe();     
         map < String, Schema.SObjectField > customFieldMap = objDescribe.fields.getMap();      
         list < Schema.PicklistEntry > custPickValues = customFieldMap.get(selectPicklistApi).getDescribe().getPickListValues();
         list < customValueWrapper > customObjWrapper = new list < customValueWrapper > ();
         for (Schema.PicklistEntry myCustPick: custPickValues) {
           customValueWrapper selectOptionValueWrapper = new customValueWrapper();
              selectOptionValueWrapper.label = myCustPick.getLabel();
              selectOptionValueWrapper.value = myCustPick.getValue();
             customObjWrapper.add(selectOptionValueWrapper);
         }
         system.debug(customObjWrapper);
         return customObjWrapper;
   
       }

       public with sharing class customValueWrapper {
        @auraEnabled public string label {get;set;}
        @auraEnabled public string value {get;set;}
      }

    public Class StudentWrapper{
        @AuraEnabled
        public String OppId {get;set;}
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public String StudentId {get;set;}
        @AuraEnabled
        public String Service {get;set;}
        @AuraEnabled
        public Decimal EPC {get;set;}
        @AuraEnabled
        public Decimal totalEPC {get;set;}
        @AuraEnabled
        public String oppName {get;set;}
        @AuraEnabled
        public List<epcui> epcuis {get;set;}
        @AuraEnabled
        public Boolean Approved {get;set;}
        @AuraEnabled
        public String ApprovedBy {get;set;}
        @AuraEnabled
        public DateTime ApprovalDate {get;set;}
        @AuraEnabled
        public Date UtilizationDate {get;set;}
        @AuraEnabled
        public String notes {get;set;}
        @AuraEnabled
        public String compedCategory {get;set;}
        @AuraEnabled
        public Boolean isOverride {get;set;}
        @AuraEnabled
        public String AccountId {get;set;}
        @AuraEnabled
        public String AccountName {get;set;}
        @AuraEnabled
        public String StudentStatus {get;set;}
        @AuraEnabled
        public String serviceName {get;set;}
        @AuraEnabled
        public String serviceId {get;set;}
        @AuraEnabled
        public Decimal price {get;set;}
        @AuraEnabled
        public Decimal cost {get;set;}
        @AuraEnabled
        public Boolean isAEP {get;set;}
        @AuraEnabled
        public Boolean isComped {get;set;}
        @AuraEnabled
        public Decimal tagTotalEPC {get;set;}
        @AuraEnabled
        public Boolean tagOnly {get;set;}

    }

    public Class epcui{
        @AuraEnabled
        public String StudentId {get;set;}
        @AuraEnabled
        public String Service {get;set;}
        @AuraEnabled
        public Decimal EPC {get;set;}
        @AuraEnabled
        public String oppName {get;set;}
        @AuraEnabled
        public Boolean Approved {get;set;}
        @AuraEnabled
        public Boolean tag {get;set;}
        @AuraEnabled
        public String tagId {get;set;}
        @AuraEnabled
        public Date UtilizationDate {get;set;}
        @AuraEnabled
        public Decimal cost {get;set;}
        @AuraEnabled
        public Decimal price {get;set;}
    }

    public Class OppWrapper{
        @AuraEnabled
        public String OppId {get;set;}
        @AuraEnabled
        public String OppName {get;set;}
        @AuraEnabled
        public Decimal EPCLeft {get;set;}
    }

    public Class saveStudentWrapper{
        @AuraEnabled
        public String studentId {get;set;}
        @AuraEnabled
        public String oppId {get;set;}
        @AuraEnabled
        public Decimal studentEPC {get;set;}
        @AuraEnabled
        public List<tags> tags {get;set;}
        @AuraEnabled
        public String notes {get;set;}
        @AuraEnabled
        public String compCategory {get;set;}
        @AuraEnabled
        public String overrideBoolean {get;set;}
       
    }

    public Class tags{
        @AuraEnabled
        public String Id {get;set;}
        @AuraEnabled
        public String tagEpc {get;set;}
        @AuraEnabled
        public String tagStartingEpc {get;set;}
        @AuraEnabled
        public String tagNotes {get;set;}
        @AuraEnabled
        public String compedCategory {get;set;}
    }

    public Class studentWire{
        @AuraEnabled
        public String accountId {get;set;}
        @AuraEnabled
        public String approval {get;set;}
        @AuraEnabled
        public Date startDate {get;set;}
        @AuraEnabled
        public Date endDate {get;set;}
    }
}