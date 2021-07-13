({
	insertRecords : function(component) {
		var self = this;
		var records = component.get("v.records");
    	var recordsToInsert = [];
    	records.forEach(function(element){
    		if(element.selected){
    			recordsToInsert.push(element.Id);
    		}
    	});
    	if(!$A.util.isEmpty(recordsToInsert)){    		
			var action = component.get("c.insertUseCaseOppRecords");
	        action.setParams({
	            opportunityId : component.get("v.opportunityId"),
	            recordIds : recordsToInsert
	        });
	        action.setCallback(this, function(response) {
	            if (response.getState() === 'SUCCESS') {
	            	var compEvent = $A.get("e.c:OpportunityUseCaseEvent");
	                compEvent.setParams({
	                    "type": "RefreshComponent"
	                });
	                compEvent.fire();
	            	component.destroy();
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
	            	self.showError(component, message);
	            }
	        });
	        $A.enqueueAction(action);
    	} else {
    		self.showError(component, "Please select atleast one Use Case to save.");
    	}
	},
	showError : function(component, errorMsg){
		$A.createComponents([
            ["ui:message",{
                "title" : "Error :",
                "severity" : "error",
            }],
            ["ui:outputText",{
                "value" : errorMsg
            }]
            ],
            function(components, status, errorMessage){
                if (status === "SUCCESS") {
                    var message = components[0];
                    var outputText = components[1];
                    message.set("v.body", outputText);
                    var div1 = component.find("errorDiv");
                    div1.set("v.body", message);
                }
                component.set("v.showSpinner", false);
                window.setTimeout(function(){
                	if(!$A.util.isEmpty(component.find("errorDiv")) 
                		&& !$A.util.isEmpty(component.find("errorDiv").getElement())
                		&& !$A.util.isEmpty(component.find("errorDiv").getElement().scrollIntoView)){
                		component.find("errorDiv").getElement().scrollIntoView({block: "start",behavior: "smooth"});
                	}
                },200);
            }
        );
	},
})