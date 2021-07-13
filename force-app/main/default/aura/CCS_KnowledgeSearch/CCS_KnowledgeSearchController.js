({
    onEnter : function(component, event, helper){
        if(event.getParams().keyCode == 13){
            var navEvt = $A.get('e.force:navigateToURL');
            navEvt.setParams({url: '/custom-search-results?search=' + component.get("v.searchText")});
            navEvt.fire();
        }
    },
    
    handleClick : function(component, event, helper){
        var navEvt = $A.get('e.force:navigateToURL');
        navEvt.setParams({url: '/custom-search-results?search=' + component.get("v.searchText")});
        navEvt.fire();
    }  
})