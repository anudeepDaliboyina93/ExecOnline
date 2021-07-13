/**
 * epcService.cls
 * Copyright 2018 Wired Triangle, LLC
 * http://www.wiredtriangle.com
 */
public without sharing class epcService implements Queueable {

    // ============================================================================================================
    // CLASS VARIABLES ============================================================================================
    // ============================================================================================================
	private static Map<Id,Student__c> affectedStudentsMap = new Map<Id,Student__c>();
    private static Map<Id,EPC_Utilization_Item__c> affectedEpcuisMap = new Map<Id,EPC_Utilization_Item__c>();
	private static List<EPC_Utilization__c> epcUtilizationsToInsert = new List<EPC_Utilization__c>();
	private  Map<String, Map<Id,Id>> serviceCat_accountIdProvIdWithNextEpcsMap_Map = new Map<String, Map<Id, Id>>(); // for each serviceCat, map of AccountId, to next ProvId with available EPCs?
	private  List<provWrapper> provWrappers = new List<provWrapper>();
	private  Map<Id, provWrapper> provIdProvWrapperMap = new Map<Id, provWrapper>();
	private static Map<String, EPC_Weighting__c> recordIdKeyEpcWeightingMap = new Map<String,EPC_Weighting__c>(); // map key is concatenated Ids from various object records
    public TriggerConfiguration__c triggerConfig;
    public String triggerConfigLevel;
    private static Boolean userLevelTriggerConfigExists = TRUE;
	private Set<Id> accountIds;
	private static Boolean hasEpcServiceExecutedThisTransaction = false;

    // ============================================================================================================
    // CONSTRUCTOR ================================================================================================
    // ============================================================================================================
	public epcService(Set<Id> accountIdsToCalculate) {
		this.accountIds = accountIdsToCalculate;
	}	
	
	// ============================================================================================================
    // insertProvisionedEpcs ======================================================================================
    // ============================================================================================================
    //
    // When Opportunities are updated to Stage = "Closed Won", and >0 EPCs have been purchased, 
    // a corresponding EPCU record of Type="Provisioned" is inserted, 1 for each Opportunity, for each Service Category.
    // NOTE: After this functionality was designed and coded, the business requirement to segregate EPCs by 
    // Service Category (e.g. "All" vs. "New Manager Only" was put on hold, but this capability now exists if needed

	public void insertProvisionedEpcs(List<Opportunity> newWinOppsList) {
		List<EPC_Utilization__c> epcuToInsert = new List<EPC_Utilization__c>();
		List<Id> opportunityIdNewWinOppsList = new List<Id>();
		for (Opportunity o:newWinOppsList) {
			opportunityIdNewWinOppsList.add(o.Id);
		}
		List<OpportunityLineItem> newWinOLIs = new List<OpportunityLineItem>(
			[SELECT Id, Quantity, Service_Category__c, Opportunity.AccountId FROM OpportunityLineItem 
			WHERE Product2.Name = 'EPC' AND Quantity>0 AND OpportunityId in :opportunityIdNewWinOppsList]);
		for (OpportunityLineItem oli:newWinOLIs) {
			if (oli.service_category__c==null) {
				oli.service_category__c='All';
			}
			epcuToInsert.add(
				new EPC_Utilization__c(
					Account__c=oli.Opportunity.AccountId, Opportunity__c=oli.OpportunityId, EPCs_Utilized__c = oli.Quantity, 
					Service_Category__c=oli.Service_Category__c, Type__c='Provisioned'
				)
			);
		}
		insert epcuToInsert;
	}

    // ============================================================================================================
    // sObjectEpcUtilizationCriteriaChanged =======================================================================
    // ============================================================================================================
    //
    // For each object, a value change to any of these specified fields is grounds for recalculating EPCs across
    // the entire parent Account
	public static boolean sObjectEpcUtilizationCriteriaChanged (sObject oldSo, sObject so) {
		// epcService should only ever fire once per transaction
		// this is a recursive check to block when a workflow or similar calls the trigger in the same transaction
		if(hasEpcServiceExecutedThisTransaction && !Test.isRunningTest()) { return false; }
		
		Schema.sObjectType soType = so.getSobjectType();
		if(
			soType == Schema.Student__c.getSobjectType() &&
			(
				ApexUtility.didFieldValueChangeCaseSensitive(so, oldSo, 'Contact__c') ||
				ApexUtility.didFieldValueChangeCaseSensitive(so, oldSo, 'Program__c') ||
				ApexUtility.didFieldValueChangeCaseSensitive(so, oldSo, 'Status__c') ||
				ApexUtility.didFieldValueChangeCaseSensitive(so, oldSo, 'EPC_Utilization_Date__c') ||
				ApexUtility.didFieldValueChangeCaseSensitive(so, oldSo, 'EPCs_Comped__c') ||
				ApexUtility.didFieldValueChangeCaseSensitive(so, oldSo, 'EPCs_Deferred__c') 
			) ||
			
			soType == Schema.EPC_Utilization_Item__c.getSobjectType() &&
			(
				ApexUtility.didFieldValueChangeCaseSensitive(so, oldSo, 'EPC_Utilization_Date__c') ||
				ApexUtility.didFieldValueChangeCaseSensitive(so, oldSo, 'Status__c')
			) ||
			
			soType == Schema.Contact.getSobjectType() &&
			(
				ApexUtility.didFieldValueChangeCaseSensitive(so, oldSo, 'AccountId') ||
				ApexUtility.didFieldValueChangeCaseSensitive(so, oldSo, 'Email')
			) ||
			
			soType == Schema.Account.getSobjectType() &&
			(
				ApexUtility.didFieldValueChangeCaseSensitive(so, oldSo, 'EPC_Utilization_Force_Recalc__c')
			) ||
			
			soType == Schema.Opportunity.getSobjectType() &&
			(
				ApexUtility.didFieldValueChangeCaseSensitive(so, oldSo, 'CloseDate') ||
				ApexUtility.didFieldValueChangeCaseSensitive(so, oldSo, 'StageName')
			) ||
			
			soType == Schema.Program__c.getSobjectType() &&
			(
				ApexUtility.didFieldValueChangeCaseSensitive(so, oldSo, 'Course_Start_Date__c')
			)
		) {
			hasEpcServiceExecutedThisTransaction = true;
			return TRUE;
		}
		return FALSE;
	}

    // ============================================================================================================
    // PROV WRAPPER CLASS: provWrapper ============================================================================
    // ============================================================================================================
    //
    // Wrapper class definition for each Provisioned EPCU record
    public class provWrapper implements Comparable {
        public Id accountId {get; private set;}
        public EPC_Utilization__c prov {get; private set;}
        public Decimal unutilizedEpcs {get; private set;}
        public Id nextProvIdWithEpcs {get; private set;}
        public Integer myIndex {get; private set;}
		public String serviceCat {get; private set;}
        
        public provWrapper(EPC_Utilization__c prov) {
            this.prov = prov;
            this.accountId = prov.Account__c;
            this.unutilizedEPCs=prov.EPCs_Utilized__c;
            this.nextProvIdWithEpcs=null;
            this.myIndex=null;
			this.serviceCat=prov.Service_Category__c;
        }
        
        //Sorting sets the order of first-in first-out utilization by EPCUIs/Students
        public Integer compareTo(Object obj){
			provWrapper myProv = (provWrapper)(obj);

        	//Sort by serviceCat, then AccountId, then Opp.CloseDate, then Id - We need determanistic order without any equivalency
			if (this.AccountId > myProv.AccountId) {
				return 1;
			} else if (this.prov.Opportunity__r.CloseDate > myProv.prov.Opportunity__r.CloseDate) {
				return 1;
			} else if (this.prov.Id > myProv.prov.Id) {
				return 1;
			} else {
				return -1;
			}
        }
    }

    // ============================================================================================================
    // POPULATE PROV WRAPPER CLASS: getProvWrappers ===============================================================
    // ============================================================================================================
    //
    // Wrapper class definition for each Provisioned EPCU record
    //Populate a list of the wrapper class for all relevant Provisioned EPCUs
	public static List<provWrapper> getProvWrappers (Set<Id> accountIds) {
		List<Id> accountIdsList = new List<Id>();
		for (Id accountId:accountIds) {
			accountIdsList.add(accountId);
		}
		List<provWrapper> results = new List<provWrapper>();		
		List<EPC_Utilization__c> provs =[
			SELECT Id, Account__c, Name, Opportunity__c, Opportunity__r.CloseDate, Opportunity__r.name, EPCs_Utilized__c, Service_Category__c 
			FROM EPC_Utilization__c 
			WHERE Type__c='Provisioned' AND EPCs_Utilized__c!=0 AND EPCs_Utilized__c!=null AND Account__c IN :accountIds
			ORDER BY Opportunity__r.CloseDate ASC, Service_Category__c
			//FOR UPDATE            
		];
		if (!(provs.size()>0)) { //Shenanigans! No Provisioned EPCUs for this Account?
			throw new TriggerException('No Provisioned EPCs for Account ' + accountIdsList[0]);
			Apex_Exception__e dmlException = new Apex_Exception__e(Message__c='No Provisioned EPCs for Account: '+accountIdsList[0], TypeName__c='Bad Data', Related_Record_Id__c=accountIdsList[0]);
			Database.SaveResult sr = EventBus.publish(dmlException);
			if (sr.isSuccess()) {
			    System.debug('Successfully published event for: No Provisioned EPCs for Account ');
			} else {
			    for(Database.Error err : sr.getErrors()) {
			        System.debug('Error publishing event for DmlException - returned: ' +
			                     err.getStatusCode() +
			                     ' - ' +
			                     err.getMessage());
			    }
			}			
		}
		for (EPC_Utilization__c prov:provs) {
				results.add(new provWrapper(prov));
		}
        System.Debug('Unsorted provs : ' + results);
		results.sort();
        System.Debug('Sorted provs : ' + results);
		return results;
	}

    // ============================================================================================================
    // PROCESS WRAPPERS: processProvWrappers ======================================================================
    // ============================================================================================================
    //
	public void processProvWrappers (List<epcService.provWrapper> provWrappers) {
		// #1. populate accountIdNextOppIdWithEpcsMap
		// #2. build linked list of wrappers: for each wrapper, populate nextOppWithEpcs if such an opp exists
		// #3. let each wrapper know what its index is
		// #5. populate serviceCat_accountIdProvIdWithNextEpcsMap_Map
		
        provIdProvWrapperMap = new Map<Id, provWrapper>();
		Id lastProvAccountId=null;
		Integer index=0;
		String lastProvServiceCat;
		List<Service__c> services = new List<Service__c>([SELECT Id, Name, Service_Category__c FROM Service__c WHERE Status__c='Active']);

		//walk through each Provisioned EPCU Wrapper (provWrapper)
		for (provWrapper myProvWrapper:provWrappers) {
			//Wrappers are sorted by serviceCat, so new entry for each new value (in serviceCat_accountIdProvIdWithNextEpcsMap_Map)
			//if (myProvWrapper.prov.Service_Category__c != lastProvServiceCat) { // first prov of next serviceCat
			if (serviceCat_accountIdProvIdWithNextEpcsMap_Map.get(myProvWrapper.serviceCat) == null) {// first prov of this serviceCat		
				serviceCat_accountIdProvIdWithNextEpcsMap_Map.put(myProvWrapper.serviceCat, new Map<Id, Id>());
			}
			//Wrappers are sorted secondly by Account
			//find Id of first Provisioned EPCU for each Account, within this ServiceName grouping.
			//if(myProvWrapper.accountId!=lastProvAccountId || myProvWrapper.serviceCat!=lastProvServiceCat) { //this is first prov for this account, within this serviceCat group
			if(serviceCat_accountIdProvIdWithNextEpcsMap_Map.get(myProvWrapper.prov.Service_Category__c).get(myProvWrapper.accountId) == null) {//this is first prov for this account, within this serviceCat group
				serviceCat_accountIdProvIdWithNextEpcsMap_Map.get(myProvWrapper.prov.Service_Category__c).put(myProvWrapper.accountId, myProvWrapper.prov.Id);
			} else { // this is not first prov for this account, mark it as "next" for the previous provWrapper (index-1)
				provWrappers[index-1].nextProvIdWithEpcs = myProvWrapper.prov.Id; // #2 
			}
			lastProvAccountId=myProvWrapper.AccountId;
			lastProvServiceCat=myProvWrapper.serviceCat;
			provWrappers[index].myIndex = index; // #3 //System.Debug(' #4 provIdProvWrapperMap.put()'); //System.Debug( myProvWrapper.prov.Id ); //System.Debug(myProvWrapper );
			provIdProvWrapperMap.put(myProvWrapper.prov.Id, myProvWrapper); // #4
			index++;
		}
	}

    // ============================================================================================================
    // EPC ITEM WRAPPER CLASS: epcItemWrapper ======================================================================
    // ============================================================================================================
    //
    // Common wrapper class for each "item" (Student or EPC Utilization Item) that can "utilize" EPCs
    public class epcItemWrapper implements Comparable {
        String itemType;
        Student__c student;
        Id accountId;
		Id contactId;
        EPC_Utilization_Item__c epcui;
        Date epcUtilizationDate;
        Decimal EPCsDiscounted = 0;
		Decimal serviceListWeighting=0;
        Id studentId;
        Id epcuiId;
        Id programId;
		Id programFamilyId;
        String category;
        String serviceCat;
        
        public epcItemWrapper (Student__c s, EPC_Utilization_Item__c i) {
            student=s;
            epcui=i;
            itemType=(student==null)?'epcui':'student';
            
             if (student==null) {
            	epcUtilizationDate = epcui.EPC_Utilization_Date__c;
                accountId          = epcui.contact__r.accountId;
				EPCsDiscounted     = 0;
                epcuiId            = epcui.Id;
				// programId       = epcui.student__r.Program__c;
				programId          = (epcui.student__c==null)?null:epcui.student__r.program__c;
				programFamilyId    = (epcui.student__c==null)?null:epcui.student__r.program__r.program_family__c;
				contactId          = (epcui.student__c==null)?null:epcui.student__r.contact__c;
                category           = epcui.Category__c;
				serviceListWeighting= epcui.Service__r.List_Weighting__c;
				serviceCat        = epcui.Service__r.Service_Category__c;
            } else {
				if (student.EPCs_Comped__c==null) { student.EPCs_Comped__c=0;}
				if (student.EPCs_Deferred__c==null) { student.EPCs_Deferred__c=0;}
                epcUtilizationDate = student.EPC_Utilization_Date__c;
				contactId          = student.contact__c;
                accountId          = (student.contact__c==null)?null:student.contact__r.accountId;
				EPCsDiscounted     = student.EPCs_Comped__c + student.EPCs_Deferred__c;                
                studentId          = student.Id;
                programId          = student.Program__c;
                programFamilyId    = student.Program__r.Program_Family__c;
                category           = 'Core Program';
				serviceListWeighting=student.Program__r.Program_Family__r.Primary_Service__r.List_Weighting__c;
                serviceCat        = 'Core Program';
            }
        }

        public Integer compareTo(Object obj){
			epcItemWrapper myEpcItemWrapper = (epcItemWrapper)(obj);
            if (this.epcUtilizationDate > myEpcItemWrapper.epcUtilizationDate) {
                return 1;
            }
        	return -1;
        }
    }

    // ============================================================================================================
    // METHOD TO DELETE EXISTING EPCU: deleteExistingEpcUtilizations ========================================
    // ============================================================================================================
    //
    // DML to delete all existing EPCU in each affected Account. Because DML will count against CPU Time Limit if 
    // any formula-based validation rules need evaluation, we can't rely on this being a zero-cost DML. It's ok 
    // if they aren't deleted right away, as long as it happens before the subsequent async job to insert newly
    // calculated EPCU records. HOWEVER, in reality, the recalc'ed insert of new records actually does precede execution
	// of this method, and so we have to make it synchronous (not @future) until we complete the TODO listed here:
    //
    // TODO: refactor to ensure that this only deletes those records that preceed the corresponding recalculated
    // EPCU records
    //
    //@future static public void deleteExistingEpcUtilizations(Set<Id> accountIds) {
    static public void deleteExistingEpcUtilizations(Set<Id> accountIds) {
        List<EPC_Utilization__c> existingEpcUtilizations = [SELECT Id FROM EPC_Utilization__c WHERE Type__c='Actual' AND Account__c IN :accountIds];
        try {
            delete existingEpcUtilizations;     
            Apex_Exception__e dmlException = new Apex_Exception__e(Message__c='No Error', TypeName__c='No Type', Related_Record_Id__c='000');
            Database.SaveResult sr = EventBus.publish(dmlException);
            if (sr.isSuccess()) {
                System.debug('Successfully published event for EPC Delete');
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error publishing event for EPC Delete');
                }
            }           
        } catch (System.DmlException e) {
            Apex_Exception__e dmlException = new Apex_Exception__e(Message__c=e.getMessage(), TypeName__c=e.getTypeName(), Related_Record_Id__c='');
            Database.SaveResult sr = EventBus.publish(dmlException);
            if (sr.isSuccess()) {
                System.debug('Successfully published event for ' +e.getTypeName());
            } else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error publishing event for DmlException - returned: ' +
                                 err.getStatusCode() +
                                 ' - ' +
                                 err.getMessage());
                }
            }           
        }
    }
	
    // ============================================================================================================
    // MAIN RECALC METHOD =========================================================================================
    // ============================================================================================================
    //
	public void execute (QueueableContext context) {
        if (TriggerConfiguration__c.getInstance(UserInfo.getUserId()).Id!=null) {
        	triggerConfigLevel='User';
            triggerConfig=TriggerConfiguration__c.getInstance(UserInfo.getUserId());
		} else {
             if (TriggerConfiguration__c.getInstance(UserInfo.getProfileId()).Id!=null) {
                triggerConfigLevel='Profile';
                triggerConfig=TriggerConfiguration__c.getInstance(UserInfo.getProfileId());
            } else {
                triggerConfigLevel='Org';
                triggerConfig=TriggerConfiguration__c.getOrgDefaults();
            }
        }
        System.Debug('triggerConfig='+triggerConfig);
		
        epcUtilizationsToInsert = new List<EPC_Utilization__c>();
        System.Debug('Executing calc for accountIds '+accountIds);
        List<Account> accountsToCalculate = [SELECT Id, Name, EPC_Utilization_Last_Recalc__c FROM Account WHERE Id in :accountIds AND epc_autocalculation_enabled__c = TRUE FOR UPDATE];
        accountIds.clear(); // don't need accounts if epc_autocalculation_enabled__c == FALSE
        for (Account a:accountsToCalculate) {
            accountIds.add(a.Id);
        }
		if (accountIds.size()==0) {
			return;
		}
        
		Decimal itemEpcsRequiringUtilization;
		Decimal thisProvEPCsRemaining;
		Decimal epcsToUtilizeThisProv;
        Boolean lastProvForThisAccount = FALSE;

        deleteExistingEpcUtilizations(accountIds);
	
		provWrappers = new List<provWrapper>();		
		provWrappers=getProvWrappers(accountIds);
		provWrappers.sort();
        System.Debug('getProvWrappers returned : ' + provWrappers);
		processProvWrappers(provWrappers);
	
        List<epcItemWrapper> affectedItemsList = new List<epcItemWrapper>();
        
        affectedEpcuisMap = new Map<Id,EPC_Utilization_Item__c>([
			SELECT Id, Status__c, EPC_Utilization_Date__c, Contact__c, Contact__r.Email, 
				Contact__r.AccountId, Student__r.Contact__c, Student__r.Program__c, Student__r.Program__r.Program_Family__c, 
				Category__c, Service__c, Service__r.Service_Category__c, Service__r.List_Weighting__c
			FROM EPC_Utilization_Item__c WHERE Contact__r.AccountId IN :accountIds AND Status_Utilized__c = TRUE
			ORDER BY Contact__r.AccountId, EPC_Utilization_Date__c, CreatedDate, Contact__r.LastName, Contact__r.Firstname, Id]);
        System.Debug('affectedEpcuisMap = ');
        System.Debug(affectedEpcuisMap.Values());

		Map<String, List<epcItemWrapper>> serviceCatAffectedItemsMap = new Map<String, List<epcItemWrapper>>();

        for (EPC_Utilization_Item__c epcui:affectedEpcuisMap.Values()) {
            //affectedItemsList.add(new epcItemWrapper(null, epcui));
			if (serviceCatAffectedItemsMap.get(epcui.Service__r.Service_Category__c) == null) {
				serviceCatAffectedItemsMap.put(epcui.Service__r.Service_Category__c, new List<epcItemWrapper>());
			}
			serviceCatAffectedItemsMap.get(epcui.Service__r.Service_Category__c).add(new epcItemWrapper(null, epcui));
        }

		affectedStudentsMap = new Map<Id,Student__c>([
			SELECT Id, Status__c, EPC_Utilization_Date__c, Contact__c, Contact__r.Email, 
			Contact__r.AccountId, Program__c, Program__r.Program_Family__c, Program__r.Program_Family__r.Service_Category__c,
			Program__r.Program_Family__r.Primary_Service__r.List_Weighting__c, EPCs_Comped__c, EPCs_Deferred__c
			FROM Student__c WHERE Contact__r.AccountId IN :accountIds AND Status_Utilized__c = TRUE
			ORDER BY Contact__r.AccountId, EPC_Utilization_Date__c, CreatedDate, Contact__r.LastName, Contact__r.Firstname, Id]);
        for (Student__c student:affectedStudentsMap.Values()) {
			String serviceCat = student.Program__r.Program_Family__r.Service_Category__c;
			if (serviceCat == null) {
				serviceCat = 'All';
			}
            //affectedItemsList.add(new epcItemWrapper(student, null));
			if (serviceCatAffectedItemsMap.get(serviceCat) == null) {
				serviceCatAffectedItemsMap.put(serviceCat, new List<epcItemWrapper>());
			}
			serviceCatAffectedItemsMap.get(serviceCat).add(new epcItemWrapper(student, null));
        }
        
        Map<Id,EPC_Weighting__c> affectedEpcWeightings = new Map<Id,EPC_Weighting__c>(
			[SELECT Id, Account__c, Contact__c, Opportunity__c, Program_Family__c, Program__c, Service__r.Name, Service__r.Service_Category__c, EPC_Weighting__c 
        	FROM EPC_Weighting__c WHERE Account__c IN :accountIds]
		);
        for (EPC_Weighting__c w:affectedEpcWeightings.values()) {
				recordIdKeyEpcWeightingMap.put(w.contact__c+':'+w.opportunity__c+':'+w.program_family__c+':'+w.Service__r.name , w);
				System.debug('recordIdKeyEpcWeighting.put : ' + w.contact__c+':'+w.opportunity__c+':'+w.program_family__c+':'+w.Service__r.name+' = ' + w);
        }
        System.Debug('recordIdKeyEpcWeightingMap : '+recordIdKeyEpcWeightingMap);
        
		affectedItemsList.sort();

		Boolean doDebug=FALSE;

		//START needed LOOP an Account
		//TODO multiple accounts in one transaction probably not correct yet, with continue statement now nested down too far
		for (String serviceCat:serviceCatAffectedItemsMap.keySet()) {
			System.Debug('------------- ServiceCategory : '+serviceCat+' -------------');
			affectedItemsList = serviceCatAffectedItemsMap.get(serviceCat);
			affectedItemsList.sort();

			for (Account a:accountsToCalculate) {
				System.Debug('------------- Account : '+a.Name+' ('+a.Id+') -------------');
                if(provIdProvWrapperMap.get(serviceCat_accountIdProvIdWithNextEpcsMap_Map.get(serviceCat).get(a.Id)).nextProvIdWithEpcs != null) {
                    lastProvForThisAccount=FALSE;                
                } else {
                    lastProvForThisAccount=TRUE;                
                }

				for (epcItemWrapper item:affectedItemsList) { 
					if (TRUE) System.Debug('Processing epcItemWrapper : '+item);
					if (item.AccountId != a.Id) {
						continue; //if this item isn't in the account we're processing, skip it on this iteration
					}
					Id itemAccountId = item.AccountId;
					//Id idNextOppWithEpcs=accountIdNextOppIdWithEpcsMap.get(itemAccountId);
					Id provIdWithCategoryEpcs;
					if (serviceCat_accountIdProvIdWithNextEpcsMap_Map.get(serviceCat) != null) {
					provIdWithCategoryEpcs=serviceCat_accountIdProvIdWithNextEpcsMap_Map.get(serviceCat).get(itemAccountId);
					} else {
					System.Debug('No Provisioned EPCs for this Service Category!!!');
					}

                    provWrapper pw = null;
                    Id oppIdParentOfProv = null;
                    thisProvEPCsRemaining = 0;
                    if (provIdWithCategoryEpcs!=null) {
                        pw = provIdProvWrapperMap.get(provIdWithCategoryEpcs);
                        oppIdParentOfProv = pw.prov.Opportunity__c;
                        thisProvEPCsRemaining = pw.unutilizedEPCs;      
                    } 
                    System.Debug('------------- Provisioned EPCU pw '+pw);

					EPC_Weighting__c epcWeighting;
					Id epcWeightingId;

                            //TODO  EPCUI.Weighting should be populated...
						System.Debug('Finding Weighting for '+item.epcuiId+item.studentId+' : oppIdParentOfProv='+oppIdParentOfProv+' , item.Category='+item.Category);
							//contact + opp + program
						if (recordIdKeyEpcWeightingMap.get(                item.contactId+':' +oppIdParentOfProv+':' +item.programFamilyId+':' +'null')!=null) {
							epcWeighting = recordIdKeyEpcWeightingMap.get (item.contactId+':' +oppIdParentOfProv+':' +item.programFamilyId+':' +'null');
						} else // contact + opp
						if (recordIdKeyEpcWeightingMap.get(                item.contactId+':' +oppIdParentOfProv+':' +'null'+':'         +'null')!=null) {
							epcWeighting = recordIdKeyEpcWeightingMap.get (item.contactId+':' +oppIdParentOfProv+':' +'null'+':'         +'null');
						} else // contact + program
						if (recordIdKeyEpcWeightingMap.get(                item.contactId+':' +'null'           +':' +item.programFamilyId+':' +'null')!=null) {
							epcWeighting = recordIdKeyEpcWeightingMap.get (item.contactId+':' +'null'           +':' +item.programFamilyId+':' +'null');
						} else // contact
						if (recordIdKeyEpcWeightingMap.get(                item.contactId+':' +'null'           +':' +'null'+':'         +'null')!=null) {
							epcWeighting = recordIdKeyEpcWeightingMap.get (item.contactId+':' +'null'           +':' +'null'+':'         +'null');
						} else // opp + program
						if (recordIdKeyEpcWeightingMap.get(                'null'        +':' +oppIdParentOfProv+':' +item.programFamilyId+':' +'null')!=null) {
							epcWeighting = recordIdKeyEpcWeightingMap.get ('null'        +':' +oppIdParentOfProv+':' +item.programFamilyId+':' +'null');
						} else // opp + program + Service Name (category)
						if (recordIdKeyEpcWeightingMap.get(                'null'        +':' +oppIdParentOfProv+':' +item.programFamilyId+':' +item.Category)!=null) {
							epcWeighting = recordIdKeyEpcWeightingMap.get ('null'        +':' +oppIdParentOfProv+':' +item.programFamilyId+':' +item.Category);
						} else // opp + Service (category)
						if (recordIdKeyEpcWeightingMap.get(                'null'        +':' +oppIdParentOfProv+':' +'null'        +':' +item.Category)!=null) {
							epcWeighting = recordIdKeyEpcWeightingMap.get ('null'        +':' +oppIdParentOfProv+':' +'null'        +':' +item.Category);
						} 
						// THESE CURRENTLY MATCH ERRONEOUSLY AGAINST LEGACY EPC_WEIGHTING__C RECORDS
						// else // opp
						// if (recordIdKeyEpcWeightingMap.get(                'null'        +':' +oppIdParentOfProv+':' +'null'+':'         +'null')!=null) {
						//  epcWeighting = recordIdKeyEpcWeightingMap.get ('null'        +':' +oppIdParentOfProv+':' +'null'+':'         +'null');
						// } 
						System.debug('Found Weighting '+epcWeighting);

		
                    if (epcWeighting!=null) {
                        itemEpcsRequiringUtilization= epcWeighting.EPC_Weighting__c - item.EPCsDiscounted;
                        epcWeightingId =epcWeighting.Id;
                    } else { //if no weighting, fall back to the service list weighting
                        epcWeightingId = null;
                        itemEpcsRequiringUtilization = item.serviceListWeighting - item.EPCsDiscounted;
                    }
		
					while (itemEpcsRequiringUtilization>0) {
						
						if (itemEpcsRequiringUtilization >= thisProvEPCsRemaining && !lastProvForThisAccount) {
							epcsToUtilizeThisProv = thisProvEPCsRemaining;
						} else {
							epcsToUtilizeThisProv = itemEpcsRequiringUtilization;
						}
						
						itemEpcsRequiringUtilization = itemEpcsRequiringUtilization - epcsToUtilizeThisProv;

						//ToDo check for null first
						thisProvEPCsRemaining = thisProvEPCsRemaining - epcsToUtilizeThisProv;
                        if (pw!=null) { //assuming we're not past the past prov...
                            provIdProvWrapperMap.get(serviceCat_accountIdProvIdWithNextEpcsMap_Map.get(serviceCat).get(itemAccountId)).unutilizedEPCs = thisProvEPCsRemaining;
                        }
						EPC_Utilization__c epcUtilizationToInsert = new EPC_Utilization__c(
									Type__c='Actual',
									Category__c=item.category,
									Account__c=a.Id,
                                    Provisioned_EPCU__c=(pw!=null?pw.prov.Id:null),
                                    Opportunity__c=(pw!=null?pw.prov.Opportunity__c:null),
									Student__c=item.studentId,
									EPC_Utilization_Item__c=item.epcuiId,
									Program__c=item.programId,
									EPC_Weighting__c=epcWeightingId,
									EPCs_Utilized__c=epcsToUtilizeThisProv
						);
						if (doDebug) System.Debug('epcUtilizationToInsert = '+epcUtilizationToInsert);
						epcUtilizationsToInsert.add(epcUtilizationToInsert);

                        //START ToDo abstract to nextOppWrapperWithunutilizedEPCs
                        while (thisProvEPCsRemaining <= 0) {
                            //if we're already on the last Prov EPCU with any EPCs, remaining Actual EPCUs will have no parent Prov EPCU
                            if (lastProvForThisAccount) {
								// these lines remove the reference to the last opportunity
								// commenting out to ensure a weighting from the latest opportunity is found and reflected in the epcus
                                // provIdWithCategoryEpcs=null;
                                // serviceCat_accountIdProvIdWithNextEpcsMap_Map.get(serviceCat).put(itemAccountId,null);
                                break;
                            } else {
                                //Next ProvWrapper, for this serviceCat, for this Account
                                if (provIdProvWrapperMap.get(serviceCat_accountIdProvIdWithNextEpcsMap_Map.get(serviceCat).get(itemAccountId)).nextProvIdWithEpcs != null) {
                                    provIdWithCategoryEpcs = provIdProvWrapperMap.get(serviceCat_accountIdProvIdWithNextEpcsMap_Map.get(serviceCat).get(itemAccountId)).nextProvIdWithEpcs;
                                    serviceCat_accountIdProvIdWithNextEpcsMap_Map.get(serviceCat).put(itemAccountId,provIdWithCategoryEpcs);
                                } else { // we're on the last ProvWrapper with EPCs available
                                    lastProvForThisAccount = TRUE;
                                }

                                thisProvEPCsRemaining = provIdProvWrapperMap.get(provIdWithCategoryEpcs).prov.EPCs_Utilized__c;
                            }
                        }					
					}
				}
			}
		}

        if (!triggerConfig.Validation_Bypass_Opportunity__c) {
            triggerConfig.Validation_Bypass_Opportunity__c=TRUE;
			try{
				update triggerConfig;
			} catch (System.DmlException e) {
				Apex_Exception__e dmlException = new Apex_Exception__e(Message__c=e.getMessage(), TypeName__c=e.getTypeName(), Related_Record_Id__c='');
				Database.SaveResult sr = EventBus.publish(dmlException);
				if (sr.isSuccess()) {
					System.debug('Successfully published event for ' +e.getTypeName());
				} else {
					for(Database.Error err : sr.getErrors()) {
						System.debug('Error publishing event for DmlException - returned: ' +
									err.getStatusCode() +
									' - ' +
									err.getMessage());
					}
				}			
			}
        }
		
		System.Debug('insert epcUtilizationsToInsert : ' + epcUtilizationsToInsert.size() + ' records');

        //need to JSON serialize these and pass them to an @future method for insertion, to avoid CPU time limit problems from doing them synchronously
        insertEpcus(JSON.serialize(epcUtilizationsToInsert));
        // insert epcUtilizationsToInsert;
        
		triggerConfig.Validation_Bypass_Opportunity__c=FALSE;
        try{
            update triggerConfig;
        } catch (System.DmlException e) {
			Apex_Exception__e dmlException = new Apex_Exception__e(Message__c=e.getMessage(), TypeName__c=e.getTypeName(), Related_Record_Id__c='');
			Database.SaveResult sr = EventBus.publish(dmlException);
			if (sr.isSuccess()) {
			    System.debug('Successfully published event for ' +e.getTypeName());
			} else {
			    for(Database.Error err : sr.getErrors()) {
			        System.debug('Error publishing event for DmlException - returned: ' +
			                     err.getStatusCode() +
			                     ' - ' +
			                     err.getMessage());
			    }
			}			
		}
		
		for (Account a:accountsToCalculate) {
			a.EPC_Utilization_Last_Recalc__c = System.Now();
		}
		update accountsToCalculate;
	}

    @future private static void insertEpcus(String epcUtilizationsToInsertJSON) {
        List<EPC_Utilization__c> epcUtilizationsToInsert = (List<EPC_Utilization__c>)JSON.deserialize(epcUtilizationsToInsertJSON, List<EPC_Utilization__c>.class);
        insert epcUtilizationsToInsert;
    }

	public static Double elide(Decimal input) {
		return (input == null) ? 0 : input;
	}

    // ============================================================================================================
    // generateEPCWeightingRecords ================================================================================
    // ============================================================================================================
    //
    // When Opportunities are created, insert a list of EPC Weighting records for that opportunity, which represents the current
    // "list cost" or "list EPC Weighting" for each Service that is currently being offered. Once Closed Won, this Weighting is 
    // memorialized/frozen so that future Student/EPCUI records can correctly debit the correct EPC value from Provisioned EPCU.
    //
    // TODO - Currently only executed at Opp INSERT. If new Services are created (business offerings) while Opp is open, or even
    // after closed won, new Weighting records are not automatically inserted
    // TODO - Updates to Service records (e.g. changes to List EPC Weighting values do not currently trigger updates to EPC_Weighting__c
    // records)
	public static void generateEPCWeightingRecords (Map<Id, Opportunity> opportunityMap) {
		List<Service__c> activeServices = new List<Service__c>([SELECT Id, Name, Marketing_Name__c, List_Weighting__c, Program_Family__c, Program_Family__r.EPC_Weighting__c  FROM Service__c WHERE Status__c='Active']);
		List<Program_Family__c> activeProgramFamilies = new List<Program_Family__c>([SELECT Id, Name, EPC_Weighting__c  FROM Program_Family__c WHERE Status__c='Active']);
		List<EPC_Weighting__c> epcWeightingsToInsert = new List<EPC_Weighting__c>();
		for (Opportunity o:opportunityMap.values()) {
			for (Service__c s:activeServices) {
				if (s.Name.contains('Core Program')) {
					//need a Weighting record for each Program Family
					epcWeightingsToInsert.add(new EPC_Weighting__c(
						Account__c=o.accountId,
						Program_Family__c=s.Program_Family__c,
						EPC_Weighting__c=elide(s.Program_Family__r.EPC_Weighting__c),
						Opportunity__c=o.Id,
						Service__c=s.Id)
					);
				} else {
					//need just one Weighting record for each Service that isn't 'Core Program'
					epcWeightingsToInsert.add(new EPC_Weighting__c(
						Account__c=o.accountId,
						EPC_Weighting__c=s.List_Weighting__c,
						Opportunity__c=o.Id,
						Service__c=s.Id)
					);
				}
			}
		}
		insert epcWeightingsToInsert;
	}
	
}