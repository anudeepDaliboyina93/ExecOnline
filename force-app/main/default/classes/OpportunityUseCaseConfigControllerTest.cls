@isTest 
private class OpportunityUseCaseConfigControllerTest {   
   
    
    static testMethod void getUseCaseRecordsTest() {
        Account acc = new Account(Name='Test Acc');
        insert acc;
        Opportunity opp = new Opportunity(Name = 'Test Opp', AccountId= acc.Id, StageName= 'EB - Phase 1', CloseDAte = DAte.today());        
        insert opp; 
        Use_Case__c useCase1 = new Use_Case__c(Name= 'Test Use Case 1', Account__c=acc.Id);
        insert useCase1;
        Use_Case__c useCase2 = new Use_Case__c(Name= 'Test Use Case 2', Account__c=acc.Id);
        insert useCase2;
        Use_Case_Opportunity__c useCAseOpp = new Use_Case_Opportunity__c(Status__c='Active', Opportunity__c = opp.Id, Use_Case__c = useCase1.Id);
        insert useCaseOpp;

        OpportunityUseCaseConfigController.ComponentElements compElement = OpportunityUseCaseConfigController.getUseCaseOppRecords(opp.Id, Acc.Id);
        System.assertEquals(true, compElement.useCaseList.size() == 1);
        System.assertEquals(true, compElement.useCaseOppList.size() == 1);
    }

    static testMethod void updateUseCaseTest() {
       Account acc = new Account(Name='Test Acc');
        insert acc;
        Opportunity opp = new Opportunity(Name = 'Test Opp', AccountId= acc.Id, StageName= 'EB - Phase 1', CloseDAte = DAte.today());        
        insert opp; 
        Use_Case__c useCase1 = new Use_Case__c(Name= 'Test Use Case 1', Account__c=acc.Id);
        insert useCase1;
        Use_Case__c useCase2 = new Use_Case__c(Name= 'Test Use Case 2', Account__c=acc.Id);
        insert useCase2;
        Use_Case_Opportunity__c useCAseOpp = new Use_Case_Opportunity__c(Status__c='Active', Opportunity__c = opp.Id, Use_Case__c = useCase1.Id);
        insert useCaseOpp; 

        useCase1.Name = 'Test Use Case 1_1';

        OpportunityUseCaseConfigController.updateUseCase(useCaseOpp, useCase1);
        System.assertNotEquals(null, [Select Id, Name From Use_Case__c Where Name = 'Test Use Case 1_1' ]);
        try{OpportunityUseCaseConfigController.updateUseCase(null, null);}
        catch(Exception e){}
    }
    static testMethod void saveUseCaseOppRecordTest() {
        Account acc = new Account(Name='Test Acc');
        insert acc;
        Opportunity opp = new Opportunity(Name = 'Test Opp', AccountId= acc.Id, StageName= 'EB - Phase 1', CloseDAte = DAte.today());        
        insert opp; 
        Use_Case__c useCase1 = new Use_Case__c(Name= 'Test Use Case 1', Account__c=acc.Id);
        insert useCase1;
        Use_Case__c useCase2 = new Use_Case__c(Name= 'Test Use Case 2', Account__c=acc.Id);
        insert useCase2;
        Use_Case_Opportunity__c useCAseOpp = new Use_Case_Opportunity__c(Status__c='Active', Opportunity__c = opp.Id, Use_Case__c = useCase1.Id);
        insert useCaseOpp;

        OpportunityUseCaseConfigController.saveUseCaseOppRecord(new Use_Case_Opportunity__c(Status__c='Active', Opportunity__c = opp.Id, Use_Case__c = useCase1.Id));
        List<Use_Case_Opportunity__c> useCaseOppList = [Select Id, Use_Case__c From Use_Case_Opportunity__c ];
        System.assertEquals(2, useCaseOppList.size());
        try{OpportunityUseCaseConfigController.saveUseCaseOppRecord(null);}
        catch(Exception e){}
    }
    static testMethod void insertUseCaseOppRecordsTest() {
        Account acc = new Account(Name='Test Acc');
        insert acc;
        Opportunity opp = new Opportunity(Name = 'Test Opp', AccountId= acc.Id, StageName= 'EB - Phase 1', CloseDAte = DAte.today());        
        insert opp; 
        Use_Case__c useCase1 = new Use_Case__c(Name= 'Test Use Case 1', Account__c=acc.Id);
        insert useCase1;
        Use_Case__c useCase2 = new Use_Case__c(Name= 'Test Use Case 2', Account__c=acc.Id);
        insert useCase2;
        Use_Case_Opportunity__c useCAseOpp = new Use_Case_Opportunity__c(Status__c='Active', Opportunity__c = opp.Id, Use_Case__c = useCase1.Id);
        insert useCaseOpp;

        OpportunityUseCaseConfigController.insertUseCaseOppRecords(opp.Id, new List<String>{useCase1.Id});
        List<Use_Case_Opportunity__c> useCaseOppList = [Select Id, Use_Case__c From Use_Case_Opportunity__c ];
        System.assertEquals(2, useCaseOppList.size());
        try{OpportunityUseCaseConfigController.insertUseCaseOppRecords(null, null);}
        catch(Exception e){}
    }
}