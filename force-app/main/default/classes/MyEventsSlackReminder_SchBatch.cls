public class MyEventsSlackReminder_SchBatch implements Schedulable, Database.Batchable<sObject>, Database.AllowsCallouts {

    public void execute(SchedulableContext sc) {
        MyEventsSlackReminder_SchBatch b = new MyEventsSlackReminder_SchBatch();
        // Max callouts per transaction is 10
        // Potentially 2 callouts per Slack message, 1 for getting Slack channel and 1 for sending message
        Database.executeBatch(b, 5);
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        Datetime rightNow = System.now();
        Datetime oneHourAgo = rightNow.addMinutes(-60);

        String query = 'SELECT Id, Subject, SE_led__c, OwnerId, WhatId FROM Event WHERE EndDateTime > :oneHourAgo AND EndDateTime < :rightNow AND Status__c = \'Scheduled\'';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Event> events) {
        Map<Id, User> ownerUserMap = getOwnerUserMap(events);
        Set<Id> eventOpportunityMap = new Set<Id>();

        for (Event event : events){

            if (event.WhatId != null){

                Schema.SObjectType sobjectType = event.WhatId.getSObjectType();
                String sobjectName = sobjectType.getDescribe().getName();

                if (sobjectName == 'Opportunity'){

                    eventOpportunityMap.add(event?.WhatId);

                }
            }  
        }

        Map<Id, Opportunity> opps = new Map<Id, Opportunity>([SELECT Id, Name FROM Opportunity WHERE Id IN: eventOpportunityMap]);

        for(Event event : events) {

            //Build and send SE Led Message if SE Led is null
            if(event.SE_led__c == null){
      
                List<Slack.Block> seLedBlocks = new List<Slack.Block>();
                if (opps?.get(event.WhatId) != null){

                    String seLedMessage = 'Looks like SE Led has not been filled out for your meeting "'+ opps?.get(event.WhatId)?.Name + '" "' + event.Subject + '"\nIs this SE Led?';
                    seLedBlocks.add(new Slack.Block('section', null, null, new Slack.TextObject('plain_text', seLedMessage), null));
    
                    seLedBlocks.add(new Slack.Block('actions', 'eventSELedAction', event.Id, null, new List<Slack.BlockElement>{ 
                        new Slack.BlockElement('button', new Slack.TextObject('plain_text', 'Yes'), 'primary', 'Yes', null), 
                        new Slack.BlockElement('button', new Slack.TextObject('plain_text', 'No'), 'danger', 'No', null)
                        }));
        
                        Slack.Message slackSELedMessage = new Slack.Message(null, seLedBlocks);
                        SlackLibrary.sendMessageToUser(slackSELedMessage, ownerUserMap.get(event.OwnerId));
                }

                else {String seLedMessage = 'Looks like SE Led has not been filled out for your meeting "' + event.Subject + '"\nIs this SE Led?';
            
                seLedBlocks.add(new Slack.Block('section', null, null, new Slack.TextObject('plain_text', seLedMessage), null));
    
                seLedBlocks.add(new Slack.Block('actions', 'eventSELedAction', event.Id, null, new List<Slack.BlockElement>{ 
                    new Slack.BlockElement('button', new Slack.TextObject('plain_text', 'Yes'), 'primary', 'Yes', null), 
                    new Slack.BlockElement('button', new Slack.TextObject('plain_text', 'No'), 'danger', 'No', null)
                    }));
    
                    Slack.Message slackSELedMessage = new Slack.Message(null, seLedBlocks);
                    SlackLibrary.sendMessageToUser(slackSELedMessage, ownerUserMap.get(event.OwnerId));
            }
             
                } 

            List<Slack.Block> blocks = new List<Slack.Block>();

            if (opps?.get(event.WhatId) != null){

                String messageText = 'Looks like your meeting "'+ opps?.get(event.WhatId)?.Name + '" "' + event.Subject + '", concluded recently.\nDo you want to update the status?';

                blocks.add(new Slack.Block('section', null, null, new Slack.TextObject('plain_text', messageText), null));
                
                blocks.add(new Slack.Block('actions', 'eventStatusAction', event.Id, null, new List<Slack.BlockElement>{ 
                    new Slack.BlockElement('button', new Slack.TextObject('plain_text', 'Completed'), 'primary', 'Completed', null), 
                    new Slack.BlockElement('button', new Slack.TextObject('plain_text', 'Canceled'), 'danger', 'Canceled', null)
                }));
    
                Slack.Message message = new Slack.Message(null, blocks);
                SlackLibrary.sendMessageToUser(message, ownerUserMap.get(event.OwnerId));

            }

            else {

                String messageText = 'Looks like your meeting "' + event.Subject + '", concluded recently.\nDo you want to update the status?';

                blocks.add(new Slack.Block('section', null, null, new Slack.TextObject('plain_text', messageText), null));
                
                blocks.add(new Slack.Block('actions', 'eventStatusAction', event.Id, null, new List<Slack.BlockElement>{ 
                    new Slack.BlockElement('button', new Slack.TextObject('plain_text', 'Completed'), 'primary', 'Completed', null), 
                    new Slack.BlockElement('button', new Slack.TextObject('plain_text', 'Canceled'), 'danger', 'Canceled', null)
                }));
    
                Slack.Message message = new Slack.Message(null, blocks);
                SlackLibrary.sendMessageToUser(message, ownerUserMap.get(event.OwnerId));

            }

        }
    }

    public Map<Id, User> getOwnerUserMap(List<Event> events) {
        Set<Id> ownerUserIds = new Set<Id>();
        for(Event event : events) {
            ownerUserIds.add(event.OwnerId);
        }
        return new Map<Id, User>((List<User>)Database.query('SELECT ' + String.join(SlackLibrary.REQUIRED_USER_FIELDS, ',') + ' FROM User WHERE Id IN :ownerUserIds'));
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('Finished MyEventsSlackReminder_SchBatch');
    }
}