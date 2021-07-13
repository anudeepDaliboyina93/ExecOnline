@isTest
public class SlackApiHandlerTest {

    @TestSetup
    static void makeData(){
        insert new SlackAPI__c(Signing_Secret__c = 'test', Signing_Version__c = 'v0');
    }

    @isTest
    static void testEventStatusAction() {
        
        Event e = new Event(DurationInMinutes=60, ActivityDateTime = System.now(), Status__c = 'Scheduled', Subject = 'test');
        insert e;

        Slack.InboundRequest slackReq = new Slack.InboundRequest();
        slackReq.response_url = 'https://test.slack.com/api';
        Slack.BlockElement el = new Slack.BlockElement(null, null, null, 'Completed', 'eventStatusAction:' + e.Id);
        slackReq.actions = new List<Slack.BlockElement>{ el };

        String payload = JSON.serialize(slackReq);
        Decimal timeStamp = System.now().addMinutes(-1).getTime() * .001;

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/slack';  
        req.addHeader('httpMethod', 'POST');
        req.addHeader('X-Slack-Request-Timestamp', String.valueOf(timeStamp));
        req.addHeader('X-Slack-Signature', SlackApiHandler.getSlackSignature(String.valueOf(timeStamp), 'payload='+ EncodingUtil.urlEncode(payload, 'UTF-8')));
        req.addParameter('payload', payload);

        RestContext.request = req;

        Test.startTest();
        SlackApiHandler.handlePost();
        Test.stopTest();

        e = [SELECT Id, Status__c FROM Event WHERE Id = :e.Id LIMIT 1];
        System.assertEquals('Completed', e.Status__c);
    }

    @isTest
    static void testEventSELedAction() {

        Account acc = TestDataFactory.getAccount();

        insert acc;

        Opportunity opp = TestDataFactory.getNewBusinessOpportunity(acc.Id);

        insert opp;
        
        Event e = new Event(DurationInMinutes=60, ActivityDateTime = System.now(), Status__c = 'Scheduled', Subject = 'test', WhatId = opp.Id);
        insert e;

        Slack.InboundRequest slackReq = new Slack.InboundRequest();
        slackReq.response_url = 'https://test.slack.com/api';
        Slack.BlockElement el = new Slack.BlockElement(null, null, null, 'Yes', 'eventSELedAction:' + e.Id);
        slackReq.actions = new List<Slack.BlockElement>{ el };

        String payload = JSON.serialize(slackReq);
        Decimal timeStamp = System.now().addMinutes(-1).getTime() * .001;

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/slack';  
        req.addHeader('httpMethod', 'POST');
        req.addHeader('X-Slack-Request-Timestamp', String.valueOf(timeStamp));
        req.addHeader('X-Slack-Signature', SlackApiHandler.getSlackSignature(String.valueOf(timeStamp), 'payload='+ EncodingUtil.urlEncode(payload, 'UTF-8')));
        req.addParameter('payload', payload);

        RestContext.request = req;

        Test.startTest();
        SlackApiHandler.handlePost();
        Test.stopTest();

        e = [SELECT Id, SE_Led__c FROM Event WHERE Id = :e.Id LIMIT 1];
        System.assertEquals('Yes', e.SE_Led__c);
    }

    @isTest
    static void testDealDeskAction() {

        Account acc = TestDataFactory.getAccount();

        insert acc;

        Opportunity opp = TestDataFactory.getNewBusinessOpportunity(acc.Id);

        insert opp;
        
        Commercial_Account_Hold__c dd = new Commercial_Account_Hold__c();

        dd.Account__c = acc.Id;
        dd.Opportunity__c = opp.Id;
        dd.Query__c = 'Test Deal Desk';
        dd.CAR_Type__c = 'Pricing';

        insert dd;

        Slack.InboundRequest slackReq = new Slack.InboundRequest();
        slackReq.response_url = 'https://test.slack.com/api';
        Slack.BlockElement el = new Slack.BlockElement(null, null, null, 'Yes', 'updateDealDesk:' + dd.Id);
        slackReq.actions = new List<Slack.BlockElement>{ el };

        String payload = JSON.serialize(slackReq);
        Decimal timeStamp = System.now().addMinutes(-1).getTime() * .001;

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/slack';  
        req.addHeader('httpMethod', 'POST');
        req.addHeader('X-Slack-Request-Timestamp', String.valueOf(timeStamp));
        req.addHeader('X-Slack-Signature', SlackApiHandler.getSlackSignature(String.valueOf(timeStamp), 'payload='+ EncodingUtil.urlEncode(payload, 'UTF-8')));
        req.addParameter('payload', payload);

        RestContext.request = req;

        Test.startTest();
        SlackApiHandler.handlePost();
        SlackApi sa = new SlackApi();
        sa.getPrivateChannel('deal-desk');
        sa.getPublicChannel('deal-desk');
        Test.stopTest();
    }

}