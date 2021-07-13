({
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
            }
        );
	},
})