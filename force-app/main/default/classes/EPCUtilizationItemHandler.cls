/**
 * EPCUtilizationItemHandler.cls
 * Copyright 2018 Wired Triangle, LLC
 * http://www.wiredtriangle.com
 */
global with sharing class EPCUtilizationItemHandler implements ITrigger {

	public static Boolean bypassTriggerLogic = false;
    public static Boolean hasHandledDiscountBundles = false;
    public static Boolean executeEpcCalculation = true;

    global static TriggerConfiguration__c triggerConfig = TriggerConfiguration__c.getInstance();
    global static Boolean enableAutoCalculateEPCUtilization = triggerConfig.Enable_Auto_Calculate_EPC_Utilization__c;
	
    private Set<Id> accountsToCalculateEpc = new Set<Id>();
	private Map<Id,Id> epcuiIdToContactAccountIdMap = new Map<Id,Id>();
	private Map<Id,Contact> affectedEpcuisContactMap = new Map<Id,Contact>();
	private Map<Id,Account> affectedEpcuisAccountMap = new Map<Id,Account>();
	private Map<Id,EPC_Weighting__c> affectedEpcWeightingMap = new Map<Id,EPC_Weighting__c>();
	private Map<Id,Map<String,EPC_Weighting__c>> accountEPCWMap = new Map<Id,Map<String,EPC_Weighting__c>>();
	
	private static Map<Id, EPC_Utilization_Item__c> affectedEpcuisMap;
    private static Map<Id, Contact> epcuiIdToStudentContact = new Map<Id, Contact>();

    public static final List<String> ACTIVE_STATUSES = new List<String>{ 'Active', 'Planned', 'Completed'};
    
    public EpcUtilizationItemHandler() {}

    public void bulkBefore() {
    	if (!bypassTriggerLogic ) {
            if(Trigger.isUpdate) {
    		    bulkBeforeAfter();
            }
            if(hasHandledDiscountBundles == false) { 
                hasHandledDiscountBundles = true;
                if(Trigger.isInsert) {
                    handleDiscountBundles((List<EPC_Utilization_Item__c>)Trigger.new, new Map<Id, EPC_Utilization_Item__c>());
                } else if(Trigger.isUpdate) {
                    handleDiscountBundles((List<EPC_Utilization_Item__c>)Trigger.new, (Map<Id, EPC_Utilization_Item__c>)Trigger.oldMap);
                }
            }
    	}
    }

    public void bulkAfter() {
        if (!bypassTriggerLogic) {
    	    bulkBeforeAfter();
        }
    }
    public void bulkBeforeAfter() {
        if (Trigger.isDelete) {
			affectedEpcuisMap = (Map<Id, EPC_Utilization_Item__c>)Trigger.oldMap;
        } else {
        	affectedEpcuisMap = (Map<Id, EPC_Utilization_Item__c>)Trigger.newMap;
        }
        Set<Id> affectedEpcuisContactIds = new Set<Id>();
        Set<Id> affectedEpcuisAccountIds = new Set<Id>();

        for (EPC_Utilization_Item__c epcui:affectedEpcuisMap.values()) {
            if (epcui.Contact__c != null) {
                affectedEpcuisContactIds.add(epcui.Contact__c);
        		System.Debug('affectedEpcuisContactIds.add('+epcui.Contact__c+')');
            }
        }
		

        affectedEpcuisContactMap = new Map<Id,Contact>(
            [SELECT Id, AccountId FROM Contact WHERE Id IN :affectedEpcuisContactIds]
        );
		for (Contact c:affectedEpcuisContactMap.values()) {
			affectedEpcuisAccountIds.add(c.AccountId);
		}        
		System.Debug('affectedEpcuisAccountIds= '+affectedEpcuisAccountIds);
        
		affectedEpcWeightingMap = new Map<Id,EPC_Weighting__c>(
			[SELECT Id, Opportunity__c, Opportunity__r.Account.Id, Service__r.Name FROM EPC_Weighting__c WHERE Opportunity__r.Account.Id IN :affectedEpcuisAccountIds]
		);
		System.Debug('affectedEpcWeightingMap= '+affectedEpcWeightingMap);
		
		//populate 2D Map : (Map of Account ID to (Map of EPCW Name to EPCW))
		for (EPC_Weighting__c epcw : affectedEpcWeightingMap.values()) {
			if (accountEPCWMap.get(epcw.Opportunity__r.Account.Id)!=null) {
				// this AccountId is already in the outer map
				accountEPCWMap.get(epcw.Opportunity__r.Account.Id).put(epcw.Service__r.Name,epcw);
			} else {
				// add a new outer map entry for this AccountId, with a new Name=>EPCW map as it's value with this EPCW.Name=>EPCW
				accountEPCWMap.put(epcw.Opportunity__r.Account.Id, new Map<String,EPC_Weighting__c>{epcw.Service__r.Name => epcw});
			}
		}

        System.Debug('affectedEpcuisContactMap='+affectedEpcuisContactMap);
        for (EPC_Utilization_Item__c epcui:affectedEpcuisMap.values()) {
            if (epcui.Contact__c != null) {
            	Id thisContactId = epcui.Contact__c;
            	Contact thisContact = affectedEpcuisContactMap.get(thisContactId);
                Id thisAccountId = thisContact.AccountId;
                epcuiIdToContactAccountIdMap.put(epcui.Id,thisAccountId);
            }
        }
        System.Debug('affectedEpcuisContactMap='+affectedEpcuisContactMap);

    }

    public void beforeInsert(SObject so) {
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        EPC_Utilization_Item__c epcui = (EPC_Utilization_Item__c) so;
		System.Debug('epcuiIdToContactAccountIdMap.get(epcui.id) = ' + epcuiIdToContactAccountIdMap.get(epcui.id));
		if (accountEPCWMap.get(epcuiIdToContactAccountIdMap.get(epcui.id))!=null) {
            if (accountEPCWMap.get(epcuiIdToContactAccountIdMap.get(epcui.id)).get(epcui.category__c) != null) {
                if (epcui.EPC_Weighting__c!=accountEPCWMap.get(epcuiIdToContactAccountIdMap.get(epcui.id)).get(epcui.category__c).Id) 
                {
                    epcui.EPC_Weighting__c=accountEPCWMap.get(epcuiIdToContactAccountIdMap.get(epcui.id)).get(epcui.category__c).Id;
                }
            }
		}
    }

    public void beforeDelete(SObject so) {
    }

    public void beforeUnDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
        System.Debug('affectedEpcuisContactMap='+affectedEpcuisContactMap);
        EPC_Utilization_Item__c epcui = (EPC_Utilization_Item__c) so;
        if (enableAutoCalculateEPCUtilization && !bypassTriggerLogic) {
        	Contact thisContact=affectedEpcuisContactMap.get(epcui.Contact__c);
			accountsToCalculateEpc.add(thisContact.AccountId);
        }
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        EPC_Utilization_Item__c epcui = (EPC_Utilization_Item__c) so;
        EPC_Utilization_Item__c oldEpcui = (EPC_Utilization_Item__c) oldSo;
                
		if (enableAutoCalculateEPCUtilization  &&
            !bypassTriggerLogic &&
			epcService.sObjectEpcUtilizationCriteriaChanged(oldEpcui, epcui) 
		) {
			accountsToCalculateEpc.add(epcuiIdToContactAccountIdMap.get(epcui.Id));
            //EPCUI moved to new Account?
            //TODO Contact__r.AccountId isn't available and will always be null unless we query it
            if (epcui.Contact__r.AccountId!=oldEpcui.Contact__r.AccountId) {
                accountsToCalculateEpc.add(oldEpcui.Contact__r.AccountId);
            }
		}
    }

    public void afterDelete(SObject so) {
        EPC_Utilization_Item__c epcui = (EPC_Utilization_Item__c) so;

        if (enableAutoCalculateEPCUtilization &&
            !bypassTriggerLogic /*TODO &&
			epcService.sObjectEpcUtilizationCriteriaChanged(oldstudent, Student) */
		) {
			accountsToCalculateEpc.add(epcuiIdToContactAccountIdMap.get(epcui.Id)); 
		}
    }

    public void afterUnDelete(SObject so) {
        EPC_Utilization_Item__c epcui = (EPC_Utilization_Item__c) so;
        if (enableAutoCalculateEPCUtilization &&
            !bypassTriggerLogic /*TODO &&
			epcService.sObjectEpcUtilizationCriteriaChanged(oldstudent, Student) */
		) {
			accountsToCalculateEpc.add(epcui.Contact__r.AccountId);
		}
    }

    public void andFinally() {
        if (!accountsToCalculateEpc.isEmpty() && executeEpcCalculation) {
        	System.Debug('accountsToCalculateEpc.size()='+accountsToCalculateEpc.size());
            System.Debug('accountsToCalculateEpc = '+accountsToCalculateEpc);
        	EpcServiceV2 epcHelper = new EpcServiceV2(accountsToCalculateEpc);
        	ID jobID = System.enqueueJob(epcHelper);
        }
    }

    public void handleDiscountBundles(List<EPC_Utilization_Item__c> newList, Map<Id, EPC_Utilization_Item__c> oldMap) {
        Map<Id, List<EPC_Utilization_Item__c>> studentIdToRecalcEpcuis = new Map<Id, List<EPC_Utilization_Item__c>>();
        Set<Id> serviceIds = new Set<Id>();

        for(EPC_Utilization_Item__c epcui : newList) {
            EPC_Utilization_Item__c oldEpcui = (EPC_Utilization_Item__c)oldMap.get(epcui.Id);
            if(needToRecalcStudent(epcui, oldEpcui)) {
                addEpcuiToMap(studentIdToRecalcEpcuis, epcui);
                serviceIds.add(epcui.Service__c);
            }
        }

        if(!studentIdToRecalcEpcuis.isEmpty()) {
            recalculateStudentBundlesForServices(studentIdToRecalcEpcuis, serviceIds);
        }
    }

    private Boolean needToRecalcStudent(EPC_Utilization_Item__c epcui, EPC_Utilization_Item__c oldEpcui) {
        // oldEpcui is null when insert
        return oldEpcui == null || epcui.Status__c != oldEpcui.Status__c;
    }

    private void addEpcuiToMap(Map<Id, List<EPC_Utilization_Item__c>> studentIdToRecalcEpcuis, EPC_Utilization_Item__c epcui) {
        if(studentIdToRecalcEpcuis.get(epcui.Student__c) == null) {
            studentIdToRecalcEpcuis.put(epcui.Student__c, new List<EPC_Utilization_Item__c>());
        }
        studentIdToRecalcEpcuis.get(epcui.Student__c).add(epcui);
    }

    public void recalculateStudentBundlesForServices(Map<Id, List<EPC_Utilization_Item__c>> studentIdToRecalcEpcuis, Set<Id> serviceIds) {
        Map<Id, EPCUI_Bundle__mdt> bundleMap = getBundleMap();
        Map<Id, Service__c> serviceMap = getServiceMap(serviceIds);
        Map<Id, Student__c> studentMap = getStudentsWithNonTriggeredEpcuisMap(studentIdToRecalcEpcuis.keyset());

        Map<Id, EPC_Utilization_Item__c> existingEpcuisToUpdate = new Map<Id, EPC_Utilization_Item__c>();

        for(Id studentId : studentIdToRecalcEpcuis.keySet()) {
            Student__c student = studentMap.get(studentId);
            for(EPC_Utilization_Item__c epcui : studentIdToRecalcEpcuis.get(studentId)) {
                for(EPCUI_Bundle__mdt bundle : getApplicableBundles(epcui, bundleMap, serviceMap.get(epcui.Service__c).Name)) {
                    List<EPC_Utilization_Item__c> newEpcuisThatMeetBundleReq = getEpcuisThatMeetBundleReq(studentIdToRecalcEpcuis.get(studentId), bundle, serviceMap);
                    List<EPC_Utilization_Item__c> existingEpcuisThatMeetBundleReq = new List<EPC_Utilization_Item__c>();
                    if(student != null) {
                        existingEpcuisThatMeetBundleReq = getEpcuisThatMeetBundleReq(student.EPC_Utilization_Items__r, bundle, serviceMap);
                    }
                    
                    Decimal setEpcsDiscounted = 0;
                    if(newAndExistingEpcuiCountsMeetBundleMinimum(newEpcuisThatMeetBundleReq, existingEpcuisThatMeetBundleReq, bundle)) {
                        setEpcsDiscounted = bundle.EPCs_Discounted_Per_Item__c;
                    }
                    // todo support multiple applicable bundles, right now it is assuming only one per Scott
                    setEpcsDiscountedOnEpcuis(newEpcuisThatMeetBundleReq, setEpcsDiscounted);
                    setEpcsDiscountedOnEpcuis(existingEpcuisThatMeetBundleReq, setEpcsDiscounted);
                    existingEpcuisToUpdate.putAll(existingEpcuisThatMeetBundleReq);

                } // for bundle
            } // for epcui
        } // for student

        if(!existingEpcuisToUpdate.isEmpty()) {
            executeEpcCalculation = false;
            update existingEpcuisToUpdate.values();
            executeEpcCalculation = true;
        }
    }

    private Map<Id, EPCUI_Bundle__mdt> getBundleMap() {
        return new Map<Id, EPCUI_Bundle__mdt>([
            SELECT Id, Minimum_Count_For_Discount_to_Apply__c, EPCs_Discounted_Per_Item__c, Service_Name_Contains__c, Start_Date__c, End_Date__c
            FROM EPCUI_Bundle__mdt
        ]);
    }
    
    private Map<Id, Service__c> getServiceMap(Set<Id> serviceIds) {
        return new Map<Id, Service__c>([
            SELECT Id, Name
            FROM Service__c 
            WHERE Id IN :serviceIds
        ]);
    }

    private Map<Id, Student__c> getStudentsWithNonTriggeredEpcuisMap(Set<Id> studentIds) {
        Set<Id> idsToExclude = new Set<Id>();
        if(Trigger.isUpdate || Trigger.isDelete) { idsToExclude.addAll(Trigger.oldMap.keyset()); }
        return new Map<Id, Student__c>([
            SELECT Id,
                (SELECT Id, EPC_Utilization_Date__c, Service__r.Name, Status__c, IsDeleted
                FROM EPC_Utilization_Items__r
                WHERE Id NOT IN :idsToExclude)
            FROM Student__c
            WHERE Id IN :studentIds
        ]);
    }

    private List<EPCUI_Bundle__mdt> getApplicableBundles(EPC_Utilization_Item__c epcui, Map<Id, EPCUI_Bundle__mdt> bundleMap, String serviceName) {
        List<EPCUI_Bundle__mdt> applicableBundles = new List<EPCUI_Bundle__mdt>();
        for(EPCUI_Bundle__mdt bundle : bundleMap.values()) {
            if(epcuiMeetsBundleNameAndDateRange(epcui, serviceName, bundle)) {
                applicableBundles.add(bundle);
            }
        }
        return applicableBundles;
    }

    private List<EPC_Utilization_Item__c> getEpcuisThatMeetBundleReq(List<EPC_Utilization_Item__c> epcuis, EPCUI_Bundle__mdt bundle, Map<Id, Service__c> serviceMap) {
        List<EPC_Utilization_Item__c> epcuisThatMeetBundleReq = new List<EPC_Utilization_Item__c>();
        for(EPC_Utilization_Item__c epcui : epcuis) {
            // trigger context epcuis dont have the relational name field, so use the map 
            // else, the related epcuis from the student query will have the relational field
            String serviceName = serviceMap.get(epcui.Service__c) == null ? epcui.Service__r.Name : serviceMap.get(epcui.Service__c).Name;
            if(epcuiMeetsBundleNameAndDateRange(epcui, serviceName, bundle) && ACTIVE_STATUSES.contains(epcui.Status__c) && epcui.IsDeleted == false) {
                epcuisThatMeetBundleReq.add(epcui);
            }
        }
        system.debug(epcuisThatMeetBundleReq);
        return epcuisThatMeetBundleReq;
    }

    private Boolean epcuiMeetsBundleNameAndDateRange(EPC_Utilization_Item__c epcui, String serviceName, EPCUI_Bundle__mdt bundle) {
        if(bundle.Start_Date__c <= epcui.EPC_Utilization_Date__c && epcui.EPC_Utilization_Date__c <= bundle.End_Date__c) {
            for(String nameContains : bundle.Service_Name_Contains__c.split(',')) {
                if(serviceName == null || serviceName.contains(nameContains)) {
                    return true;
                }
            }
        }
        return false;
    }

    private Boolean newAndExistingEpcuiCountsMeetBundleMinimum(List<EPC_Utilization_Item__c> newEpcuisThatMeetBundleReq, List<EPC_Utilization_Item__c>  existingEpcuisThatMeetBundleReq, EPCUI_Bundle__mdt bundle) {
        return newEpcuisThatMeetBundleReq.size() + existingEpcuisThatMeetBundleReq.size() >= bundle.Minimum_Count_For_Discount_to_Apply__c;
    }

    private void setEpcsDiscountedOnEpcuis(List<EPC_Utilization_Item__c> epcuis, Decimal setEpcsDiscounted) {
        for(EPC_Utilization_Item__c epcui : epcuis) {
            epcui.EPCs_Discounted__c = setEpcsDiscounted;
        }
    }

}