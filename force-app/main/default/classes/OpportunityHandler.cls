/**
 * OpportunityHandler.cls
 * Copyright 2015 Wired Triangle, LLC
 * http://www.wiredtriangle.com
 */
global with sharing class OpportunityHandler implements ITrigger {

    private CalloutBuffer.ObjectsToEnqueueWrapper objectsToEnqueue = new CalloutBuffer.ObjectsToEnqueueWrapper();
	private Set<Id> accountsToCalculateEpc = new Set<Id>();
    global static TriggerConfiguration__c triggerConfig = TriggerConfiguration__c.getInstance();
    global static Boolean enableAutoCalculateEPCUtilization = triggerConfig.Enable_Auto_Calculate_EPC_Utilization__c;
    private Map<Id, Opportunity> newWinOppsMap = new Map<Id, Opportunity>();
    global static Boolean provisionedEpcsInserted = false;
    public static Boolean newLogoLogicRan = false;
    private Set<Id> oppsChanged = new Set<Id>();
    private Map<Id, Decimal> syncEPCToOpp = new Map<Id, Decimal>();
    String channelName = Slack_Channel__mdt.getInstance('general').Channel_Name__c;
    public static boolean firstRun = true;
																											   
    public void bulkBefore() {
    }

    public void bulkAfter() {
    }

    public void beforeInsert(SObject so) {


    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        Opportunity opportunity = (Opportunity)so;
        Opportunity oldOpportunity = (Opportunity)oldSo;

        if (opportunity.isWon && !oldOpportunity.isWon) {
            newWinOppsMap.put(opportunity.Id, opportunity);
        }

        else if (!opportunity.isWon && oldOpportunity.isWon){
            oppsChanged.add(opportunity.Id);
            accountsToCalculateEpc.add(opportunity.AccountId);
        }

        if (epcRollupChanged(opportunity, oldOpportunity)){
            syncEPCToOpp.put(opportunity.Id, opportunity.EPCs_Purchased_roll_up__c);
            accountsToCalculateEpc.add(opportunity.AccountId);
        }

    }

    public void beforeDelete(SObject so) {

    }

    public void beforeUnDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
        Opportunity opportunity = (Opportunity)so;
        enqueue(opportunity, 'POST');
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        Opportunity opportunity = (Opportunity)so;
        Opportunity oldOpportunity = (Opportunity)oldSo;
        
        if (opportunity.isWon && !oldOpportunity.isWon) {
            newWinOppsMap.put(opportunity.Id, opportunity);
        }
        if (CalloutBuffer.hasIntegrationFieldChanged(opportunity, oldOpportunity)) {
            enqueue(opportunity, 'PUT');
        }
		if (enableAutoCalculateEPCUtilization &&
			EpcServiceV2.shouldFireEpcCalcFromFieldChange(oldOpportunity, opportunity)) {
			accountsToCalculateEpc.add(oldOpportunity.AccountId);
			accountsToCalculateEpc.add(opportunity.AccountId);
		}
    }

    public void afterDelete(SObject so) {
        Opportunity opportunity = (Opportunity)so;
        enqueue(opportunity, 'DELETE');
    }

    public void afterUnDelete(SObject so) {
        Opportunity opportunity = (Opportunity)so;
        enqueue(opportunity, 'POST');
    }

    public void andFinally() {

        system.debug(oppsChanged.size());
        system.debug(syncEPCToOpp.size());
        if (!objectsToEnqueue.isEmpty()) {
            CalloutBuffer.enqueueObjects(objectsToEnqueue);
        }

        EpcServiceV2 epcHelper = new EpcServiceV2(accountsToCalculateEpc);

        if (!newWinOppsMap.isEmpty()) {
            if(Trigger.isBefore && !newLogoLogicRan) {
                handleNewLogoOpportunities(newWinOppsMap.values());
                newLogoLogicRan = true;
            }
			system.debug('provisionedEpcsInserted--'+provisionedEpcsInserted);
            if(!provisionedEpcsInserted && Trigger.isAfter) {
                epcHelper.insertProvisionedEpcs(newWinOppsMap.values());
                provisionedEpcsInserted=true;
                
            }

        if (Trigger.isAfter && !newWinOppsMap.isEmpty()){
          //  buildAndSendMessage();
        }
				 
        }

        if (!oppsChanged.isEmpty()){

            system.debug('deleting epcu');
            List<EPC_Utilization__c> deleteEPCU = [SELECT Id, Opportunity__c, Type__c FROM EPC_Utilization__c WHERE Opportunity__c IN: oppsChanged AND Type__c = 'Provisioned'];

            if (!deleteEPCU.isEmpty()){

                delete deleteEPCU;
            }
        }

        if (!syncEPCToOpp.isEmpty()){

            List<EPC_Utilization__c> updateEPC = new List<EPC_Utilization__c>();
            List<EPC_Utilization__c> epcsToChange = [SELECT Id, EPCs_Utilized__c, Opportunity__c FROM EPC_Utilization__c WHERE Opportunity__c IN: syncEPCToOpp.keyset() AND Type__c = 'Provisioned'];
system.debug('inside updating epc');
system.debug(epcsToChange.size());
            for (EPC_Utilization__c epc : epcsToChange){

                epc.EPCs_Utilized__c = syncEPCToOpp.get(epc?.Opportunity__c);

                updateEPC.add(epc);
            }

            update updateEPC;
        }

        if (!accountsToCalculateEpc.isEmpty()) {
        	ID jobID = System.enqueueJob(epcHelper);
        }
        

    }

    private void enqueue(SObject so, String action) {
        objectsToEnqueue.actionType = action;
        objectsToEnqueue.objects.add(so);
    }

    private void handleNewLogoOpportunities(List<Opportunity> wonOppsList) {
        Map<String, Decimal> clientSegmentToNewLogoAmountThreshold = new Map<String, Decimal>{
            'Large Enterprise' => 50000,
            'Mid-Market' => 30000
        };

        Set<Id> accountIds = new Set<Id>();
        for(Opportunity opp : wonOppsList) {
            accountIds.add(opp.AccountId);
        }
        Map<Id, Account> accountMap = getAccountsWithThisYearOppsMap(accountIds);

        for(Opportunity opp : wonOppsList) {
            if(hasPreviousNewLogoOpp(accountMap.get(opp.AccountId))) {
                continue;
            }

            Decimal newLogoAmountThreshold = clientSegmentToNewLogoAmountThreshold.get(opp.Client_Segment__c);
            if(ApexUtility.getRecordTypeNameFromId('Opportunity', opp.RecordTypeId) == 'New Business') {
                opp.New_Logo__c = opp.Amount >= newLogoAmountThreshold;
																   
            } else {
                opp.New_Logo__c = doesOppMeetNewLogoThresholdInCalendarYear(opp, accountMap.get(opp.AccountId), newLogoAmountThreshold);
            }
        }
    }

    private Map<Id, Account> getAccountsWithThisYearOppsMap(Set<Id> accountIds) {
        return new Map<Id, Account>([
            SELECT Id, 
                (SELECT Id, Amount, CloseDate, New_Logo__c, RecordType.Name 
                FROM Opportunities 
                WHERE New_Logo__c = true OR
                    (IsWon = true AND CloseDate = THIS_YEAR))
            FROM Account 
            WHERE Id IN :accountIds
        ]);
    }

    private Boolean doesOppMeetNewLogoThresholdInCalendarYear(Opportunity opportunity, Account account, Decimal newLogoAmountThreshold) {
        Boolean hasNewBusinessThisCalendarYear = false;
        Decimal totalAmountThisYear = opportunity.Amount;

        for(Opportunity opp : account.Opportunities) {
            // same calendar year
            if(opportunity.CloseDate.year() == opp.CloseDate.year()) {
                if(opp.RecordType.Name == 'New Business') {
                    hasNewBusinessThisCalendarYear = true;
                }
                totalAmountThisYear += opp.Amount;
            }
        }

																									  
        return hasNewBusinessThisCalendarYear && totalAmountThisYear >= newLogoAmountThreshold;
    }

    private Boolean hasPreviousNewLogoOpp(Account account) {
        for(Opportunity opp : account.Opportunities) {
            if(opp.New_Logo__c) {
                return true;
            }
        }
        return false;
    }

    private Boolean epcRollupChanged(Opportunity opp, Opportunity oldOpp){
        
        return opp.EPCs_Purchased_roll_up__c != oldOpp.EPCs_Purchased_roll_up__c;

    }
    public void buildAndSendMessage(){
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();

        List<Opportunity> opps = [SELECT Id, Owner.Name, Unweighted_Net_Bookings__c FROM Opportunity WHERE Id IN: newWinOppsMap.keySet()];

        for (Opportunity opp : opps){

            oppMap.put(opp.Id, opp);
        }

        for (Opportunity opp : newWinOppsMap.values()){

            if (opp.isWon){

            String ownerName   = oppMap.get(opp.Id).Owner.Name;
            String recTypeName = opp.Opportunity_Record_Type_Name__c;
            String accountName = opp.Account_Name_Text__c;
            String newBookings = opp.Amount.format();

            List<Slack.Block>      blocks   = new List<Slack.Block>();
            List<Slack.TextObject> fields   = new List<Slack.TextObject>();
            String oppMessage = ' Woohoo! ' + ownerName + ' closed a ' + recTypeName + ' deal for $' + newBookings + ' with ' + accountName + '!';

            Slack.TextObject fireworks        = new Slack.TextObject('plain_text', ':hd-firework: :hd-firework: :hd-firework:' );
            Slack.TextObject messageObj        = new Slack.TextObject('plain_text', oppMessage );
           
            blocks.add(new Slack.Block('section', 'closedWonOpp', null, fireworks, null));
            blocks.add(new Slack.Block('section', 'closedWonOppmessage', null, messageObj, null));
           

            Slack.Message message = new Slack.Message(null, blocks);
    
            System.enqueueJob(new getChannelId(message, channelName));
            }

            
        }
    }

    class getChannelId implements Queueable, Database.AllowsCallouts{

        private String channelName {get;set;}
        private  Slack.Message message {get;set;}
    
        public getChannelId( Slack.Message message, String channelName){
            this.message = message;
            this.channelName = channelName;
        }

        public void execute(QueueableContext qc){
            String channelId = SlackLibrary.getPublicChannel(channelName);

            if(!Test.isRunningTest()) {
            System.enqueueJob(new sendMessageToChannel(message, channelId));
            }
        }
    }

    class sendMessageToChannel implements Queueable, Database.AllowsCallouts{

        private Slack.Message message {get;set;}
        private String channelId {get;set;}

        public sendMessageToChannel(Slack.Message message, String channelId){
            this.message   = message;
            this.channelId = channelId;
        }

        public void execute(QueueableContext qc){

            SlackLibrary.sendMessageToChannel(message, channelId);
        }
    }

}