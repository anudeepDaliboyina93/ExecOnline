/* CalloutBufferTest.cls
* Copyright 2014 Wired Triangle, LLC
* http://www.wiredtriangle.com
*/
@isTest
public class CalloutBufferTest {

    // Test what happens when the callout buffer is not completely set up. (In this case, the
    // username is missing)
    @isTest static void TestBufferNotSetup() {
        Callout_Buffer_Configuration__c cbc = new Callout_Buffer_Configuration__c();
        cbc.Callout_Buffer_Enabled__c = true;
        cbc.Endpoint_Address__c ='http://blah.com';
        cbc.Version__c='1';
        cbc.Password__c = 'password';
        insert cbc;

        // Add a new callout buffer item
        CalloutBuffer.addBufferItems(new List<CalloutBuffer.calloutBufferItem>{new CalloutBuffer.calloutBufferItem('fakeEndpoint{versionNum}', 'POST', '{"bodyKey1":"bodyVal1","bodyKey2":2}', null, new Map<String, String>(), null)});
        Callout_Buffer_Item__c cbi = [select id, endpoint__c from Callout_Buffer_Item__c];
        // And make sure it was added correctly
        system.assertEquals('fakeEndpoint{versionNum}',cbi.Endpoint__c);

        // Delete it...
        CalloutBuffer.deleteBufferItems(new List<String>{cbi.id});

        // ... and it's gone
        Callout_Buffer_Item__c[] cbis = [select id from Callout_Buffer_Item__c];
        system.assert(cbis.isEmpty());

        // Add it back...
        CalloutBuffer.addBufferItems(new List<CalloutBuffer.calloutBufferItem>{new CalloutBuffer.calloutBufferItem('fakeEndpoint{versionNum}', 'POST', '{"bodyKey1":"bodyVal1","bodyKey2":2}', null, new Map<String, String>(), null)});
        cbi = [select id, endpoint__c from Callout_Buffer_Item__c];
        system.assertEquals('fakeEndpoint{versionNum}',cbi.Endpoint__c);

        // And flush the buffer...
        Test.startTest();
        CalloutBuffer.flushBuffer();
        Test.stopTest();

        // Our buffer item should have a retry attempt, as the callout failed
        cbi = [select id, endpoint__c, Retry_Attempts__c from Callout_Buffer_Item__c];
        system.assertEquals('fakeEndpoint{versionNum}',cbi.Endpoint__c);
        system.assertEquals(1.0,cbi.Retry_Attempts__c);
    }

    // Not let's try things for real...
    @isTest static void TestBufferIsSetupPass() {
        // Build our test runtime setup...
        Callout_Buffer_Configuration__c cbc = new Callout_Buffer_Configuration__c();
        cbc.Callout_Buffer_Enabled__c = true;
        cbc.Endpoint_Address__c ='http://blah.com';
        cbc.Version__c='1';
        cbc.Password__c = 'password';
        cbc.Username__c = 'username';
        cbc.SetupOwnerId = UserInfo.getOrganizationId();
        cbc.Token__c = 'token';
        insert cbc;

        // Add a new callout buffer item
        CalloutBuffer.addBufferItems(new List<CalloutBuffer.calloutBufferItem>{new CalloutBuffer.calloutBufferItem('fakeEndpoint{versionNum}', 'POST',  '{ "sections" : [{"bodyKey1":"bodyVal1","bodyKey2":"bodyVal"}]}', null, new Map<String, String>(), null)});
        Callout_Buffer_Item__c cbi = [select id, endpoint__c from Callout_Buffer_Item__c];
        system.assertEquals('fakeEndpoint{versionNum}',cbi.Endpoint__c);

        // Set our endpoint mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // And do the callout
        Test.startTest();
        CalloutBuffer.flushBuffer();
        Test.stopTest();

        // Now look at the buffer item, and make sure the response body contains what the mock should have
        // put in there
        cbi = [select id, endpoint__c, Retry_Attempts__c, Last_Response_Body__c from Callout_Buffer_Item__c];
        system.assertEquals('fakeEndpoint{versionNum}',cbi.Endpoint__c);
        system.assertEquals('[{ "foos" : [{"foo": "bar"}]}]',cbi.Last_Response_Body__c);

    }

    // Not let's try things for real, on mock endpoint that returns <> 200...
    @isTest static void TestBufferIsSetupFail() {
        // Build our test runtime setup...
        Callout_Buffer_Configuration__c cbc = new Callout_Buffer_Configuration__c();
        cbc.Callout_Buffer_Enabled__c = true;
        cbc.Endpoint_Address__c ='http://blah.com';
        cbc.Version__c='1';
        cbc.Password__c = 'password';
        cbc.Username__c = 'username';
        cbc.SetupOwnerId = UserInfo.getOrganizationId();
        cbc.Token__c = 'token';
        insert cbc;

        // Add a new callout buffer item
        CalloutBuffer.addBufferItems(new List<CalloutBuffer.calloutBufferItem>{new CalloutBuffer.calloutBufferItem('fakeEndpoint{versionNum}', 'POST', '{ "sections" : [{"bodyKey1":"bodyVal1","bodyKey2":"bodyVal"}]}', null, new Map<String, String>(), null)});
        Callout_Buffer_Item__c cbi = [select id, endpoint__c from Callout_Buffer_Item__c];
        system.assertEquals('fakeEndpoint{versionNum}',cbi.Endpoint__c);

        // Set our endpoint mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorFail());

        // And do the callout
        Test.startTest();
        CalloutBuffer.flushBuffer();
        Test.stopTest();

        // Now look at the buffer item, and make sure the response body contains what the mock should have
        // put in there
        cbi = [select id, endpoint__c, Retry_Attempts__c, Last_Response_Body__c, Last_Response_Status_Code__c from Callout_Buffer_Item__c];
        system.assertEquals('fakeEndpoint{versionNum}',cbi.Endpoint__c);
        // system.assertEquals('{"foo":"bar"}',cbi.Last_Response_Body__c);
        system.assertEquals('Callout username, password, endpoint, or version not set',cbi.Last_Response_Body__c);

        system.assertEquals(400,cbi.Last_Response_Status_Code__c);
        system.assertEquals(1.0,cbi.Retry_Attempts__c);
    }

    @isTest
    static void excludedUserIdsTest_None() {
        Callout_Buffer_Configuration__c cbc = new Callout_Buffer_Configuration__c();
        cbc.Callout_Buffer_Enabled__c = true;
        cbc.Endpoint_Address__c ='http://blah.com';
        cbc.Version__c='1';
        cbc.Password__c = 'password';
        cbc.Username__c = 'username';
        cbc.SetupOwnerId = UserInfo.getOrganizationId();
        cbc.Token__c = 'token';
        insert cbc;

        system.assertEquals(false,CalloutBuffer.excludeUserFromCallouts());
    }

    @isTest
    static void excludedUserIdsTest_One() {
        Callout_Buffer_Configuration__c cbc = new Callout_Buffer_Configuration__c();
        cbc.Callout_Buffer_Enabled__c = true;
        cbc.Endpoint_Address__c ='http://blah.com';
        cbc.Version__c='1';
        cbc.Password__c = 'password';
        cbc.Username__c = 'username';
        cbc.SetupOwnerId = UserInfo.getOrganizationId();
        cbc.Token__c = 'token';
        cbc.User_Exclusion_List__c = UserInfo.getUserId();

        insert cbc;

        system.assertEquals(true,CalloutBuffer.excludeUserFromCallouts(),cbc);
    }


    public class MockHttpResponseGenerator implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {

            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('[{ "foos" : [{"foo": "bar"}]}]');
            res.setStatusCode(200);
            return res;
        }
    }

    public class MockHttpResponseGeneratorFail implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {

            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"foo":"bar"}');
            res.setStatusCode(400);
            return res;
        }
    }

}