public with sharing class DealDeskHandler extends TriggerHandler{

    public override void afterInsert(Map<Id, SObject> newItemMap) {

        List<Commercial_Account_Hold__c> newDealDeskRecords = newItemMap.values();
        String channelName = Slack_Channel__mdt.getInstance('Deal_Desk').Channel_Name__c;

        for (Commercial_Account_Hold__c dd : newDealDeskRecords){

            List<Slack.BlockOption> blocks  = new List<Slack.BlockOption>();
            List<Slack.TextObject> fields   = new List<Slack.TextObject>();
            List<Slack.TextObject> urlfield = new List<Slack.TextObject>();
   
            String accountName     = dd.Account_Name__c;
            String accountOwner    = dd.Account_Owner__c;
            String opportunityName = dd.Opportunity_Name__c;
            String topic           = dd.CAR_Type__c;
            String URLString       = '<' + URL.getOrgDomainUrl().toExternalForm() + '/' + dd.Id + ' | ' + accountName + ' - New Deal Desk Request>';

            Slack.TextObject accountInfo     = new Slack.TextObject('mrkdwn', 'Account: \n ' + accountName);
            fields.add(accountInfo);
            Slack.TextObject ownerInfo       = new Slack.TextObject('mrkdwn', 'Account Owner: \n ' + accountOwner);
            fields.add(ownerInfo);
            Slack.TextObject oppInfo         = new Slack.TextObject('mrkdwn', 'Opportunity: \n ' + opportunityName);
            fields.add(oppInfo);
            Slack.TextObject topicInfo       = new Slack.TextObject('mrkdwn', 'Topic: \n ' + topic);
            fields.add(topicInfo);
            Slack.TextObject descriptionInfo = new Slack.TextObject('mrkdwn', 'Description: \n ' + dd.Query__c);
            fields.add(descriptionInfo);
            Slack.TextObject urlblock        = new Slack.TextObject('mrkdwn', ':boom: There is a new deal desk request! :boom: \n ' + URLString);
            urlfield.add(urlblock);

            blocks.add(new Slack.BlockOption('section', 'URLblock', null, null, null, urlfield));
            blocks.add(new Slack.BlockOption('section', 'fieldsBlock', null, null, null, fields));
            blocks.add(new Slack.BlockOption('actions', 'updateDealDesk', dd.Id, null, new List<Slack.BlockElementOptions>{ 
                new Slack.BlockElementOptions('static_select', new Slack.OptionObject(dd.Status__c != null ? dd.Status__c : 'Select Status', 'status__c', getStatusOptions(dd)), null) 
                }, null));
    
            Slack.MessageOptions message = new Slack.MessageOptions(null, blocks);

            System.enqueueJob(new getChannelId(message, channelName));
            

         }

       }

       public List<Slack.options> getStatusOptions(Commercial_Account_Hold__c dd){
           
           List<Slack.options>       options         = new List<Slack.options>();
           Map<String, List<String>> dependentValues = ApexUtility.getDependentPicklistValues(Commercial_Account_Hold__c.Status__c);

           for (String picklistValue : dependentValues.keySet()){
               if (picklistValue == dd.CAR_Type__c){
                   for (String value : dependentValues.get(picklistValue)){

                    Slack.TextObject textObj = new Slack.TextObject('plain_text', value);
                    Slack.options    opt     = new Slack.options(textObj, value);
 
                    options.add(opt);
                   }
                  
               }
           }

          return options;
       }

    class getChannelId implements Queueable, Database.AllowsCallouts{

        private String channelName {get;set;}
        private  Slack.MessageOptions message {get;set;}
    
        public getChannelId( Slack.MessageOptions message, String channelName){
            this.message = message;
            this.channelName = channelName;
        }

        public void execute(QueueableContext qc){
            String channelId = SlackLibrary.getChannel(channelName);

            if(!Test.isRunningTest()) {
            System.enqueueJob(new sendMessageToChannelOptions(message, channelId));
            }
        }
    }

    class sendMessageToChannelOptions implements Queueable, Database.AllowsCallouts{

        private Slack.MessageOptions message {get;set;}
        private String channelId {get;set;}

        public sendMessageToChannelOptions(Slack.MessageOptions message, String channelId){
            this.message   = message;
            this.channelId = channelId;
        }

        public void execute(QueueableContext qc){

            SlackLibrary.sendMessageToChannelOptions(message, channelId);
        }
    }
}