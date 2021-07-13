@isTest
private class ManageEPCTest {
    @testSetup static void setupTestRecords() {
        
        TriggerConfiguration__c triggerConfiguration = TriggerConfiguration__c.getOrgDefaults();
        triggerConfiguration.Enable_Auto_Calculate_EPC_Utilization__c = TRUE;
        upsert triggerConfiguration;
        
        Integer count = 0;
        
	    Account a = new Account();
        a.Name = 'Acme';
        insert a;

		//Insert Products
        System.Debug('Insert Products');
		List<Product2> productList = new List<Product2>();
        productlist.add(new Product2(Name = 'EPC', ProductCode = 'EPC', isActive = true ));
        insert productlist;

        //Create PricebookEntries
        System.Debug('Insert PricebookEntries');
        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();
	    Id pricebookId = Test.getStandardPricebookId();
        for(count = 0 ; count < productlist.size() ; count++) {
            System.Debug('PBE '+productlist[count].Id);
            pricebookEntryList.add(new PricebookEntry(Pricebook2Id = pricebookId,
                                                      Product2Id = productlist[count].Id,
                                                      UnitPrice = 1000*(count+1),
                                                      IsActive = true));
        }
        insert pricebookEntryList;

        Id oppRTID = Schema.getGlobalDescribe().get('Opportunity').getDescribe().getRecordTypeInfosByName().get('B2C').getRecordTypeId();


        //Create Opportunities
        System.Debug('Insert Opportunities');
		List<Opportunity> opps = new List<Opportunity>();
		for (count=0 ; count<3 ; count++){
        	opps.add(new Opportunity (
                name = 'New Opp',
                CloseDate = Date.Today().addDays(7*count),
                StageName = 'NB - Phase 1',
                accountId = a.Id,
                RecordTypeId = oppRTID
			));
        }
        insert opps;

        //Create OpportunityLineItem
        System.Debug('Insert OpportunityLineItem');
        List<OpportunityLineItem> oliToInsert = new List<OpportunityLineItem>();
		for (count=0 ; count<3 ; count++){
	        oliToInsert.add(new OpportunityLineItem( 
				OpportunityId = opps[count].Id,
				Quantity = 2,
				UnitPrice = pricebookEntryList[0].UnitPrice,
				PricebookEntryId = pricebookEntryList[0].Id
        	));
        }
		insert oliToInsert;

        //Update Opportiunities
        System.Debug('Update Opportiunities');
        for (Opportunity opp:opps) {
            opp.StageName = 'Closed/Won';
        }
        update opps;
        
        List<Contact> contacts = new List<Contact>();
		for (count=0 ; count<3 ; count++){
			contacts.add(new Contact(
                FirstName = 'Test Student',
                Email = 'contact'+count+'@example.com',
                LastName = 'Student ' + count,
                AccountId = a.Id
        	));
        }

        insert contacts;
        
        Service__c serviceCoreProgramABC = new Service__c (name='Core Program', Marketing_Name__c='ABC',
            List_Weighting__c= 1.00, Status__c='Active',Service_Category__c='All', Utilization_Date_Formula__c='Program Start Date -14d');
        insert serviceCoreProgramABC;

        Program_Family__c programFamilyABC = new Program_Family__c (name='ABC', Friendly_Name__c='ABC',
            Primary_Service__c=serviceCoreProgramABC.Id);
        insert programFamilyABC;
        system.debug(programFamilyABC.Primary_Service__c);
        system.debug(programFamilyABC.Primary_Service__r.List_Weighting__c);

        programFamilyABC.Primary_Service__c = serviceCoreProgramABC.Id;

        update programFamilyABC;

        serviceCoreProgramABC.Program_Family__c = programFamilyABC.Id;
        update serviceCoreProgramABC;

		Program__c program = new Program__c();
        program = new Program__c(friendly_name__c = 'test', short_name__c = 'test', EPC__c=1, Program_Family__c=programFamilyABC.Id, Course_Start_Date__c = Date.today() - 14);
        insert program;

 
        Test.startTest();
        

        Program__c p = [SELECT Id, Program_Family__r.Primary_Service__r.List_Weighting__c, Course_Start_Date__c FROM Program__c WHERE Id =:program.Id LIMIT 1];

        system.debug(p.Program_Family__r.Primary_Service__r.List_Weighting__c);
     
             List<Student__c> students = new List<Student__c>();
             for (count=0 ; count<3 ; count++){
                 students.add(new Student__c(
                     Contact__c = contacts[count].Id,    
                     Program__c = p.Id, 
                     Status__c='Enrolled',
                     EPCs_Comped__c = .01,
                     EPCs_Deferred__c = .01,
                     Approved__c = false,
                     Override_EPCU__c = false,
                     Registration_Tags__c = 'Written feedback'
     
                     
                 ));
             }

        insert students;

        List<EPC_Weighting__c> epcwList = new List<EPC_Weighting__c>();
        List<EPC_Utilization__c> epcuList = new List<EPC_Utilization__c>();

        EPC_Utilization__c provEPC = new EPC_Utilization__c();
        provEPC.Account__c = a.Id;
        provEPC.Type__c = 'Provisioned';
        provEPC.EPCs_Utilized__c = 10;
        provEPC.Opportunity__c = opps[0].Id;

        insert provEPC;

        EPC_Utilization__c epcuActual = new EPC_Utilization__c();
        epcuActual.Account__c = a.Id;
        epcuActual.Type__c = 'Actual';
        epcuActual.EPCs_Utilized__c = 1.00;
        epcuActual.Opportunity__c = opps[0].Id;
        epcuActual.Provisioned_EPCU__c = [SELECT Id FROM EPC_Utilization__c LIMIT 1]?.Id;
        epcuActual.Student__c = students[1].Id;

        epcuList.add(epcuActual);
        
        EPC_Utilization__c epcu = new EPC_Utilization__c();
            epcu.Account__c = a.Id;
            epcu.Type__c = 'Finance Adjustment';
            epcu.EPCs_Utilized__c = 1.00;

            epcuList.add(epcu);

            insert epcuList;

            EPC_Weighting__c epcwOpp = new EPC_Weighting__c();
            epcwOpp.Account__c = a.Id;
            epcwOpp.Opportunity__c = opps[0].Id;
            epcwOpp.Service__c = serviceCoreProgramABC.Id;
            epcwOpp.EPC_Weighting__c = 1.00;
            epcwOpp.Program_Family__c = programFamilyABC.Id;
            epcwOpp.Start_Date__c = Date.Today();
            epcwOpp.End_Date__c = Date.Today() + 1;
            
    
            epcwList.add(epcwOpp);

            EPC_Weighting__c epcwAcc = new EPC_Weighting__c();
            epcwAcc.Account__c = a.Id;
            epcwAcc.Service__c = serviceCoreProgramABC.Id;
            epcwAcc.EPC_Weighting__c = 1.00;
            epcwAcc.Program_Family__c = programFamilyABC.Id;
            epcwAcc.Start_Date__c = Date.Today();
            epcwAcc.End_Date__c = Date.Today() + 1;
            
            epcwList.add(epcwAcc);
            
            insert epcwList;

            EPC_Utilization_Item__c newUtilizationItem = new EPC_Utilization_Item__c();

            newUtilizationItem.Contact__c = contacts[0].Id;
            newUtilizationItem.Service__c = serviceCoreProgramABC.Id;
            newUtilizationItem.Student__c = students[0].Id;
            newUtilizationItem.Status__C  = 'Active';
            newUtilizationItem.EPCs_Comped__c = 0.01;
            newUtilizationItem.EPCs_Deferred__c = 0.01;
            newUtilizationItem.EPCs_Discounted__c = 0.01;
            newUtilizationItem.EPC_Utilization_Date__c = Date.Today();

            insert newUtilizationItem;
                         
        Test.stopTest();
  
      }

      @isTest private static void testManageEPC() {

        Test.startTest();

        Id acctId = [SELECT Id FROM Account LIMIT 1].Id;
        Id studentId = [SELECT Id FROM Student__c LIMIT 1].Id;

        List<Id> studentIds = new List<Id>();
        studentIds.add(studentId);

        

        Boolean canEdit = ManageEPCController.canEdit(acctId);

        ManageEPCController.approveRecords(studentIds);

        List<ManageEPCController.OppWrapper> opps = ManageEPCController.getOpps(acctId);

        Test.stopTest();
      }

      @isTest private static void testTreeGrid(){

        Test.startTest();

        ManageEPCController.studentWire sw = new ManageEPCController.studentWire();
        Id acctId = [SELECT Id FROM Account LIMIT 1].Id;

        sw.accountId = acctId;
        sw.approval = 'false';
        sw.startDate = null;
        sw.endDate = null;


        List<ManageEPCController.StudentWrapper> studentWrapper = ManageEPCController.studentsTree(JSON.serialize(sw));

        Test.stopTest();
  
      }

      @isTest private static void testSaveStudent(){
          Test.startTest();
          EPC_Utilization__c epc = [SELECT Id, Opportunity__c FROM EPC_Utilization__c WHERE Type__c = 'Provisioned'LIMIT 1];
         
          Id epcOppId = epc.Opportunity__c;

        Id studentId = [SELECT Id FROM Student__c LIMIT 1].Id;
        Id oppId = [SELECT Id, isClosed, StageName FROM Opportunity WHERE Id =:epcOppId].Id;
        
        Id epcuiId = [SELECT Id FROM EPC_Utilization_Item__c WHERE Student__c =:studentId].Id;

        ManageEPCController.saveStudentWrapper sw = new ManageEPCController.saveStudentWrapper();
        ManageEPCController.tags tags = new ManageEPCController.tags();

        sw.studentId = studentId;
        sw.oppId = oppId;
        sw.studentEPC = 1;
        sw.notes = 'here are notes';
        sw.compCategory = 'Other';
        sw.overrideBoolean = 'true';

        tags.Id= epcuiId;
        tags.tagEpc = '.2';
        tags.tagStartingEpc = '.2';

        List<ManageEPCController.tags> tagList = new List<ManageEPCController.tags>();
        tagList.add(tags);

        sw.tags = tagList;

        ManageEPCController.saveStudent(JSON.serialize(sw));

        Test.stopTest();
      }


}