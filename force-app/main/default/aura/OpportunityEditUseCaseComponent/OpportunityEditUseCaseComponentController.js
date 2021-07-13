({
	cancelDialog : function(component, event, helper) {
		component.destroy();
	},
	onSuccess : function(component, event, helper) {
		var compEvent = $A.get("e.c:OpportunityUseCaseEvent");
        compEvent.setParams({
            "type": "RefreshComponent"
        });
        compEvent.fire();
		component.destroy();
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
		var inputFields = component.find("inputField");
		var recordEditForm = component.find("recordEditForm");
		var fields = component.get("v.fields");
		var fieldsError = "All Fields are required. Please fill these fields.\n ";

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
			var div1 = component.find("errorDiv");
            div1.set("v.body", null);
            recordEditForm.submit();
		}		
	},
})