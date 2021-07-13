public class SlackLibrary {
    public static final List<String> REQUIRED_USER_FIELDS = new List<String>{ 'Id', 'Slack_Member_Id__c', 'Slack_App_Channel_Id__c' };

    static SlackApi slackApi = new SlackApi();

    public static Slack.SendMessageResponse sendMessageToChannel(String messageText, String channel) {
        Slack.Message message = buildSimpleTextMessage(messageText);
        return sendMessageToChannel(message, channel);
    }

    public static Slack.SendMessageResponse sendMessageToUserId(String messageText, Id userId) {
        User user = Database.query('SELECT ' + String.join(REQUIRED_USER_FIELDS, ',') + ' FROM User WHERE Id = \'' + userId + '\'');
        return sendMessageToUser(messageText, user);
    }

    public static Slack.SendMessageResponse sendMessageToUser(String messageText, User user) {
        Slack.Message message = buildSimpleTextMessage(messageText);
        return sendMessageToUser(message, user);
    }

    public static Slack.SendMessageResponse sendMessageToUser(Slack.Message message, User user) {
        Boolean updateUser = false;
        if(user.Slack_App_Channel_Id__c == null) {
            if(user.Slack_Member_Id__c == null) {
                return null;
            }
            Slack.OpenChannelResponse response = slackApi.openChannelBetweenAppBotAndSlackMember(user.Slack_Member_Id__c);
            if (response.channel.id != null){
                System.debug(response.channel.id);
                user.Slack_App_Channel_Id__c = response.channel.id;
                updateUser = true;
            }
           
        }

        Slack.SendMessageResponse response = sendMessageToChannel(message, user.Slack_App_Channel_Id__c);

        // update the user after all callouts per Salesforce limits
        if(updateUser) {
            update user;
        }

        return response;
    }

    public static Slack.SendMessageResponse sendMessageToChannel(Slack.Message message, String channel) {
        message.channel = channel;
        return slackApi.postMessage(message);
    }

    public static Slack.SendMessageResponse sendMessageToChannelOptions(Slack.MessageOptions message, String channel) {
        message.channel = channel;
        return slackApi.postMessageOption(message);
    }

    public static String getChannel(String channelName){
        return slackApi.getPrivateChannel(channelName);
    }

    public static String getPublicChannel(String channelName){
        return slackApi.getPublicChannel(channelName);
    }

    public static void replyToHook(String endpoint, Boolean replaceOriginal, String text, String responseType) {
        slackApi.replyToHook(endpoint, replaceOriginal, text, responseType);
    }

    public static Slack.Message buildSimpleTextMessage(String slackMessage) {
        Slack.TextObject textObject = new Slack.TextObject('mrkdwn', slackMessage);
        Slack.Block block = new Slack.Block('section', null, null, textObject, null);
        return new Slack.Message(null, new List<Slack.Block>{ block });
    }

    public static Slack.MessageOptions buildSimpleTextMessageOptions(String slackMessage) {
        Slack.TextObject textObject = new Slack.TextObject('mrkdwn', slackMessage);
        Slack.BlockOption block = new Slack.BlockOption('section', null, null, textObject, null, null);
        return new Slack.MessageOptions(null, new List<Slack.BlockOption>{ block });
    }

}