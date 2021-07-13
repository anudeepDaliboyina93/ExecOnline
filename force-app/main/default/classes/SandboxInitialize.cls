global class SandboxInitialize implements SandboxPostCopy {
    global void runApexClass(SandboxContext context) {
        upsertAndDisableCalloutBuffer(); 
    }

    private void upsertAndDisableCalloutBuffer() {
        // disable callout buffer for new sandboxes to stop false alerts on prod api
        Callout_Buffer_Configuration__c calloutBufferConfig = Callout_Buffer_Configuration__c.getInstance();
        calloutBufferConfig.Endpoint_Address__c = 'https://platform.staging.execonline.com/api';
        calloutBufferConfig.Callout_Buffer_Enabled__c = false;
        upsert calloutBufferConfig;
    }
}