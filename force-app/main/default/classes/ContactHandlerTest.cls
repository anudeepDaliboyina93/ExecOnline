@isTest
 global class ContactHandlerTest {

    global static TriggerConfiguration__c triggerConfig = TriggerConfiguration__c.getInstance();

     @isTest private static void testContactDML () {
        Test.setMock(HttpCalloutMock.class, new calloutBufferTest.MockHttpResponseGenerator());
        setupCalloutBufferConfig(FALSE);
        setupTestRecords();
    }
    
    
    public static void setupCalloutBufferConfig (Boolean calloutBufferEnabled) {
        User thisUser = [ Select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs( thisUser ){
    
            //Callout_Buffer_Configuration__c cbc = new Callout_Buffer_Configuration__c();
                Callout_Buffer_Configuration__c cbc = Callout_Buffer_Configuration__c.getOrgDefaults();
            cbc.Callout_Buffer_Enabled__c = calloutBufferEnabled;
            cbc.Endpoint_Address__c ='http://blah.com';
            cbc.Version__c='1';
            cbc.Password__c = 'password';
            cbc.Username__c = 'username';
            cbc.SetupOwnerId = UserInfo.getOrganizationId();
            cbc.Token__c = 'token';
            upsert cbc;
        }
    }
    
    @isTest
    public static void setupTestRecords() {
        //Test.setMock(HttpCalloutMock.class, new CalloutBufferTest.MockHttpResponseGenerator());
        //setupCalloutBufferConfig(FALSE);
        
        Integer count = 0;
        
        Account a = new Account();
        a.Name = 'Acme';
        insert a;
        Account a2 = new Account();
        a2.Name = 'York';
        insert a2;
        
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
        
        for (count=0 ; count<3 ; count++){
            contacts[count].LastName = 'StudentNew'+count;
            contacts[count].Email = 'contact'+count*10+'@example.com';
            contacts[count].AccountId = a2.Id;
        }

        triggerConfig.Enable_Auto_Calculate_EPC_Utilization__c = TRUE;
        update contacts;
        delete contacts;
        undelete contacts;
    }
}