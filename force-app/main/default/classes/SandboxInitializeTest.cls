@isTest
public class SandboxInitializeTest {
    @isTest
    static void testSandboxInitialize() {
        insert new Callout_Buffer_Configuration__c(Endpoint_Address__c = 'https://platform.execonline.com/api', Callout_Buffer_Enabled__c = false);

        Test.startTest();

        Test.testSandboxPostCopyScript(
            new SandboxInitialize(), UserInfo.getOrganizationId(),
                UserInfo.getOrganizationId(), UserInfo.getOrganizationName());

        Test.stopTest();

        Callout_Buffer_Configuration__c calloutBufferConfig = Callout_Buffer_Configuration__c.getInstance();
        System.assertEquals(false, calloutBufferConfig.Callout_Buffer_Enabled__c);
    }
}