public class OpportunityUseCaseConfigController {
	@AuraEnabled
    public static ComponentElements getUseCaseOppRecords(String opportunityId, String accountId) {
    	ComponentElements compElements = new ComponentElements();
        try {
            List<Use_Case_Opportunity__c > useCaseOppList = [SELECT Id, Name, Use_Case__r.Id, Use_Case__r.Name, Status__c FROM Use_Case_Opportunity__c WHERE Opportunity__c =: opportunityId AND Status__c = 'Active'];
        	compElements.useCaseOppList = useCaseOppList;
        	setAllFields(compElements);
            getUseCaseRecords(compElements, opportunityId, accountId);
        }  catch(Exception e) {
            throw new AuraHandledException('Unable to get records. please check logs.');
        }
        return compElements;
    }

    @AuraEnabled
    public static void setAllFields( ComponentElements compElements) {
    	Map<String, Schema.FieldSet> fieldSets = Schema.getGlobalDescribe().get('Use_Case__c').getDescribe().FieldSets.getMap();
    	List<Schema.FieldSetMember> accordianFields = fieldSets.get('UseCaseAccordionFields') != null ? fieldSets.get('UseCaseAccordionFields').getFields() : null;
    	if(accordianFields != null && !accordianFields.isEmpty()){
    		for(Schema.FieldSetMember obj : accordianFields){
    			compElements.useCaseAccordianFieldsList.add(new FieldObject(obj.getFieldPath(), obj.getLabel()));
    		}
    	}
    	List<Schema.FieldSetMember> newEditFields = fieldSets.get('UseCaseNewEditForm') != null ? fieldSets.get('UseCaseNewEditForm').getFields() : null;
    	if(newEditFields != null && !newEditFields.isEmpty()){
    		for(Schema.FieldSetMember obj : newEditFields){
    			compElements.useCaseNewEditFieldsList.add(new FieldObject(obj.getFieldPath(), obj.getLabel()));
    		}
    	}
    	List<Schema.FieldSetMember> listBuilderFields = fieldSets.get('UseCaseListBuilderColumns') != null ? fieldSets.get('UseCaseListBuilderColumns').getFields() : null;
    	if(listBuilderFields != null && !listBuilderFields.isEmpty()){
    		for(Schema.FieldSetMember obj : listBuilderFields){
    			compElements.useCaseListBuilderFieldsList.add(new FieldObject(obj.getFieldPath(), obj.getLabel()));
    		}
    	}
    }

    @AuraEnabled
    public static void saveUseCaseOppRecord(Use_Case_Opportunity__c record) {
        try {
            insert record;
        }  catch(Exception e) {
            throw new AuraHandledException('Unable to save record. please check logs.');
        }
    }

    @AuraEnabled 
    public static void getUseCaseRecords(ComponentElements compElements, String opportunityId, String accId){
        Set<String> useCaseIds = new Set<String>();
        List<Use_Case__c> useCaseList = [Select id,
                                                Account__c, 
                                                (Select id,Opportunity__c, Status__c from Use_Case_Opportunities__r where Opportunity__c =: opportunityId AND Status__c != 'Removed')  
                                                from Use_Case__c 
                                                WHERE Account__c =: accId
                                                ];
        if(!useCaseList.isEmpty()){
            for(Use_Case__c useCaseObj : useCaseList){
                if(useCaseObj.Use_Case_Opportunities__r == null || useCaseObj.Use_Case_Opportunities__r.isEmpty()){
                    useCaseIds.add(useCaseObj.Id);
                }
            }
            String query = 'SELECT Id, ';
            List<FieldObject> fields = compElements.useCaseListBuilderFieldsList;
            for(FieldObject obj : fields){
                query = query + obj.apiName + ', ';
            }
            query = query.removeEndIgnoreCase(', ');
            query = query + ' FROM Use_Case__c WHERE Id IN: useCaseIds';
            compElements.useCaseList = (List<Use_Case__c>) Database.query(query);
        } 
        
    }  

    @AuraEnabled
    public static void insertUseCaseOppRecords(String opportunityId, List<String> recordIds) {
        try {
            List<Use_Case_Opportunity__c> useCaseOppList = new List<Use_Case_Opportunity__c>();
            for(String useCaseId : recordIds){
                Use_Case_Opportunity__c useCaseOppObj = new Use_Case_Opportunity__c(Opportunity__c = opportunityId, 
                                                            Use_Case__c = useCaseId, 
                                                            Status__c = 'Active');
                useCaseOppList.add(useCaseOppObj);
            }
            insert useCaseOppList;
        }  catch(Exception e) {
            throw new AuraHandledException('Unable to save record. please check logs.');
        }
    }     

    @AuraEnabled
    public static void updateUseCase(Use_Case_Opportunity__c useCaseOpp, Use_Case__c useCase) {
        try {
            update useCase;
            update useCaseOpp;
        }  catch(Exception e) {
            throw new AuraHandledException('Unable to remove. please check logs.');
        }
    } 

    public class ComponentElements{
    	@AuraEnabled public List<Use_Case_Opportunity__c> useCaseOppList;
        @AuraEnabled public List<Use_Case__c> useCaseList;
    	@AuraEnabled public List<FieldObject> useCaseAccordianFieldsList;
    	@AuraEnabled public List<FieldObject> useCaseNewEditFieldsList;
    	@AuraEnabled public List<FieldObject> useCaseListBuilderFieldsList;

    	public ComponentElements(){
    		this.useCaseOppList = new List<Use_Case_Opportunity__c>();
    		this.useCaseAccordianFieldsList = new List<FieldObject>();
    		this.useCaseNewEditFieldsList = new List<FieldObject>();
			this.useCaseListBuilderFieldsList = new List<FieldObject>();
            this.useCaseList = new List<Use_Case__c>();
    	}
    }

    public class FieldObject{
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;

        public FieldObject(String apiName, String label){
            this.apiName = apiName;
            this.label = label;
        }
    }
}