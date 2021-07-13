({
	search:function(component,searchText){
        var self = this;
        //var searchText = component.get('v.searchText');
        var contactId = sessionStorage.getItem('contactId');
        var action = component.get('c.searchForArticles');
        action.setParams({searchText : searchText,
                          contactId : contactId});
        action.setCallback(this, function(response){
            if(response.getState() === 'SUCCESS'){
                var result = response.getReturnValue();
                if(!$A.util.isEmpty(result)){
                    var activeAccordians = component.get("v.activeAccordians");
                    component.set("v.resultCount",result.resultCount);
                    if(!$A.util.isEmpty(result.knowledgeArticlesList)){
                        component.set("v.knowledgeArticlesList", result.knowledgeArticlesList);
                        activeAccordians.push("knowledge");
                    }
                    if(result.resultCount === 0){
                        component.set("v.noResult",true);
                    }
                    else{
                        component.set("v.noResult", false);
                        window.setTimeout(function(){
                            component.set("v.activeAccordians", activeAccordians);
                        },500);
                        
                    }
                }
                component.set("v.showSpinner", false);
            } 
            else if(response.getState() === 'ERROR'){                
                var errors = response.getError();
                var message = '';
                if(Array.isArray(errors)){
                    errors.forEach(function(element){
                        message = message + '\n' + element.message;
                    });	
                } else{
                    message =  errors.message;
                } 
                self.showToast("sticky", "Error", message, "error", 2000);
                component.set("v.showSpinner", false);  
            }
            else
                console.log(response.getError());
        });
        $A.enqueueAction(action);
    }
})