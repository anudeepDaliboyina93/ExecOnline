({
	activateButton : function(component, event) {
        component.find('submitBtn').set('v.disabled',false);
    },
    deactivateButton : function(component, event) {
        component.find('submitBtn').set('v.disabled',true);
    }
})