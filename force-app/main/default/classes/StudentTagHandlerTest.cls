@isTest
private class StudentTagHandlerTest {

    @TestSetup
    public static void setupTestRecords() {
        
        TriggerConfiguration__c triggerConfiguration = TriggerConfiguration__c.getOrgDefaults();
        triggerConfiguration.Enable_Auto_Calculate_EPC_Utilization__c = false;
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

        //Create Opportunities
        System.Debug('Insert Opportunities');
		List<Opportunity> opps = new List<Opportunity>();
		for (count=0 ; count<3 ; count++){
        	opps.add(new Opportunity (
                name = 'New Opp',
                CloseDate = Date.Today().addDays(7*count),
                StageName = 'NB - Phase 1',
                accountId = a.Id
			));
        }
        insert opps;

        //Create OpportunityLineItem
        System.Debug('Insert OpportunityLineItem');
        List<OpportunityLineItem> oliToInsert = new List<OpportunityLineItem>();
		for (count=0 ; count<3 ; count++){
	        oliToInsert.add(new OpportunityLineItem( 
				OpportunityId = opps[count].Id,
				Quantity = 1,
				UnitPrice = pricebookEntryList[0].UnitPrice,
				PricebookEntryId = pricebookEntryList[0].Id,
                Service_Category__c = 'All'
        	));
        }
		insert oliToInsert;

        //Update Opportiunities
        System.Debug('Update Opportiunities');
        for (Opportunity opp:opps) {
            opp.StageName = 'Closed Won';
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

        //Insert Contacts
        System.Debug('Insert Contacts');
        insert contacts;
        
        Service__c serviceCoreProgramABC = new Service__c (name='Core Program', Marketing_Name__c='ABC',
            List_Weighting__c=1, Status__c='Active',Service_Category__c='All', Utilization_Date_Formula__c='Program Start Date -14d');
        //Insert Service Core Program
        System.Debug('Insert Service Core Program');
        insert serviceCoreProgramABC;

        Service__c serviceWrittenFeedback = new Service__c (name='Written feedback', Marketing_Name__c='Written feedback',
            List_Weighting__c=1, Status__c='Active',Service_Category__c='All', Utilization_Date_Formula__c='Program Start Date -14d');
        //Insert Service Core Program
        System.Debug('Insert Service Core Program');
        insert serviceWrittenFeedback;

        Program_Family__c programFamilyABC = new Program_Family__c (name='ABC', Friendly_Name__c='ABC',
            Primary_Service__c=serviceCoreProgramABC.Id);
        //Insert ProgramFamily
        System.Debug('Insert ProgramFamily');
        insert programFamilyABC;

        serviceCoreProgramABC.Program_Family__c = programFamilyABC.Id;
        update serviceCoreProgramABC;

		Program__c program = new Program__c();
        program = new Program__c(friendly_name__c = 'test', short_name__c = 'test', EPC__c=1, Program_Family__c=programFamilyABC.Id);
        insert program;

        Tag__c tag = new Tag__c(name='Written feedback', Name_External_Id__c='Written feedback');
        insert tag;

        Tag_Service__c tagService = new Tag_Service__c(service__c=serviceWrittenFeedback.Id, tag__c=tag.Id);
        insert tagService;
    }

    @isTest
    static void test() {
        TriggerConfiguration__c triggerConfiguration = TriggerConfiguration__c.getOrgDefaults();
        triggerConfiguration.Enable_Auto_Calculate_EPC_Utilization__c = true;
        upsert triggerConfiguration;

        Program__c program = [SELECT Id FROM Program__c LIMIT 1];
        List<Contact> contacts = [SELECT Id FROM Contact];
        List<Student__c> students = new List<Student__c>();
		for (Integer count=0 ; count<3 ; count++){
            students.add(new Student__c(
				Contact__c = contacts[count].Id,    
                Program__c = program.Id, 
                Status__c='Prospect',
                Registration_Tags__c='Written feedback'
            ));
        }

        Test.startTest();
		insert students;
        
		for (Integer count=0 ; count<3 ; count++){
            students[count].Registration_Tags__c = '';
        }

        List<Student_Tag__c> studentTags = new List<Student_Tag__c>([SELECT Id, Tag__c, Student__c FROM Student_Tag__c]);
        update studentTags;

        Test.stopTest();
        
    }
    
}