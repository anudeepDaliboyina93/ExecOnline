@isTest
public with sharing class CampaignHandlerTest {
	public CampaignHandlerTest() {
		
	}


	@isTest
	public static void campaignHandlerUpdateNameTest() {
    
        Program__c program = new Program__c(friendly_name__c = 'test', short_name__c = 'test');
        insert program;        


        Campaign camp = new Campaign(Name = 'Test Camp', Program__c = program.Id);
        insert camp; 

        program.Manager_Campaign__c = camp.id;
        upsert program;

		camp = [Select Id, Name from Campaign where Id = :camp.Id];
		camp.Name = 'Test Camp 2';
		upsert camp;

		camp = [Select Id, Name from Campaign where Id = :camp.Id];
		System.AssertEquals('Test Camp', camp.Name);		
	}

	@isTest
	public static void campaignHandlerUpdateName_NonMgrProgTest() {
    
       

        Program__c program2 = new Program__c(friendly_name__c = 'test', short_name__c = 'test');
        insert program2;

        Campaign campNonMgrProgram = new Campaign(Name = 'Test Camp', Program__c = program2.Id);
        insert campNonMgrProgram;


		campNonMgrProgram = [Select Id, Name from Campaign where Id = :campNonMgrProgram.Id];
		campNonMgrProgram.Name = 'Test Camp 2';
		upsert campNonMgrProgram;

		campNonMgrProgram = [Select Id, Name from Campaign where Id = :campNonMgrProgram.Id];
		System.AssertEquals('Test Camp 2', campNonMgrProgram.Name);		

	}
}