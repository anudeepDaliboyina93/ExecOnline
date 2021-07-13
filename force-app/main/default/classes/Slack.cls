public class Slack {

    /**
    * Sub classes for building Slack requests and handling responses
    */

    // https://api.slack.com/reference/messaging/payload
    public class Message {
        // channel a required parameter for web api
        public String channel {get;set;}
        public List<Block> blocks {get;set;}

        public Message(String channel, List<Block> blocks) {
            this.channel = channel;
            this.blocks = blocks;
        }
    }

    public class MessageOptions {
        // channel a required parameter for web api
        public String channel {get;set;}
        public List<BlockOption> blocks {get;set;}

        public MessageOptions(String channel, List<BlockOption> blocks) {
            this.channel = channel;
            this.blocks = blocks;
        }
    }

    // https://api.slack.com/reference/block-kit/blocks
    public class Block {
        public String type {get;set;}
        public String block_id {get;set;}
        public TextObject text {get;set;}
        public List<BlockElement> elements {get;set;}

        public Block(String type, String block_id_action, Id block_id_salesforceId, TextObject text, List<BlockElement> elements) {
            this.type = type;
            // concat the block_id of event action type and the related Salesforce record Id
            // this is to parse when a user responds in Slack and receive instance information on 
            // action being performed and the related Salesforce Id
            this.block_id = block_id_action;
            this.block_id += block_id_salesforceId == null ? '' : ':' + block_id_salesforceId;
            this.text = text;
            this.elements = elements;
        }
    }

    public class BlockOption {
        public String type {get;set;}
        public String block_id {get;set;}
        public TextObject text {get;set;}
        public List<BlockElementOptions> elements {get;set;}
        public List<TextObject> fields {get;set;}

        public BlockOption(String type, String block_id_action, Id block_id_salesforceId, TextObject text, List<BlockElementOptions> elements, List<TextObject> fields) {
            this.type = type;
            // concat the block_id of event action type and the related Salesforce record Id
            // this is to parse when a user responds in Slack and receive instance information on 
            // action being performed and the related Salesforce Id
            this.block_id = block_id_action;
            this.block_id += block_id_salesforceId == null ? '' : ':' + block_id_salesforceId;
            this.text = text;
            this.elements = elements;
            this.fields = fields;
        }
    }

    public class SelectedObject {
        public TextObject text {get;set;}
        public String value {get;set;}

        public SelectedObject(TextObject text, String value){
            this.text = text;
            this.value = value;
        }
    }

    // https://api.slack.com/reference/block-kit/block-elements
    public class BlockElement {
        public String type {get;set;}
        public TextObject text {get;set;}
        public String style {get;set;}
        public String value {get;set;}
        public String block_id {get;set;}
        public SelectedObject selected_option {get;set;}

        public BlockElement(String type, TextObject text, String style, String value, String block_id) {
            this.type = type;
            this.text = text;
            this.style = style;
            this.value = value;
            this.block_id = block_id;
        }
    }

    public class BlockElementOptions {
        public String type {get;set;}
        public OptionObject text {get;set;}
        public TextObject placeholder {get;set;}
        public List<options> options {get;set;}
        public String value {get;set;}
        public String action_id {get;set;}
        public String block_id {get;set;}

        public BlockElementOptions(String type, OptionObject text, String action_id) {
            this.type = type;
            this.placeholder = text.placeholder;
            this.options = text.options;
            this.action_id = action_id;
            
        }
    }

    // https://api.slack.com/reference/block-kit/composition-objects#text
    public class TextObject {
        public String type {get;set;}
        public String text {get;set;}

        public TextObject(String type, String text) {
            this.type = type;
            this.text = text;
        }
    }

    public class OptionObject {
        public TextObject placeholder {get;set;}
        public String action_id {get;set;}
        public List<options> options {get;set;}

        public OptionObject(String placeholder, String action_id, List<options> options){
            this.placeholder = new TextObject('plain_text', placeholder);
            this.action_id   = action_id;
            this.options     = options;

        }

    }

    public class options {
        public TextObject text {get;set;}
        public String value {get;set;}

        public options(TextObject text, String value){
            this.text  = text;
            this.value = value;
        }

    }

    // Responses
    // https://api.slack.com/web#responses
    public class OpenChannelResponse {
        public Boolean ok {get;set;}
        public Channel channel {get;set;}
    }
    public class Channel {
        public String id {get;set;}
        public String name {get;set;}
    }

    public class SendMessageResponse {
        public Boolean ok {get;set;}
        public String stuff {get;set;}
        public String warning {get;set;}
        public String error {get;set;}
        public String channel {get;set;}
        public List<Channel> channels {get;set;}
    }

    // https://api.slack.com/interactivity/handling#payloads
    // https://api.slack.com/reference/interaction-payloads/block-actions
    public class InboundRequest {
        public String api_app_id {get;set;}
        public String response_url {get;set;}
        public List<BlockElement> actions {get;set;}

        public String blockAction {get;set;}
        public String salesforceId {get;set;}

        public void parseBlockId() {
            if(actions.size() == 1) {
                List<String> blockIds = this.actions[0].block_id.split(':');
                this.blockAction = blockIds[0];
                this.salesforceId = blockIds.size() > 1 ? blockIds[1] : null;
            }
        }
    }

}