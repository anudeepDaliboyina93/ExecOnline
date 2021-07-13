public class SlackApi {

    // https://api.slack.com/web
    // Sub classes should be used to create request params
    // Requests should be routed through the SlackLibrary for actual callouts

    // Refer to https://api.slack.com/reference/surfaces/formatting
    // for markdown "mrkdwn" formatting guidelines

    public static SlackAPI__c apiSettings = SlackAPI__c.getInstance();

    @testVisible
    private static Boolean isTesting = false;

    private Boolean shouldSendRequest() {
        return (Test.isRunningTest() && isTesting) || (!Test.isRunningTest() && apiSettings.Is_Active__c);
    }

    // method to handle sending all slack requests
    public HTTPResponse sendRequest(String httpMethod, String apiEndpoint, String requestBody) {
        HttpRequest req = new HttpRequest();

        req.setEndpoint(apiEndpoint);
        req.setMethod(httpMethod);
        req.setHeader('Content-Type', 'application/json;charset=utf-8');
        req.setHeader('Authorization', 'Bearer ' + apiSettings.Bot_User_Token__c);
        req.setBody(requestBody);
        if(shouldSendRequest()) {
            return new Http().send(req);
        }
        return null;
    }

    public HTTPResponse sendRequestUrlEncoded(String httpMethod, String apiEndpoint, String requestBody) {
        HttpRequest req = new HttpRequest();

        req.setEndpoint(apiEndpoint);
        req.setMethod(httpMethod);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Authorization', 'Bearer ' + apiSettings.Bot_User_Token__c);
        req.setBody(requestBody);
        if(shouldSendRequest()) {
            return new Http().send(req);
        }
        return null;
    }

    // https://api.slack.com/methods/chat.postMessage
    public Slack.SendMessageResponse postMessage(Slack.Message message) {
        HTTPResponse res = sendRequest('POST', apiSettings.API_Base_URL__c + 'chat.postMessage', JSON.serialize(message, true));
        if(res != null) {
            return (Slack.SendMessageResponse)JSON.deserialize(res.getbody(), Slack.SendMessageResponse.class);
        }
        return null;
    }

    public Slack.SendMessageResponse postMessageOption(Slack.MessageOptions message) {
        HTTPResponse res = sendRequest('POST', apiSettings.API_Base_URL__c + 'chat.postMessage', JSON.serialize(message, true));
       
        if(res != null) {
            return (Slack.SendMessageResponse)JSON.deserialize(res.getbody(), Slack.SendMessageResponse.class);
        }
        return null;
    }

    public String getPrivateChannel(String channelName){

        String payload = 'types='+EncodingUtil.urlEncode('private_channel', 'UTF-8')+'&exclude_archived='+EncodingUtil.urlEncode('true', 'UTF-8');

        HTTPResponse res = sendRequestUrlEncoded('GET', apiSettings.API_Base_URL__c + 'conversations.list', payload);
        if(res != null) {
            Slack.SendMessageResponse messageResponse = (Slack.SendMessageResponse)JSON.deserialize(res.getbody(), Slack.SendMessageResponse.class);

            for (Slack.Channel channel : messageResponse.channels){

                if (channel.name == channelName){
                    return channel.id;
                }
            }
return null;
           
        }
        return null;
    }

    public String getPublicChannel(String channelName){

        String payload = 'types='+EncodingUtil.urlEncode('public_channel', 'UTF-8')+'&exclude_archived='+EncodingUtil.urlEncode('true', 'UTF-8');

        HTTPResponse res = sendRequestUrlEncoded('GET', apiSettings.API_Base_URL__c + 'conversations.list', payload);
        if(res != null) {
            Slack.SendMessageResponse messageResponse = (Slack.SendMessageResponse)JSON.deserialize(res.getbody(), Slack.SendMessageResponse.class);

            for (Slack.Channel channel : messageResponse.channels){

                if (channel.name == channelName){
                    return channel.id;
                }
            }
return null;
           
        }
        return null;
    }

    // https://api.slack.com/methods/im.open
    public Slack.OpenChannelResponse openChannelBetweenAppBotAndSlackMember(String slackMemberId) {
        Map<String, String> bodyMap = new Map<String, String> {
            'users' => slackMemberId
        };

        HTTPResponse res = sendRequest('POST', apiSettings.API_Base_URL__c + 'conversations.open', JSON.serialize(bodyMap, true));
        if(res != null) {
            return (Slack.OpenChannelResponse)JSON.deserialize(res.getbody(), Slack.OpenChannelResponse.class);
        }
        return null;
    }

    // https://api.slack.com/interactivity/handling#message_responses
    public Slack.SendMessageResponse replyToHook(String endpoint, Boolean replaceOriginal, String text, String responseType) {
        Map<String, String> message = new Map<String, String>{
            'replace_original' => String.valueOf(replaceOriginal),
            'text' => text,
            'response_type' => responseType
        };
        HTTPResponse res = sendRequest('POST', endpoint, JSON.serialize(message, true));
        if(res != null) {
            return (Slack.SendMessageResponse)JSON.deserialize(res.getbody(), Slack.SendMessageResponse.class);
        }
        return null;
    }

}