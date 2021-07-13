({
	saveRecord : function(component, record) {
		var self = this;
		var action = component.get("c.saveUseCaseOppRecord");
        action.setParams({
            record : record
        });
        action.setCallback(this, function(response) {
            if(response.getState() === 'ERROR') {
            	var errors = response.getError();
            	var message = '';
            	if(Array.isArray(errors)){
            		errors.forEach(function(element){
						message = message + '\n' + element.message;
					});	
            	} else{
            		message =  errors.message;
            	} 
				self.showError(component, fieldsError);               
	        } else if(response.getState() === 'SUCCESS') {
                var compEvent = $A.get("e.c:OpportunityUseCaseEvent");
                compEvent.setParams({
                    "type": "RefreshComponent"
                });
                compEvent.fire();
	        	component.destroy();
	        }
        });
        $A.enqueueAction(action);
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
            }
        );
	},
})