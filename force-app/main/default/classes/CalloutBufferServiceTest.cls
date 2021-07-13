@isTest
private class CalloutBufferServiceTest {

    private static testMethod void CheckForCalloutBuildsJsonBody() {

        insertCustomSettings();
        Account account = new account(name = 'Test Account');
        insert account;
        Opportunity opportunity = new Opportunity(Name = 'Test Opportunity', StageName = 'Test', CloseDate = Date.today(), accountId = account.Id);
        insert opportunity;
        //List<SObject> students = new List<Student__c>();
        //students.add(student);

        String jsonBody = CalloutBuffer.buildJSONbody(opportunity, 'POST');
    }

    private static void insertCustomSettings() {
        Integration_Field_Configuration__C integrationFieldConfig = buildIntegrationFieldConfiguration();
        insert integrationFieldConfig;

    }
    private static Integration_Field_Configuration__C buildIntegrationFieldConfiguration() {
        Integration_Field_Configuration__C integrationFieldConfig = new Integration_Field_Configuration__C();
        integrationFieldConfig.Name = 'Test';
        integrationFieldConfig.Field__c = 'accountId';
        integrationFieldConfig.Integration_Key__c = 'accountId';
        integrationFieldConfig.Object_Type__c = 'Opportunity';

        return integrationFieldConfig;
    }

    private static void insertResources() {
        Callout_Buffer_Resources__c bufferResources = new Callout_Buffer_Resources__c(
            Name = 'Opportunity',
            Resource__c = 'opportunities',
            Enabled__c = true
        );
    }

    @isTest private static void updateInProgressTimesTest() {

        Callout_Buffer_Item__c[] cbis = new List<Callout_Buffer_Item__c>{(new Callout_Buffer_Item__c(Status__c = 'In-progress'))};
        insert cbis;
        Integer start = System.Now().millisecond();
        while(System.Now().millisecond()< start+5){ 
        }
        CalloutBufferService.updateInProgressTimes();
        System.assertEquals(cbis[0].status__c , 'In-progress', cbis[0].status__c );
        cbis = [select Id, Processing_Time__c from Callout_Buffer_Item__c];
        System.assertEquals(true, cbis[0].Processing_Time__c > 0, (cbis[0].Processing_Time__c).format());
    }

    // Contact Type list has one type that is in the callout type list
    @isTest private static void doCalloutForContactTypeTest1() {
        Account acct = new Account(Name = 'Test Account');
        insert acct;
        Contact contact = new Contact(firstname = 'test', lastname = 'test', email = 'test@example.com', accountid = acct.id, contact_type__c='Coach');
        insert contact;
        System.assert(CalloutBufferService.doCalloutForContactType(contact));
    }

    // Contact Type list has one type that is not in the callout type list
    @isTest private static void doCalloutForContactTypeTest2() {
        Account acct = new Account(Name = 'Test Account');
        insert acct;
        Contact contact = new Contact(firstname = 'test', lastname = 'test', email = 'test@example.com', accountid = acct.id, contact_type__c='Coaches');
        insert contact;
        System.assert(!CalloutBufferService.doCalloutForContactType(contact));
    }    

    // Contact Type list has more than one type but one is in the callout type list
    @isTest private static void doCalloutForContactTypeTest3() {
        Account acct = new Account(Name = 'Test Account');
        insert acct;
        Contact contact = new Contact(firstname = 'test', lastname = 'test', email = 'test@example.com', accountid = acct.id, contact_type__c='Coaches;Auditor');
        insert contact;
        System.assert(CalloutBufferService.doCalloutForContactType(contact));
    }    

    // Contact Type list has more than one type but one is in the callout type list
    @isTest private static void doCalloutForContactTypeTest4() {
        Account acct = new Account(Name = 'Test Account');
        insert acct;
        Contact contact = new Contact(firstname = 'test', lastname = 'test', email = 'test@example.com', accountid = acct.id);
        insert contact;
        System.assert(!CalloutBufferService.doCalloutForContactType(contact));
    }


}