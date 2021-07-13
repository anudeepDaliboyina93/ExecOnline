({invoke : function(component, event, helper) { // Get the record ID attribute 
    
var record = component.get("v.recordId"); 

var aUrl = "/apex/malbek__MalbekOpportunityRequestContract?id="+record;

var urlEvent = $A.get("e.force:navigateToURL"); urlEvent.setParams({ "isredirect": "true", "url": aUrl }); urlEvent.fire(); }})