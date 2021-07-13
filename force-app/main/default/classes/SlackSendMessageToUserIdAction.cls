global class SlackSendMessageToUserIdAction {
    
    @InvocableMethod(label='Send Slack Message to User Id' description='Sends a Slack message to a User if they have a Slack Member Id' category='Slack')
    global static void sendSlackMessageToUserId(List<SlackSendMessageToUserIdActionRequest> requests) {
        sendSlackMessageToUserIdFuture(requests[0].messageText, requests[0].userId);
    }

    // Future callout to get around "no dml before callout" which triggers this action. Ie. process builder
    @future(callout=true)
    global static void sendSlackMessageToUserIdFuture(String messageText, Id userId) {
        SlackLibrary.sendMessageToUserId(messageText, userId);
    }

    global class SlackSendMessageToUserIdActionRequest {
        @InvocableVariable(required=true)
        global String messageText;

        @InvocableVariable(required=true)
        global Id userId;
    }

}