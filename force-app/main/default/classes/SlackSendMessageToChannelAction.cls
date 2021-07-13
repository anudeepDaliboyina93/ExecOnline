global class SlackSendMessageToChannelAction {
    
    @InvocableMethod(label='Send Slack Message to Channel' description='Sends a Slack message to a Slack channel' category='Slack')
    global static void sendSlackMessageToChannel(List<SlackSendMessageToChannelActionRequest> requests) {
        sendSlackMessageToChannelFuture(requests[0].messageText, requests[0].channel);
    }

    // Future callout to get around "no dml before callout" which triggers this action. Ie. process builder
    @future(callout=true)
    global static void sendSlackMessageToChannelFuture(String messageText, String channel) {
        SlackLibrary.sendMessageToChannel(messageText, channel);
    }

    global class SlackSendMessageToChannelActionRequest {
        @InvocableVariable(required=true)
        global String messageText;

        @InvocableVariable(required=true)
        global String channel;
    }

}