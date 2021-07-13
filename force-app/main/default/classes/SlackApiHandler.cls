@RestResource(urlMapping='/slack')
global class SlackApiHandler {

    @HttpPost
    global static void handlePost() {
        RestRequest request = RestContext.request;
        
        if(!isValidRequest(request)) {
            
            return;
        } 

        Slack.InboundRequest inboundRequest = (Slack.InboundRequest)JSON.deserialize(request.params.get('payload'), Slack.InboundRequest.class);
        inboundRequest.parseBlockId();

        switch on inboundRequest.blockAction {
            when 'eventStatusAction' {
                handleEventStatusAction(inboundRequest);
            }
            when 'eventSELedAction' {
                handleEventSELedAction(inboundRequest);
            } 
            when 'updateDealDesk' {
                handleUpdateDealDesk(inboundRequest);
            }
        }
        
    }

    // A valid request is signatures that match and was signed by Slack within last 5 minutes
    static Boolean isValidRequest(RestRequest request) {
        // subtract 5 minutes and convert from ms to s
        
        Decimal fiveMinutesAgo = System.now().addMinutes(-5).getTime() * .001;
        String timeStamp = request.headers.get('X-Slack-Request-Timestamp');
        String slackSignature = request.headers.get('X-Slack-Signature');

        String mySignature = getSlackSignature(timeStamp, getRequestBody(request.params));
        
        return mySignature == slackSignature && Decimal.valueOf(timeStamp) > fiveMinutesAgo;
    }

    @testVisible
    static String getSlackSignature(String timeStamp, String requestBody) {
        // https://api.slack.com/docs/verifying-requests-from-slack
        String stringToSign = SlackApi.apiSettings.Signing_Version__c + ':' + timeStamp + ':' + requestBody;
        Blob signatureBlob = Crypto.generateMac('HmacSHA256', Blob.valueOf(stringToSign), Blob.valueOf(SlackApi.apiSettings.Signing_Secret__c));
        return SlackApi.apiSettings.Signing_Version__c + '=' + EncodingUtil.convertToHex(signatureBlob);
    }

    static String getRequestBody(Map<String, String> params) {
        String requestBody = '';
        for(String key : params.keyset()) {
            
            requestBody += key + '=' + EncodingUtil.urlencode(params.get(key), 'UTF-8');
           
        }
        return requestBody;
    }

    /**
    * Methods to handle different inbound user interaction from Slack
    */

    static void handleEventStatusAction(Slack.InboundRequest inboundRequest) {
        Event event = [SELECT Id, Subject, WhatId FROM Event WHERE Id = :inboundRequest.salesforceId LIMIT 1];
        event.Status__c = inboundRequest.actions[0].value;

        if (event.WhatId != null){

            Schema.SObjectType sobjectType = event.WhatId.getSObjectType();
            String sobjectName = sobjectType.getDescribe().getName();

        

        if (sobjectName == 'Opportunity'){

            String oppId = event.WhatId;

            Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Id =:oppId LIMIT 1];

            String replyMessage = 'Thanks, we updated your event in Salesforce!\n';
            replyMessage += '"' + opp.Name + '" event is now ' + event.Status__c.toLowercase();

            SlackLibrary.replyToHook(inboundRequest.response_url, true, replyMessage, null);

        }
    }

        update event;
    }

    static void handleEventSELedAction(Slack.InboundRequest inboundRequest) {
        Event event = [SELECT Id, Subject, SE_led__c, WhatId FROM Event WHERE Id =:inboundRequest.salesforceId LIMIT 1];
        event.SE_led__c = inboundRequest.actions[0].value;

        if (event.WhatId != null){

            Schema.SObjectType sobjectType = event.WhatId.getSObjectType();
            String sobjectName = sobjectType.getDescribe().getName();

        
        
        if (sobjectName == 'Opportunity'){

            String oppId = event.WhatId;

            Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Id =:oppId LIMIT 1];

            String replyMessage = 'Thanks, we updated your event in Salesforce!\n';
            replyMessage += '"' + opp.Name + '" event had its SE Led field updated to' + event.SE_led__c.toLowercase();

            SlackLibrary.replyToHook(inboundRequest.response_url, true, replyMessage, null);

        }
    }

        update event;
    }

    static void handleUpdateDealDesk(Slack.InboundRequest inboundRequest) {

        Commercial_Account_Hold__c dd = [SELECT Id, Status__c FROM Commercial_Account_Hold__c WHERE Id=: inboundRequest.salesforceId];

        dd.Status__c = inboundRequest?.actions[0]?.selected_option?.value;

        update dd;
    }

}