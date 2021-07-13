({
    init: function(cmp){
        var contactId;
        var value = sessionStorage.getItem('contactId');
        if(!value){
            contactId = cmp.get("v.contactId");
        }
        else{
            contactId = value; 
        }
        var action = cmp.get("c.getNavigationTopics");
        action.setParams({ contactId : contactId});
        action.setCallback(this, function(response){
            var expandedRows = [];
            var finalGridData = [];            
            var columns = [{type: 'text',
                            fieldName: 'name',
                            label: 'Topic'
                           }];
            
            cmp.set('v.gridColumns', columns);
            
            var state = response.getState();
            if(state==="SUCCESS"){
                var responses = response.getReturnValue();
                cmp.set("v.managedTopics", responses);

                for(var i=0; i<responses.length; i++){
                    var parentTopic = {};
                    label: 'Item 1',
                    parentTopic.label = responses[i]['topic']['name'].replace('&amp;','&').replace('&gt;','>').replace('&lt;','<');
                    parentTopic.name = responses[i]['topic']['id'];
                    parentTopic.disabled = false;
                    parentTopic.expanded = true;
                    parentTopic.href= '/s/topic/'+responses[i]['topic']['id'];
                    var childTree = [];                    
                    
                    if(responses[i]['children'] != undefined && responses[i]['children'] != null && responses[i]['children'] != ''
                      && responses[i]['children'] != '[]' && responses[i]['children'] != []){
                        
                        for(var j=0; j<responses[i]['children'].length; j++){
                            var subTopic = {};
                            subTopic.label = responses[i]['children'][j]['topic']['name'].replace('&amp;','&').replace('&gt;','>').replace('&lt;','<');
                            subTopic.name = responses[i]['children'][j]['topic']['id'];
                            subTopic.disabled = false;
                            subTopic.href= '/s/topic/'+responses[i]['children'][j]['topic']['id'];
                            childTree.push(subTopic);
                        }
                    }
                    parentTopic['items'] = childTree;
                    finalGridData.push(parentTopic);
                }
                cmp.set('v.gridData', finalGridData);
                cmp.set('v.gridExpandedRows', expandedRows);
            }
            else{
                console.log("error occured retrieving topics");
            }
        });
        $A.enqueueAction(action);
    }
});