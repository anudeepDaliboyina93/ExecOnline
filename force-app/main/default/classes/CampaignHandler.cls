/**
 * CampaignHandler.cls
 * Copyright 2017 Wired Triangle, LLC
 * http://www.wiredtriangle.com
 */

public with sharing class CampaignHandler implements ITrigger {
    
    private static Map<Id, Id> campaignIdToProgramIdMap = new Map<Id, Id>();
    
    private static Map<Id, Campaign> campaignsForPrograms = new Map<Id, Campaign>();

    public static Boolean allowCampaignNameChange = FALSE;

    public void bulkBefore() {
    	Set<Id> programsToLookUp = new Set<Id>();
    	Map<Id, Id> programIdToCampaignIdMap = new Map<Id, Id>();

    	campaignsForPrograms = new Map<Id, Campaign>([Select Id, Name, Program__c, Program__r.Name from Campaign where Program__c != NULL]);
    	for (Campaign c : campaignsForPrograms.values()) {
			programsToLookUp.add(c.Program__c);
			programIdToCampaignIdMap.put(c.Program__c, c.Id);
    	}
    	

    	if (!programIdToCampaignIdMap.isEmpty()) {
    		List<Program__C> programs = [Select Id, Manager_Campaign__c from Program__c where  Id in :programIdToCampaignIdMap.keySet() and Manager_Campaign__c != NULL];
    		for (Program__c p : programs) {
    			campaignIdToProgramIdMap.put(p.Manager_Campaign__c, p.Id);
    		}
    	}

    }

    public void bulkAfter() {
        
    }

    public void beforeInsert(SObject so) {
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
    	Campaign c = (Campaign)so;
    	Campaign oldC = (Campaign)oldSo;
		checkManagerProgramChange(oldC, c);
    }

    public void beforeDelete(SObject so) {
    }

    public void beforeUnDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
           
    }

    public void afterUpdate(SObject oldSo, SObject so) {

    }

    public void afterDelete(SObject so) {


    }

    public void afterUnDelete(SObject so) {
       
    }

    public void andFinally() {
        }

    @TestVisible
    private void checkManagerProgramChange(Campaign oldC, Campaign newC) {
    	if (oldC.Name != newC.Name && newC.Program__c != NULL) {
    		String progMgrCampaignId = campaignIdToProgramIdMap.get(newC.Id); 
    		if (progMgrCampaignId != NULL && progMgrCampaignId == newC.Program__c && !allowCampaignNameChange) {
    			newC.Name = oldC.Name;
    		}
    	}
    }

}