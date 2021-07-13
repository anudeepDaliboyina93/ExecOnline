global class DealDeskScheduledSummary implements Schedulable{
    global void execute (SchedulableContext ctx){

        String channelName;

        Map<String, Slack_Channel__mdt> channelMap = Slack_Channel__mdt.getAll();

        for (Slack_Channel__mdt channel : channelMap.values()){
            if (channel.DeveloperName == 'Deal_Desk'){

                channelName = channel.Channel_Name__c;
            }
        }

        Set<String> leftOverStatuses = new Set<String>{'Requested','Pending'};
        List<Slack.BlockOption> blocks = new List<Slack.BlockOption>();

        List<Commercial_Account_Hold__c> leftOverDealDeskItems = [SELECT Id, Account_Name__c, Opportunity_Name__c, CAR_Type__c, Query__c, Status__c FROM Commercial_Account_Hold__c WHERE Status__c IN:leftOverStatuses AND CreatedDate = TODAY];

        blocks.add(new Slack.BlockOption('header', null, null, new Slack.TextObject('plain_text', ':city_sunset: Todays Deal Desk Items Still Open!'), null, null));
        blocks.add(new Slack.BlockOption('divider', 'dividerBlock1', null, null, null, null));

        for (Commercial_Account_Hold__c dd : leftOverDealDeskItems){

            List<Slack.TextObject> fields = new List<Slack.TextObject>();
            List<Slack.TextObject> urlfield = new List<Slack.TextObject>();
   
            String accountName     = dd.Account_Name__c;
            String opportunityName = dd.Opportunity_Name__c;
            String topic           = dd.CAR_Type__c;
            String URLString       = '<' + URL.getOrgDomainUrl().toExternalForm() + '/' + dd.Id + ' | ' + accountName + ' - Open Deal Desk Request>';

            Slack.TextObject accountInfo     = new Slack.TextObject('mrkdwn', 'Account: \n ' + accountName);
            fields.add(accountInfo);
            Slack.TextObject oppInfo         = new Slack.TextObject('mrkdwn', 'Opportunity: \n ' + opportunityName);
            fields.add(oppInfo);
            Slack.TextObject topicInfo       = new Slack.TextObject('mrkdwn', 'Topic: \n ' + topic);
            fields.add(topicInfo);
            Slack.TextObject descriptionInfo = new Slack.TextObject('mrkdwn', 'Description: \n ' + dd.Query__c);
            fields.add(descriptionInfo);
            Slack.TextObject urlblock        = new Slack.TextObject('mrkdwn', ':exclamation: This deal desk request is still open! :exclamation: \n ' + URLString);
            urlfield.add(urlblock);

            blocks.add(new Slack.BlockOption('section', 'URLblock'+dd.Id, null, null, null, urlfield));
            blocks.add(new Slack.BlockOption('section', 'fieldsBlock'+dd.Id, null, null, null, fields));
            blocks.add(new Slack.BlockOption('actions', 'updateDealDesk', dd.Id, null, new List<Slack.BlockElementOptions>{ 
                new Slack.BlockElementOptions('static_select', new Slack.OptionObject(dd.Status__c != null ? dd.Status__c : 'Select Status', 'status__c', statusOptions(dd)), null) 
                }, null));
            blocks.add(new Slack.BlockOption('divider', 'dividerBlock'+dd.Id, null, null, null, null));
        }

        if (!leftOverDealDeskItems.isEmpty()){

            Slack.MessageOptions message = new Slack.MessageOptions(null, blocks);

            System.enqueueJob(new getChannelId(message, channelName));
        }
    
    }

    List<Slack.options> statusOptions(Commercial_Account_Hold__c dd){
           
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