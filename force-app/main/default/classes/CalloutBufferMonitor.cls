global class CalloutBufferMonitor implements Schedulable {

    global void execute(SchedulableContext context) {
        System.Debug('Running CalloutBufferMonitor');
        System.abortJob(context.getTriggerId());
        System.schedule('CalloutBufferMonitor ' + String.valueOf(Datetime.now()), '0 '+DateTime.now().addMinutes(2).minute()+' */1 ? * *', this);

        Callout_Buffer_Configuration__c cbconfig = Callout_Buffer_Configuration__c.getInstance(); 
        Decimal warningThreshold = cbconfig.Seconds_in_Queue_Warning_Threshold__c;
        if (warningThreshold==null) {
            warningThreshold=999999;
        }
        List<Callout_Buffer_Item__c> cbis = [SELECT 
            Id, CreatedDate, Status__c, Initial_Response_Status_Code__c, Initial_Response_Timestamp__c, Last_Response_Status_Code__c, Last_Response_Timestamp__c, 
            Processing_Time__c, Retry_Attempts__c, seconds_in_queue__c, alert_sent__c, Time_In_Queue__c, initial_response_code__c 
            FROM Callout_Buffer_Item__c 
            //WHERE CreatedDate > :Datetime.now().addMinutes(-60)
            ORDER BY CreatedDate DESC
            LIMIT 1
            ];
        if (cbis[0].Seconds_in_Queue__c>warningThreshold && cbis[0].alert_sent__c == null) {
            emailAlert(cbis[0].Id);  
            cbis[0].alert_sent__c = System.now();
            update cbis[0];     
        }
    }
    
    public void emailAlert(Id cbiId) {
        //Apex can't use WhatId when sending to a User, only to Leads/Contacts
        //Workaround is create a Lead for this email and then delete it
        Id userId = '005F00000063Cd6';
        User user = [select email, firstName, lastName from User where id = :userId];
        Lead tempLead = new Lead(email = user.email, company='Acme', firstName = user.firstName, lastName = user.lastName);
        insert tempLead;
        
        Id templateId = [SELECT Id from EmailTemplate where Name = 'CBI Monitor'].Id;       
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTargetObjectId(tempLead.id); 
        mail.setTemplateId(templateId);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setSenderDisplayName('ExecOnline SFDC Callout Buffer');
        mail.setSaveAsActivity(false); 
        mail.setWhatId(cbiId); 
        if (!Test.isRunningTest()) {
          Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        delete tempLead;
    }

 }