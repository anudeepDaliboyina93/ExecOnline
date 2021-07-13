({
	init : function(component, event, helper){
		var searchString = window.location.search;
        var searchText = component.get("v.searchKeyword");
		if(!$A.util.isEmpty(searchText)){
			component.set("v.showSpinner",true);
			component.set("v.searchKeyword",decodeURI(searchText));
            helper.search(component,decodeURI(searchText));
        }
        else
			component.set("v.showSpinner",false);
    },
    
    goToUrl : function(component, event, helper){
        if(!$A.util.isEmpty(event) && !$A.util.isEmpty(event.target) && !$A.util.isEmpty(event.target.id)){
            var path = event.target.id;
            var navEvt = $A.get('e.force:navigateToURL');
            navEvt.setParams({url: path});
            navEvt.fire();
        }
    }
})