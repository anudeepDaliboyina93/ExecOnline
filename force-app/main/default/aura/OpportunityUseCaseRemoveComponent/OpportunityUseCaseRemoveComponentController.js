({
	cancelDialog : function(component, event, helper) {
		component.destroy();
	},
	remove : function(component, event, helper) {
		var compEvent = $A.get("e.c:OpportunityUseCaseEvent");
        compEvent.setParams({
            "type": "RemoveUseCase",
            "payload" : component.get("v.recordId")
        });
        compEvent.fire();
        component.destroy();
	}
})