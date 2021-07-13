({
    showToast : function(component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "Next Steps have been updated successfully.",
            "type":"success"
        });
        $A.get('e.force:refreshView').fire();
        toastEvent.fire();
        helper.deactivateButton(component,event);
    },
    
    fieldChange : function(component, event, helper) {
        helper.activateButton(component,event);
    }
})