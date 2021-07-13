({
	doInit : function(component) {
        var oppId = component.get('v.oppId');
        var recordId = component.get('v.recordId');
        if(!oppId && recordId) {
            component.set('v.oppId', recordId);
        } else {
            this.getUseCaseOppRecords(component);
        }
    },
    
    getUseCaseOppRecords : function(component) {
		var action = component.get("c.getUseCaseOppRecords");
        action.setParams({
            opportunityId : component.get("v.oppId"),
            accountId : component.get("v.accountId")
        });
        action.setCallback(this, function(response) {
            if (response.getState() === 'SUCCESS') {
            	var result = response.getReturnValue();
            	if(!$A.util.isEmpty(result)){
            		if($A.util.isEmpty(result.useCaseOppList)){
            			component.set("v.noResult", true);
            		} else{
            			component.set("v.noResult", false);
            		}
            		component.set("v.useCaseOpportunityList", result.useCaseOppList);
            		component.set("v.useCaseAccordianFieldsList", result.useCaseAccordianFieldsList);
            		component.set("v.useCaseNewEditFieldsList", result.useCaseNewEditFieldsList);
            		component.set("v.useCaseListBuilderFieldsList", result.useCaseListBuilderFieldsList);
                    component.set("v.useCaseList", result.useCaseList);  
            	}
                component.set("v.showSpinner", false);
            } else if(response.getState() === 'Error') {
            	var errors = response.getError();
            	var message = '';
            	if(Array.isArray(error)){
            		errors.forEach(function(element){
						message = message + '\n' + element.message;
					});	
            	} else{
            		message =  errors.message;
            	} 
                component.set("v.showSpinner", false);              
            }
        });
        $A.enqueueAction(action);
    },

	handleButtonMenu : function(component, event) {
		var self = this;
		var value = event.getParam("value");
		if(!$A.util.isEmpty(value)){
			var action = value.split("-", 2)[0];
			var id = value.split("-", 2)[1];
			switch(action) {
	            case "View": 
	            	window.open(window.location.origin + '/' + id, '_blank'); 
	            	break;
	            case "Edit": 
                    component.set("v.showSpinner", true);
                    $A.createComponent(
                        "c:OpportunityEditUseCaseComponent", {
                            fields: component.get("v.useCaseNewEditFieldsList"),
                            opportunityId : component.get("v.oppId"),
                            recordId : id
                        },
                        function (msgBox) {
                            if (component.isValid()) {
                                var targetCmp = component.find('EditUseCaseModel');
                                var body = targetCmp.get("v.body");
                                body.push(msgBox);
                                targetCmp.set("v.body", body);
                            }
                            component.set("v.showSpinner", false);
                        }
                    );
		            break;
	            case "Remove":  
                    component.set("v.showSpinner", true);
                    $A.createComponent(
                        "c:OpportunityUseCaseRemoveComponent", {
                            recordId : id
                        },
                        function (msgBox) {
                            if (component.isValid()) {
                                var targetCmp = component.find('ConfirmRemoveUseCase');
                                var body = targetCmp.get("v.body");
                                body.push(msgBox);
                                targetCmp.set("v.body", body);
                            }
                            component.set("v.showSpinner", false);
                        }
                    );
		            break;
	        }
		}
	},
    removeUseCase : function(component, recordId) {
        var self = this;
        var recordViewForm = component.find("recordViewForm");
        if(!$A.util.isEmpty(recordViewForm)){
            if(Array.isArray(recordViewForm)){
                recordViewForm.every(function(element){
                    if(element.get("v.useCaseId") === recordId){
                        element.destroy();
                        return false;
                    }
                    return true;
                });
            } else if(recordViewForm.get("v.useCaseId") === recordId){
                recordViewForm.destroy();
            }
        }
        var useCaseOpportunityList = component.get("v.useCaseOpportunityList");
        var index;
        useCaseOpportunityList.every(function(element, elementIndex){
            if(!$A.util.isEmpty(element.Use_Case__r) && !$A.util.isEmpty(element.Use_Case__r.Id) && element.Use_Case__r.Id === recordId){
                index = elementIndex;
                return false;
            }
            return true;
        });
        if(!$A.util.isEmpty(index)){
            var element = useCaseOpportunityList[index];
            useCaseOpportunityList = useCaseOpportunityList.splice(index,1);
            component.set("v.useCaseOpportunityList", useCaseOpportunityList);

            element.Use_Case__r.Status__c = "Inactive - Never Sold";
            element.Status__c = "Removed";
            var action = component.get("c.updateUseCase");
            action.setParams({
                useCase : element.Use_Case__r,
                useCaseOpp : element
            });
            action.setCallback(this, function(response) {
                if (response.getState() === 'SUCCESS') {
                    self.doInit(component);
                } else if(response.getState() === 'Error') {
                    var errors = response.getError();
                    var message = '';
                    if(Array.isArray(error)){
                        errors.forEach(function(element){
                            message = message + '\n' + element.message;
                        }); 
                    } else{
                        message =  errors.message;
                    }
                    component.set("v.showSpinner", false);               
                }
            });
            $A.enqueueAction(action);
        }
    },
})