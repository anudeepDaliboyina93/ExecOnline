trigger updateResponsetimeonCaseClose on Case (after update) {
    
    set<id>  caseids = new set<id>();
    
    for(case cs : trigger.new){
        if(cs.status == 'Closed'){
            caseids.add(cs.id);    
        }    
    }
     
    list<Response_Time__c> lstresponselist = [select id,response_time__c,Inquiry_Time__c  from Response_Time__c where response_time__c = null AND Case__c IN :caseids];
     
    for(Response_Time__c rt : lstresponselist ){
        rt.response_time__c = system.now();
    }
    
    update lstresponselist ;
    }