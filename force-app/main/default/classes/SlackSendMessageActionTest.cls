@isTest
public class SlackSendMessageActionTest {
    
    @isTest
    static void testSlackSendMessageToChannel() {
        SlackSendMessageToChannelAction.SlackSendMessageToChannelActionRequest request = new SlackSendMessageToChannelAction.SlackSendMessageToChannelActionRequest();
        request.messageText = 'testMessage';
        request.channel = 'testChannel';
        SlackSendMessageToChannelAction.sendSlackMessageToChannel(new List<SlackSendMessageToChannelAction.SlackSendMessageToChannelActionRequest>{ request });
    
        // nothing to assert
    }

    @isTest
    static void testSlackSendMessageToUserId() {
        SlackSendMessageToUserIdAction.SlackSendMessageToUserIdActionRequest request = new SlackSendMessageToUserIdAction.SlackSendMessageToUserIdActionRequest();
        request.messageText = 'testMessage';
        request.userId = UserInfo.getUserId();
        SlackSendMessageToUserIdAction.sendSlackMessageToUserId(new List<SlackSendMessageToUserIdAction.SlackSendMessageToUserIdActionRequest>{ request });

        // nothing to assert
    }


}