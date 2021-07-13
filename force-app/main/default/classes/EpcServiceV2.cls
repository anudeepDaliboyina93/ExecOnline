public class EpcServiceV2 implements System.Queueable {

    @TestVisible
    private static Set<Id> accIdsToExecute = new Set<Id>();
    private Set<Id> accountIds;

    public EpcServiceV2(Set<Id> triggeredAccountIds) {
        this.accountIds = getValidAccIdsToExecute(triggeredAccountIds);
    }

    /**
    * Returns a set of Account Ids
    * Removes Account Ids that have already executed in this transactions
    * 
    * @param Set<Id> the set of AccountIds to calculate EPC usage
    * @return Set<Id> the set of AccountIds that haven't been executed yet and have autocalc enabled
    */
    private Set<Id> getValidAccIdsToExecute(Set<Id> triggeredAccountIds) {
        List<Account> triggeredAccountsWithAutoCalcEnabled = [SELECT Id FROM Account WHERE Id IN :triggeredAccountIds AND EPC_Autocalculation_Enabled__c = true];
        Set<Id> validAccIdsToExecute = new Set<Id>();
        for(Account acc : triggeredAccountsWithAutoCalcEnabled) {
            if(!accIdsToExecute.contains(acc.Id)) {
                validAccIdsToExecute.add(acc.Id);
                accIdsToExecute.add(acc.Id);
            }
        }
        return validAccIdsToExecute;
    }
    
    private static Map<String, List<String>> objNameToFieldsToCheckListMap = new Map<String, List<String>>{
        'Student__c'                => new List<String>{'Contact__c','Program__c','Status__c','EPC_Utilization_Date__c','EPCs_Comped__c','EPCs_Deferred__c'},
        'EPC_Utilization_Item__c'   => new List<String>{'EPC_Utilization_Date__c','Status__c'},
        'Contact'                   => new List<String>{'AccountId','Email'},
        'Account'                   => new List<String>{'EPC_Utilization_Force_Recalc__c'}, 
        'Opportunity'               => new List<String>{'CloseDate','StageName'},
        'Program__c'                => new List<String>{'Course_Start_Date__c'}
    };

    public static Boolean shouldFireEpcCalcFromFieldChange(sObject obj1, sObject obj2) {
        String objName = obj1.getSobjectType().getDescribe().getName();
        List<String> fieldsToCheckForChange = objNameToFieldsToCheckListMap.get(objName);
        for(String fieldName : fieldsToCheckForChange) {
            if(ApexUtility.isFieldValDifferent(obj1, obj2, fieldName)) {
                return true;
            }
        }
        return false;
    }

    public void execute(QueueableContext context) {
        // Nothing to execute, skip
        if(this.accountIds.isEmpty()) { 
            return; 
        }

        // Get approved / override count 
        Map<Id, Decimal> utilizedByApprovedOrOverride = getApprovedOrOverrideCount(accountIds);

        // Get relevant Provisioned EPCUs
        Map<Id, ProvisionedWrapper> accIdToProvisionedWrapper = getProvisionedWrappers(accountIds, utilizedByApprovedOrOverride);
		

        // Get all EPCU items, ie. Students, EPCU_Items, EPCU(Type=Adjustment)
        Map<Id, List<EpcuWrapper>> accIdToEpcuWrappers = getEpcuWrappers(accountIds);

        List<Account> updateAccounts = new List<Account>();
        List<EPC_Utilization__c> insertEpcUtilizations = new List<EPC_Utilization__c>();
																 

        for(Id accId : accountIds) {
            ProvisionedWrapper provWrapper = accIdToProvisionedWrapper.get(accId);
            List<EpcuWrapper> epcuWrappers = accIdToEpcuWrappers.get(accId);
            
            // Account has provisioned EPCs and Actuals to process
            if(provWrapper != null && epcuWrappers != null) {
                for(EpcuWrapper epcuw : epcuWrappers) {
					
                    Decimal startingEpcWeighting = epcuw?.EpcWeighting;
                    system.debug(startingEpcWeighting);
                    Boolean isUnlimitedUsage = false;
                    EPC_Weighting__c epcWeightingOverride = getEpcWeightingOverride(epcuw, provWrapper.provisionedEpc.Opportunity__c);

                    if(epcWeightingOverride != null) {
                        startingEpcWeighting = epcWeightingOverride?.EPC_Weighting__c;
                        if(epcWeightingOverride.Is_Unlimited__c) {
                            isUnlimitedUsage = true;
                            startingEpcWeighting = 0;
                        }
                    }
                    Decimal epcsToActualizeRemaining = startingEpcWeighting == null ? 0 : startingEpcWeighting - epcuw?.EpcsComped - epcuw?.EpcsDeferred - epcuw?.EpcsDiscounted;

																															 
                    
                    // This loop allows a single real usage to be split across multiple EPCU Actuals
                    // if the first Provisioned EPCU cannot fulfill the entire Actual
                    while(epcsToActualizeRemaining > 0 || isUnlimitedUsage == true) {
                        // EPCs to Actualize this EPCU Actual
                        Decimal epcsToActualize = epcsToActualizeRemaining;

                        if(provWrapper.availableEpcs < epcsToActualize) {
                            // Can only Actualize the amount of available EPCs on the current Provisioned
                            epcsToActualize = provWrapper.availableEpcs;
                        }
                        // EPCs to Actualize on the next loop iteration
                        epcsToActualizeRemaining = epcsToActualizeRemaining - epcsToActualize;

                        if (!epcuw.isApproved && !epcuw.isOverride){

                            // Subtract the EPCs to Actualize this time from the available EPCs on Provisioned
                            provWrapper.availableEpcs = provWrapper.availableEpcs - epcsToActualize;
    
                            insertEpcUtilizations.add(new EPC_Utilization__c(
                                Type__c = epcuw.IsAdjustment ? 'Adjustment' : 'Actual',
                                Account__c = epcuw.AccountId,
                                Provisioned_EPCU__c = isUnlimitedUsage ? null : provWrapper.provisionedEpc.Id,
                                Opportunity__c = isUnlimitedUsage ? epcWeightingOverride.Opportunity__c : provWrapper.provisionedEpc.Opportunity__c,
                                Student__c = epcuw.StudentId,
                                EPC_Utilization_Item__c = epcuw.EpcuiId,
                                Category__c = epcuw.Category,
                                Program__c = epcuw.ProgramId,
                                EPC_Weighting__c = epcWeightingOverride == null ? null : epcWeightingOverride.Id,
                                EPCs_Utilized__c = epcsToActualize,
                                Manual_Adjustment_Date__c = epcuw.IsAdjustment ? epcuw.EpcUtilizationDate : null,
                                Adjustment_Program_Period__c =  epcuw.IsAdjustment ? epcuw.AdjustmentProgramPeriod : null
                        
                            ));
                            }
                    	
                        // Continue to the next Provisioned Wrapper if it exists
                        // Otherwise keep using the last known Provisioned Wrapper 
                        if(provWrapper.availableEpcs == 0 && provWrapper.next != null) {
                            provWrapper = provWrapper.next;
                        }
                        // This allows overflow of EPCU Actuals
                        // If the last Provisioned EPCU runs out of EPCs, it allows the process to complete
                        // by continuing to link the Actuals to the last known Provisioned keeping the same weighting
                        if(provWrapper.availableEpcs == 0 && provWrapper.next == null) {
                            provWrapper.availableEpcs = 9999;
                        }
                        isUnlimitedUsage = false;
	
                    }
                }
            }

            updateAccounts.add(new Account(Id = accId, EPC_Utilization_Last_Recalc__c = System.now()));
        }

        if(insertEpcUtilizations.size() > 0 || updateAccounts.size() > 0) {
            insertEpcuActualsUpdateAccounts(JSON.serialize(insertEpcUtilizations), JSON.serialize(accountIds));
        }

    }

    /**
    * Returns a map of AccountId to linked list of local class Provisioned Wrapper
    * The linked list starts with the oldest provisioned EPCU record and ascends via the next Provisioned prop
    * 
    * @param Set<Id> the set of AccountIds to populate provisioned wrappers
    * @return the map of AccountId to ProvisionedWrapper linked list
    */
    private Map<Id, ProvisionedWrapper> getProvisionedWrappers(Set<Id> accountIds, Map<Id, Decimal> overrideValues) {
        List<EPC_Utilization__c> provisionedEpcus = [
            SELECT Id, Account__c, Name, Type__c, Adjustment_Date__c, Opportunity__c, Opportunity__r.CloseDate, Opportunity__r.Name, EPCs_Utilized__c, Service_Category__c 
            FROM EPC_Utilization__c 
            WHERE Account__c IN :accountIds AND 
                ((Type__c='Provisioned' AND EPCs_Utilized__c!=0 AND EPCs_Utilized__c!=null)
                OR (Type__c='Finance Adjustment' AND EPCs_Utilized__c > 0))
            ORDER BY Type__c ASC, Opportunity__r.CloseDate ASC
        ];
        List<EPC_Utilization__c> provisionedAdjustmentEpcus = new List<EPC_Utilization__c>();
        for(Integer i = 0; i < provisionedEpcus.size(); i++) {
            if(provisionedEpcus[i].Type__c == 'Provisioned') {
                break;
            }
            provisionedAdjustmentEpcus.add(provisionedEpcus.remove(i));
            i--;
        }
        List<EPC_Utilization__c> sortedProvisionedEpcus = new List<EPC_Utilization__c>();
        for(Integer i = 0; i < provisionedEpcus.size(); i++) {
            if(provisionedAdjustmentEpcus.isEmpty()) {
                break;
            }
            if(provisionedAdjustmentEpcus[0].Adjustment_Date__c < provisionedEpcus[i].Opportunity__r.CloseDate) {
                sortedProvisionedEpcus.add(provisionedAdjustmentEpcus.remove(0));
            } else {
                sortedProvisionedEpcus.add(provisionedEpcus.remove(i));
                i--;
            }
        }
        if(!provisionedEpcus.isEmpty()) {
            sortedProvisionedEpcus.addAll(provisionedEpcus);
        }
        Map<Id, ProvisionedWrapper> accIdToProvisionedWrapper = new Map<Id, ProvisionedWrapper>();
        for(EPC_Utilization__c epcu : sortedProvisionedEpcus) {

            Decimal overrides = overrideValues.get(epcu.Id);
 
            if (overrides == null){
                accIdToProvisionedWrapper.put(epcu.Account__c, linkProvisionedWrappers(accIdToProvisionedWrapper.get(epcu.Account__c), new ProvisionedWrapper(epcu)));

            }
            else if (epcu.EPCs_Utilized__c - overrides > 0){
                
                epcu.EPCs_Utilized__c = epcu.EPCs_Utilized__c - overrides;
                accIdToProvisionedWrapper.put(epcu.Account__c, linkProvisionedWrappers(accIdToProvisionedWrapper.get(epcu.Account__c), new ProvisionedWrapper(epcu)));
            }	 
        }

        if (accIdToProvisionedWrapper.size() == 0){
            Integer lastIndex = provisionedEpcus.size() != 0 ? provisionedEpcus.size() -1 : 0;
            EPC_Utilization__c lastEPC = provisionedEpcus.size() != 0 ? provisionedEpcus[lastIndex] : null;
            if (lastEPC != null){
                accIdToProvisionedWrapper.put(lastEPC.Account__c, new ProvisionedWrapper(lastEPC));
            }
            
        }
        return accIdToProvisionedWrapper;
    }

    public Map<Id, Decimal> getApprovedOrOverrideCount(Set<Id> accountIds){

        List<EPC_Utilization__c> approvedOrOverrideUtilization = [SELECT Id, Student__r.Override_EPCU__c, EPC_Utilization_Item__r.Student__r.Override_EPCU__c,
                                                                        Student__r.Approved__c, EPC_Utilization_Item__r.Student__r.Approved__c, Provisioned_EPCU__c,
                                                                        EPCs_Utilized__c 
                                                                        FROM EPC_Utilization__c 
                                                                        WHERE Account__c IN: accountIds
                                                                        AND ((Type__c!='Provisioned' AND EPCs_Utilized__c!=0 AND EPCs_Utilized__c!=null)
                                                                        OR (Type__c!='Finance Adjustment' AND EPCs_Utilized__c > 0))
                                                                        AND ((Student__r.Override_EPCU__c = true OR EPC_Utilization_Item__r.Student__r.Override_EPCU__c = true) 
                                                                        OR (Student__r.Approved__c = true OR EPC_Utilization_Item__r.Student__r.Approved__c = true))];

        Map<Id, Decimal> provisionedEpcsUsed = new Map<Id, Decimal>();      
        
        system.debug(approvedOrOverrideUtilization.size());

        for (EPC_Utilization__c epc : approvedOrOverrideUtilization){
            Decimal count = provisionedEpcsUsed.get(epc.Provisioned_EPCU__c);

            if (count == null){
                count = epc.EPCs_Utilized__c;
                provisionedEpcsUsed.put(epc.Provisioned_EPCU__c, count);
                
            }

            else if (count != null){
                count = count + epc.EPCs_Utilized__c;

                provisionedEpcsUsed.put(epc.Provisioned_EPCU__c, count);
            }
        } 
        
        return provisionedEpcsUsed;
    }
    private class ProvisionedWrapper {
        EPC_Utilization__c provisionedEpc {get;set;}
        Decimal availableEpcs {get;set;}
        ProvisionedWrapper next {get;set;}
        public ProvisionedWrapper(EPC_Utilization__c provisionedEpc) {
            this.provisionedEpc = provisionedEpc;
            this.availableEpcs = provisionedEpc.EPCs_Utilized__c;
			
			
        }
    }
    public ProvisionedWrapper linkProvisionedWrappers(ProvisionedWrapper root, ProvisionedWrapper next) {
        if(root == null) {
            root = next;
        } else {
            ProvisionedWrapper temp = root;
            while(temp.next != null) {
                temp = temp.next;
            }
            temp.next = next;
        }
        return root;
    }

    /**
    * Returns a map of AccountId to list of local class EPCU Wrapper
    * The list is sorted by EPC Utilization date and a polymorphed wrapper of Student, EPCUI, EPCU(Adjustment)
    * 
    * @param Set<Id> the set of AccountIds to populate EPCU Wrappers
    * @return the map of AccountId to EPCU Wrapper list
    */
    private Map<Id, List<EpcuWrapper>> getEpcuWrappers(Set<Id> accountIds) {
        Map<Id, List<EpcuWrapper>> accIdToEpcuWrappers = new Map<Id, List<EpcuWrapper>>();
        List<EpcuWrapper> epcuWrappers = new List<EpcuWrapper>();
        epcuWrappers.addAll(getStudentEpcuWrappers(accountIds));
        epcuWrappers.addAll(getEpcuiEpcuWrappers(accountIds));
        epcuWrappers.addAll(getAdjustmentEpcuWrappers(accountIds));
        for(EpcuWrapper epcuw : epcuWrappers) {
            if(accIdToEpcuWrappers.get(epcuw.AccountId) == null) {
                accIdToEpcuWrappers.put(epcuw.AccountId, new List<EpcuWrapper>()); 
            }
            accIdToEpcuWrappers.get(epcuw.AccountId).add(epcuw);
        }
        for(List<EpcuWrapper> epcuList : accIdToEpcuWrappers.values()) {
            // Sort the EPCU Wrappers by Utilization date/Adjustment date
            epcuList.sort();
        }
        return accIdToEpcuWrappers;
    }
    private class EpcuWrapper implements Comparable {
        Student__c Student;
        EPC_Utilization_Item__c Epcui;
        EPC_Utilization__c Epcu;

        Id StudentId;
        Id EpcuiId;
        Id EpcuId;

        Id AccountId;
        Id ServiceId;
        Date EpcUtilizationDate;
        Decimal EpcWeighting;
        Boolean IsAdjustment = false;
        Id AdjustmentProgramPeriod;
        Boolean isApproved = false;
        Boolean isOverride = false;
								   

        String Category;
        Id ProgramId;

        Decimal EpcsComped = 0;
        Decimal EpcsDeferred = 0;
        Decimal EpcsDiscounted = 0;

        public EpcuWrapper(Student__c student) {
            this.Student = student;
            this.StudentId = student.Id;
            this.AccountId = student.Contact__r.AccountId;
            this.ServiceId = student.Program__r.Program_Family__r.Primary_Service__c;
            this.EpcUtilizationDate = student.EPC_Utilization_Date__c;
            this.EpcWeighting = student.Program__r.Program_Family__r.Primary_Service__r.List_Weighting__c;
			this.isApproved = student.Approved__c;
            this.isOverride = student.Override_EPCU__c;							  
													   
            if(student.EPCs_Comped__c > 0) {
                this.EpcsComped = student.EPCs_Comped__c;
            }
            if(student.EPCs_Deferred__c > 0) {
                this.EpcsDeferred = student.EPCs_Deferred__c;
            }
            this.Category = 'Core Program';
            this.ProgramId = student.Program__c;
        }
        public EpcuWrapper(EPC_Utilization_Item__c epcui) {
            this.Epcui = epcui;
            this.EpcuiId = epcui.Id;
            this.AccountId = epcui.Contact__r.AccountId;
            this.ServiceId = epcui.Service__c;
            this.EpcUtilizationDate = epcui.EPC_Utilization_Date__c;
            this.EpcWeighting = epcui.Service__r.List_Weighting__c;
            this.Category = epcui.Category__c;
            if(epcui.Student__c != null) {
                this.ProgramId = epcui.Student__r.Program__c;
				this.isApproved = epcui.Student__r.Approved__c;
                this.isOverride = epcui.Student__r.Override_EPCU__c;									   
																	
            }
            if(epcui.EPCs_Comped__c > 0) {
                this.EpcsComped = epcui.EPCs_Comped__c;
            }
            if(epcui.EPCs_Deferred__c > 0) {
                this.EpcsDeferred = epcui.EPCs_Deferred__c;
            }
            if(epcui.EPCs_Discounted__c > 0) {
                this.EpcsDiscounted = epcui.EPCs_Discounted__c;
            }
        }
        public EpcuWrapper(EPC_Utilization__c epcu) {
            this.Epcu = epcu;
            this.EpcuId = epcu.Id;
            this.AccountId = epcu.Account__c;
            this.ServiceId = epcu.Program__r.Program_Family__r.Primary_Service__c;
            this.EpcUtilizationDate = epcu.Adjustment_Date__c;
            this.EpcWeighting = epcu.EPCs_Utilized__c * -1;
            this.IsAdjustment = true;
            this.AdjustmentProgramPeriod = epcu.Adjustment_Program_Period__c;
        }

        public Integer compareTo(Object obj){
            EpcuWrapper epcuw = (EpcuWrapper)obj;
            if (this.epcUtilizationDate > epcuw.epcUtilizationDate) {
                return 1;
            }
            return -1;
        }
    }
    private List<EpcuWrapper> getStudentEpcuWrappers(Set<Id> accountIds) {
        List<Student__c> students = [
            SELECT Id, Status__c, EPC_Utilization_Date__c, Contact__c, Contact__r.Email, 
                Contact__r.AccountId, Program__c, Program__r.Program_Family__c, Program__r.Program_Family__r.Primary_Service__c,
                Program__r.Program_Family__r.Primary_Service__r.List_Weighting__c, EPCs_Comped__c, EPCs_Deferred__c, Approved__c,
                Override_EPCU__c
								
            FROM Student__c 
            WHERE Contact__r.AccountId IN :accountIds AND Status_Utilized__c = TRUE AND Approved__c = false AND Override_EPCU__c = false
            ORDER BY Contact__r.AccountId, EPC_Utilization_Date__c, CreatedDate, Contact__r.LastName, Contact__r.Firstname, Id
        ];
        List<EpcuWrapper> epcuWrappers = new List<EpcuWrapper>();
        for(Student__c student : students) {
            system.debug(student.Program__r.Program_Family__r.Primary_Service__r.List_Weighting__c);
            epcuWrappers.add(new EpcuWrapper(student));
        }
        return epcuWrappers;
    }
    private List<EpcuWrapper> getEpcuiEpcuWrappers(Set<Id> accountIds) {
        List<EPC_Utilization_Item__c> epcuis = [
            SELECT Id, Status__c, EPC_Utilization_Date__c, Contact__c, Contact__r.Email, 
                Contact__r.AccountId, Student__r.Contact__c, Student__r.Program__c, Student__r.Program__r.Program_Family__c, 
                Category__c, Service__c, Service__r.Service_Category__c, Service__r.List_Weighting__c, EPCs_Comped__c, EPCs_Deferred__c, EPCs_Discounted__c,
				Student__r.Approved__c, Student__r.Override_EPCU__c
																   
            FROM EPC_Utilization_Item__c 
            WHERE Contact__r.AccountId IN :accountIds AND Status_Utilized__c = TRUE AND Student__r.Override_EPCU__c = false
            ORDER BY Contact__r.AccountId, EPC_Utilization_Date__c, CreatedDate, Contact__r.LastName, Contact__r.Firstname, Id
        ];
        system.debug(epcuis);
        List<EpcuWrapper> epcuWrappers = new List<EpcuWrapper>();
        for(EPC_Utilization_Item__c epcui : epcuis) {
            epcuWrappers.add(new EpcuWrapper(epcui));

        }
        return epcuWrappers;
    }
    private List<EpcuWrapper> getAdjustmentEpcuWrappers(Set<Id> accountIds) {
        List<EPC_Utilization__c> adjustmentEpcus = [
            SELECT Id, Adjustment_Date__c, Account__c, EPCs_Utilized__c, Program__r.Program_Family__r.Primary_Service__c, Adjustment_Program_Period__c
            FROM EPC_Utilization__c 
            WHERE Account__c IN :accountIds AND Type__c IN ('Finance Adjustment')
            ORDER BY Account__c, Adjustment_Date__c
        ];
        List<EpcuWrapper> epcuWrappers = new List<EpcuWrapper>();
        for(EPC_Utilization__c epcu : adjustmentEpcus) {
            epcuWrappers.add(new EpcuWrapper(epcu));
        }
        return epcuWrappers;
    }

    /**
    * Returns the EPC Weighting record that acts as an override for the default value on Service__c
    *
    * Maps with keys as Ids have better performance than a concat String key of accIdOppId + serviceId
    * 30-50% better performance depending on server load
    * Refactored to Map<String, List<EPC_Weighting__c>> instead of a double nested map and performance got worse
    * 
    * @param epcuWrapper the EPC Actual Wrapper that will be creating
    * @param provisionedOppId the EPC Provisioned Opportunity Id
    * @return the EPC_Weighting__c override record
    */
    Map<Id, Map<Id, List<EPC_Weighting__c>>> accIdOppIdToServiceIdToWeightingListMap;
    private EPC_Weighting__c getEpcWeightingOverride(EpcuWrapper epcuWrapper, Id provisionedOppId) {
        populateWeightingsMap();
        EPC_Weighting__c matchingWeightingOverride;
        List<EPC_Weighting__c> serviceRelatedWeightings = new List<EPC_Weighting__c>();
        // Add Opportunity weightings first
        if(accIdOppIdToServiceIdToWeightingListMap.containsKey(provisionedOppId)) {
            List<EPC_Weighting__c> oppServiceRelatedWeightings = accIdOppIdToServiceIdToWeightingListMap.get(provisionedOppId).get(epcuWrapper.ServiceId);
            
            if(oppServiceRelatedWeightings != null) {
                serviceRelatedWeightings.addAll(oppServiceRelatedWeightings);
            }
        }
        // Add Account weightings second, Account weightings override Opportunity weightings
        if(accIdOppIdToServiceIdToWeightingListMap.containsKey(epcuWrapper.AccountId)) {
            List<EPC_Weighting__c> accServiceRelatedWeightings = accIdOppIdToServiceIdToWeightingListMap.get(epcuWrapper.AccountId).get(epcuWrapper.ServiceId);
            
            if(accServiceRelatedWeightings != null) {
                serviceRelatedWeightings.addAll(accServiceRelatedWeightings);
            }
        }
        for(EPC_Weighting__c weighting : serviceRelatedWeightings) {
            if(isEpcuWithinWeightingDates(epcuWrapper, weighting)) {
                matchingWeightingOverride = weighting;
            }
        }
        return matchingWeightingOverride;
    }
    private void populateWeightingsMap() {
        if(accIdOppIdToServiceIdToWeightingListMap != null) {
            return;
        }
        accIdOppIdToServiceIdToWeightingListMap = new Map<Id, Map<Id, List<EPC_Weighting__c>>>();
        List<EPC_Weighting__c> allRelatedAccWeightings = [SELECT Id, Account__c, Opportunity__c, Service__c, EPC_Weighting__c, Is_Unlimited__c, Start_Date__c, End_Date__c
                                                            FROM EPC_Weighting__c 
                                                            WHERE (Account__c IN :this.accountIds AND Opportunity__c = null)
                                                                OR (Opportunity__r.AccountId IN :this.accountIds AND Opportunity__r.StageName = 'Closed/Won')
                                                            ORDER BY CreatedDate ASC];
        for(EPC_Weighting__c weighting : allRelatedAccWeightings) {
            Id accIdOrOppId = weighting.Opportunity__c == null || weighting.Is_Unlimited__c ? weighting.Account__c : weighting.Opportunity__c;

            // Find the accId or oppId key to serviceIdToWeightingList
            if(!accIdOppIdToServiceIdToWeightingListMap.containsKey(accIdOrOppId)) {
                accIdOppIdToServiceIdToWeightingListMap.put(accIdOrOppId, new Map<Id, List<EPC_Weighting__c>>());
            }
            // Find the serviceId to weighting list
            if(!accIdOppIdToServiceIdToWeightingListMap.get(accIdOrOppId).containsKey(weighting.Service__c)) {
                accIdOppIdToServiceIdToWeightingListMap.get(accIdOrOppId).put(weighting.Service__c, new List<EPC_Weighting__c>());
            }
            accIdOppIdToServiceIdToWeightingListMap.get(accIdOrOppId).get(weighting.Service__c).add(weighting);
        }
    }
    private Boolean isEpcuWithinWeightingDates(EpcuWrapper epcuw, EPC_Weighting__c weighting) {
        if(weighting.Start_Date__c == null || weighting.End_Date__c == null) {
            return true;
        }
        if(weighting.Start_Date__c <= epcuw.EpcUtilizationDate && epcuw.EpcUtilizationDate <= weighting.End_Date__c) {
            return true;
        }
        return false;
    }

    
    /**
    * Future method to insert and delete the new Actual EPCUs and mark Accounts last EPC run time
    * The need for future method is because during insert of EPCU it fires various triggers
    * Eg. Account trigger, this causes slowness during UI data changes
    * 
    * @param String the JSON string of Actual EPCUs to deserialize and insert
    * @param String the JSON string of Accounts to deserialize and update
    */
    @future 
    private static void insertEpcuActualsUpdateAccounts(String insertEpcUtilizationsJson, String accountIds) {

		Set<Id> accountIdSet = (Set<Id>)JSON.deserialize(accountIds, Set<Id>.class);	

		delete [SELECT Id FROM EPC_Utilization__c WHERE Type__c IN ('Actual', 'Adjustment', '') AND Account__c IN :accountIdSet
				AND ((Student__c = null AND EPC_Utilization_Item__r.Student__r.Approved__c = false)
                OR (Student__r.Approved__c = false AND EPC_Utilization_Item__c = null))
                AND ((Student__r.Override_EPCU__c = false AND EPC_Utilization_Item__c = null)
                OR (Student__c = null AND EPC_Utilization_Item__r.Student__r.Override_EPCU__c = false))];
		
        List<EPC_Utilization__c> insertEpcUtilizations = (List<EPC_Utilization__c>)JSON.deserialize(insertEpcUtilizationsJson, List<EPC_Utilization__c>.class);
        if(insertEpcUtilizations.size() > 0) {
		
		    Account [] accts = [SELECT Id FROM Account WHERE Id IN:accountIdSet FOR UPDATE];

            insert insertEpcUtilizations;
 
        }

        calculateAccountLevelBalances((Set<Id>)JSON.deserialize(accountIds, Set<Id>.class));
    }

    private static void calculateAccountLevelBalances(Set<Id> accountIds) {
        Date actualizeBeforeThisDate = Date.today();
        List<AggregateResult> epcus = [SELECT Account__c, Type__c, SUM(EPCs_Utilized__c) epcs, EPC_Utilization_Date__c 
                                        FROM EPC_Utilization__c 
                                        WHERE Account__c IN :accountIds
                                            AND (Type__c != 'Adjustment') 
                                        GROUP BY Account__c, Type__c, EPC_Utilization_Date__c];

        Map<Id, Account> accountMap = new Map<Id, Account>();
        for(AggregateResult ar : epcus) {
            Id accountId = (Id)ar.get('Account__c');
            Account acc = accountMap.get(accountId);
            if(acc == null) {
                acc = new Account(Id = accountId, EPC_Utilization_Last_Recalc__c = System.now(), EPCs_Total_Purchased__c = 0, EPCs_Total_Utilized__c = 0, EPCs_Total_Reserved__c = 0, EPCs_Total_Adjustments__c = 0);
            }
            switch on (String)ar.get('Type__c') {
                when 'Provisioned' {
                    acc.EPCs_Total_Purchased__c += (Decimal)ar.get('epcs');
                }
                when 'Actual' {
                    if((Date)ar.get('EPC_Utilization_Date__c') > actualizeBeforeThisDate) {
                        acc.EPCs_Total_Reserved__c += (Decimal)ar.get('epcs');
                    } else {
                        acc.EPCs_Total_Utilized__c += (Decimal)ar.get('epcs');
                    }
                }
                when 'Finance Adjustment' {
                    acc.EPCs_Total_Adjustments__c += (Decimal)ar.get('epcs');
                }
            }
            accountMap.put(accountId, acc);
        }
        if(accountMap.size() > 0) {
            update accountMap.values();
        }
    }

    public void insertProvisionedEpcs(List<Opportunity> newClosedWonOppsList) {
        //AD EDITED-------6 JULY 2021
        TRG_Opportunity_Helper.createProvisionedEPCUs(newClosedWonOppsList);
        //---------------------------
        //Commenting remaining lines to make sure the lines added above work.
        /*List<EPC_Utilization__c> newProvisionedEpcus = new List<EPC_Utilization__c>();
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>(newClosedWonOppsList);
        Map<String, OpportunityLineItem> oLineItemMap = new Map<String, OpportunityLineItem>();

        List<OpportunityLineItem> oppLineItems = [SELECT Id, Quantity, Service_Category__c, Opportunity.AccountId, CreatedDate, Product2.Name 
                                                  FROM OpportunityLineItem
                                                  WHERE 
                                                  (Product2.Name = 'EPC' OR Product2.ProductCode = 'AEP') 
                                                  AND Quantity > 0 AND OpportunityId in :opportunityMap.keySet()
                                                  ORDER BY CreatedDate
                                                 ];
        
        Decimal totalEPCS = 0;

        for (OpportunityLineItem oli : oppLineItems) {
            if (oli.Service_Category__c==null) {
                oli.Service_Category__c = 'All';
            }

            if (oli.Product2.Name == 'EPC'){
                totalEPCS = totalEPCS + oli.Quantity;
                oLineItemMap.put('EPC', oli);
            }
            
            else {

                oLineItemMap.put('AEP', oli);
            }
        } 

        if(totalEPCS > 0) {

            OpportunityLineItem oli = oLineItemMap?.get('EPC');

            EPC_Utilization__c newEPC = new EPC_Utilization__c(
                Account__c = oli.Opportunity.AccountId, 
                Opportunity__c = oli.OpportunityId, 
                EPCs_Utilized__c = totalEPCS, 
                Service_Category__c = oli.Service_Category__c, 
                Type__c = 'Provisioned');

                newProvisionedEpcus.add(newEPC);	  
        }

        if (oLineItemMap.get('AEP') != null){

            OpportunityLineItem oli = oLineItemMap?.get('AEP');

            EPC_Utilization__c newEPC = new EPC_Utilization__c(
                Account__c = oli.Opportunity.AccountId, 
                Opportunity__c = oli.OpportunityId, 
                EPCs_Utilized__c = 0, 
                Service_Category__c = oli.Service_Category__c, 
                Type__c = 'Provisioned');

                newProvisionedEpcus.add(newEPC);

        }



        if (!newProvisionedEpcus.isEmpty()){
            
            insert newProvisionedEpcus;
        }*/
    }

}