@isTest
public class SlackLibraryTest {
    
    @isTest
    static void testSendMessageToChannel() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SlackMockResponse());
        SlackApi.isTesting = true;
        Slack.SendMessageResponse response = SlackLibrary.sendMessageToChannel('testMessage', 'testChannel');
        Slack.SendMessageResponse optionsResponse = SlackLibrary.sendMessageToChannelOptions(SlackLibrary.buildSimpleTextMessageOptions('testMessage'), 'testChannel');
        Test.stopTest();

        System.assert(response.ok);
    }
    
    @isTest
    static void testSendMessageToUserId() {
        User myUser = new User(Id = UserInfo.getUserId(), Slack_App_Channel_Id__c = null, Slack_Member_Id__c = 'test');
        update myUser;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SlackMockResponse());
        SlackApi.isTesting = true;
        Slack.SendMessageResponse response = SlackLibrary.sendMessageToUserId('testMessage', myUser.Id);
        Test.stopTest();

        System.assert(response.ok);
    }

    public class SlackMockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            String mockBody;
            if(req.getEndpoint().contains('chat.postMessage')) {
                Slack.SendMessageResponse mockResponse = new Slack.SendMessageResponse();
                mockResponse.ok = true;
                mockResponse.channel = 'mockChannel';

                mockBody = JSON.serialize(mockResponse);
            } else if(req.getEndpoint().contains('conversations.open')) {
                Slack.Channel mockChannel = new Slack.Channel();
                mockChannel.id = 'mockChannel';

                Slack.OpenChannelResponse mockResponse = new Slack.OpenChannelResponse();
                mockResponse.ok = true;
                mockResponse.channel = mockChannel;

                mockBody = JSON.serialize(mockResponse);
            }

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(mockBody);
            res.setStatusCode(200);
            return res;
        }
    }
}