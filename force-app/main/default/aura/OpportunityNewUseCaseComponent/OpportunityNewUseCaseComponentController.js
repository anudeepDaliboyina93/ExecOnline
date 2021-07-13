({
	init : function(component, event, helper) {
	},
	cancelDialog : function(component, event, helper) {
		component.destroy();
	},
	onLoad : function(component, event, helper) {
		component.set("v.showSpinner", false);
	},
	onSuccess : function(component, event, helper) {
		self = this;
		var oppUseCaseRecord = component.get("v.oppUseCaseObject");
		var response = event.getParam("response");
		if(!$A.util.isEmpty(response) && !$A.util.isEmpty(response.id)){
			oppUseCaseRecord.Use_Case__c = response.id;
			oppUseCaseRecord.Status__c = "Active";
			oppUseCaseRecord.Opportunity__c = component.get("v.opportunityId");
			helper.saveRecord(component, oppUseCaseRecord);
		}
	},
	onError : function(component, event, helper) {
		var errorObj = event.getParams();
		if(!$A.util.isEmpty(errorObj.error) && !$A.util.isEmpty(errorObj.error.message)){
            helper.showError(component, errorObj.error.message);
        } else if(!$A.util.isEmpty(errorObj.message)){
            helper.showError(component, errorObj.message);
        } else{
            helper.showError(component, 'There is some error creating the record. Please check error logs.');
        }
	},
	save : function(component, event, helper) {
		component.set("v.showSpinner", true);
		var inputFields = component.find("inputField");
		var recordEditForm = component.find("recordEditForm");
		var fields = component.get("v.fields");
		var fieldsError = "Please fill these fields.\n ";

		inputFields.forEach(function(element){
			if($A.util.isEmpty(element.get("v.value"))){
				var err = fields.find(function(field){return field.apiName === element.get("v.fieldName")})["label"] + ', ';
				fieldsError = fieldsError + err;
			}			
		});

		if(fieldsError.includes(",")){
			fieldsError = fieldsError.substring(0,fieldsError.lastIndexOf(","));
			helper.showError(component, fieldsError);
		} else{
			console.log('in');
			var div1 = component.find("errorDiv");
                        // Replace div body with the dynamic component
            div1.set("v.body", null);
            console.log(component.find("status"));
            console.log(component.find("status").get("v.value"));
            console.log(component.find("account").get("v.value"));


            component.find("account").set("v.value", component.get("v.accountId"));
            component.find("status").set("v.value", "Sales");
            console.log(component.find("status").get("v.value"));
            console.log(component.find("account").get("v.value"));
            
            recordEditForm.submit();
		}
		
	},
})