({
	 init: function(cmp){
        var contactId = sessionStorage.getItem('contactId');

        if(contactId){
            var action = cmp.get("c.getContact");
            action.setParams({ contactId : contactId});
            action.setCallback(this, function(response){
                var state = response.getState();
                if(state==="SUCCESS"){
                    var newCase = {'SObjectType': 'Case',
                                   'AccountId': response.getReturnValue().AccountId,
                                   'ContactId': response.getReturnValue().Id,
                                   'Subject': '',
                                   'Description': '',
                                   'SuppliedName': response.getReturnValue().Name,
                                   'SuppliedEmail': response.getReturnValue().Email,
                                   'Origin' : 'Web'
                                  };
                    cmp.set("v.newCase", newCase);
                }
                else{
                    console.log("error occured retrieving contact");
                }
            });
            $A.enqueueAction(action);
        }
     },
    
    submitCase : function(cmp){
        var allValid = cmp.find('field').reduce(function (validSoFar, inputCmp){
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if (allValid){
            var newCase = cmp.get("v.newCase");
            var action = cmp.get("c.createCase");
            action.setParams({ newCase : newCase });
            action.setCallback(this, function(resp){
                var state = resp.getState();
                if(state === 'SUCCESS'){
                    cmp.set('v.saved',true);
                }
                else if(state === 'ERROR'){
                    console.log('resp.getError() ' +JSON.stringify(resp.getError()));
                    var errors = resp.getError();
                    for(var i = 0 ;i < errors.length;i++){
                        console.log(errors[i].message);
                    }
                }
            });
            $A.enqueueAction(action);      
        }
    }   
})