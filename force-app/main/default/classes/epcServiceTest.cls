@isTest
private class epcServiceTest {


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
        productlist.add(new Product2(Name = 'AEP', ProductCode = 'AEP', isActive = true ));
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

        //Create Opportunities
        System.Debug('Insert Opportunities');
		List<Opportunity> opps = new List<Opportunity>();
		for (count=0 ; count<3 ; count++){
        	opps.add(new Opportunity (
                name = 'New Opp',
                CloseDate = Date.Today().addDays(7*count),
                StageName = 'NB - Phase 1',
                accountId = a.Id,
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Ad Hoc').getRecordTypeId()
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
            oliToInsert.add(new OpportunityLineItem( 
				OpportunityId = opps[count].Id,
				Quantity = 1,
				UnitPrice = pricebookEntryList[1].UnitPrice,
				PricebookEntryId = pricebookEntryList[1].Id
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
                AccountId = a.Id,
                Manager_First_Name__c = 'Test',
                Manager_Last_Name__c = 'Manager',
                Manager_s_Email__c = 'testmanager@example.com',
                Manager_s_Title__c = 'CEO'
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

        EPC_Utilization__c epcuActual = new EPC_Utilization__c();
        epcuActual.Account__c = a.Id;
        epcuActual.Type__c = 'Actual';
        epcuActual.EPCs_Utilized__c = 1.00;
        epcuActual.Opportunity__c = opps[0].Id;
        epcuActual.Provisioned_EPCU__c = [SELECT Id FROM EPC_Utilization__c LIMIT 1].Id;
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
                         
		for (count=0 ; count<3 ; count++){

            if (count == 1){
                students[count].Approved__c = true;
            }
        }
        update students; 
        Test.stopTest();
    
    }
    
    @isTest private static void testEpcAutoCalcuationBatch () {

        Test.startTest();

        epcRecalcBatch recalcBatch = new epcRecalcBatch(new List<String>());
        Id batchEpcRecalcBatchId = Database.executeBatch(recalcBatch,50);  
        
        Test.stopTest();
        
    }

    @isTest private static void testApprovalsAndOverrides() {

        Test.startTest();

        Account a = [SELECT Id, EPCs_Total_Balance__c FROM Account LIMIT 1];
        PricebookEntry pb = [SELECT Id, UnitPrice FROM PricebookEntry LIMIT 1];

        //Create Opportunities
        System.Debug('Insert Opportunities');
        Opportunity newOpp = new Opportunity();
        
        newOpp.name = 'New Opp number two';
        newOpp.CloseDate = Date.Today().addDays(60);
        newOpp.StageName = 'Phase 3 - Negotiations';
        newOpp.accountId = a.Id;
        newOpp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Ad Hoc').getRecordTypeId();

        insert newOpp;

        //Create OpportunityLineItem
        
        OpportunityLineItem oli = new OpportunityLineItem(
				OpportunityId = newOpp.Id,
				Quantity = 2,
				UnitPrice = pb.UnitPrice,
				PricebookEntryId = pb.Id
        );
        
		insert oli;

        newOpp.StageName = 'Closed/Won';

        update newOpp;
        
        List<EPC_Utilization__c> epc = [SELECT Id, Type__c, Provisioned_EPCU__c, Opportunity__c, Opportunity__r.Name,  Student__r.Approved__c, EPCs_Utilized__c, EPC_Utilization_Date__c, Student__r.Override_EPCU__c, Student__c FROM EPC_Utilization__c WHERE Type__c = 'Actual' AND Student__c != null ORDER BY EPC_Utilization_Date__c DESC];
        List<EPC_Utilization__c> pepc = [SELECT Id, Type__c, Opportunity__c, Opportunity__r.CloseDate,  Student__r.Approved__c, EPCs_Utilized__c, EPC_Utilization_Date__c FROM EPC_Utilization__c WHERE Type__c = 'Provisioned' ORDER BY Opportunity__r.CloseDate DESC];

        Id actualProvisionedId = epc[0].Provisioned_EPCU__c;
        Id firstAvailableProvisioned = pepc[0].Id;
        Id studentId = epc[0].Student__c;
        Id epcId = epc[0].Id;
        system.debug(epc[0]);
        system.debug(studentId);

        Student__c updateStudent = new Student__c();

        updateStudent.Id = studentId;
        updateStudent.Override_EPCU__c = true;

        update updateStudent;
      
        
        epc[0].Provisioned_EPCU__c = pepc[1].Id;
        epc[0].Opportunity__c = newOpp.Id;

        Id newProvisionedId = pepc[1].Id;
        Id newProvisionedOppId = newOpp.Id;

        update epc[0];

        system.debug(epc[0].Provisioned_EPCU__c);

        Set<Id> acctIdSet = new Set<Id>{a.Id};

        EpcServiceV2 epcHelper = new EpcServiceV2(acctIdSet);
        ID jobID = System.enqueueJob(epcHelper);
        
        EPC_Utilization__c updatedEPC = [SELECT Id, Provisioned_EPCU__c, Opportunity__c FROM EPC_Utilization__c WHERE Id =:epcId];

        Test.stopTest();

        //Check the first available EPC is being provisioned to the actual
        System.assertEquals(actualProvisionedId, firstAvailableProvisioned);
        //Check EPC has override in place after running EPC Service Class
        System.assertEquals(newProvisionedId, updatedEPC.Provisioned_EPCU__c);

    }


}