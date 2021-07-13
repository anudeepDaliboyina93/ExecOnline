({
	init : function(component, event, helper) {
		component.set("v.showSpinner", false);
	},
	cancelDialog : function(component, event, helper) {
		component.destroy();
	},
	handleClick : function (cmp, event, helper) {
        var buttonstate = cmp.get('v.buttonstate');
        cmp.set('v.buttonstate', !buttonstate);
    },
    save : function(component, event, helper) {
    	component.set("v.showSpinner", true);
    	helper.insertRecords(component);
	},
})