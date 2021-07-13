({
    doInit : function(component, event, helper){
        var sPageURL = decodeURIComponent(window.location.search.substring(1)),
            sURLVariables = sPageURL.split('&'),
            sParameterName,
            i;
        if(sURLVariables != null && sURLVariables !=''){
            for(i = 0; i < sURLVariables.length; i++){
                sParameterName = sURLVariables[i].split('=');
                if(sParameterName[0] === 'cid'){
                    var contactId = sParameterName[1] === undefined ? false : sParameterName[1];
                    if(contactId){
                        sessionStorage.removeItem('contactId', contactId);
                        sessionStorage.setItem('contactId', contactId);
                        component.set("v.contactId", contactId);
                    }
                }
            }
        }
        else
            component.set("v.contactId", sessionStorage.getItem('contactId'));
    }
})