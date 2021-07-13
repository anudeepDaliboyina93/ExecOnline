trigger Trg_updateresponsetimefromcase on EmailMessage (after insert)  {

    list<Response_Time__c> lstresponse = new list<Response_Time__c>();
    set<id>  caseids = new set<id>();
    
    for(emailmessage message: trigger.new){
        caseids.add(message.parentid); 
     }
    
     map<id,case> casemap = new map<id,case> ([select id, description,closeddate,(select status,createddate, lastmodifieddate,messagedate from Case.EmailMessages),(select id,response_time__c,Inquiry_Time__c  from Case.Response_Time__r) from case where id in:caseids]); 
     
     for(emailmessage message: trigger.new){
         if(casemap.containskey(message.parentid)){
            boolean tocreatert = true;
            boolean toupdate = true;
            for(response_time__c rt : casemap.get(message.parentid).response_time__r){
                if(rt.response_time__c == null){
                    tocreatert = false;  
                    
                    if(message.status=='3'){
                        rt.response_time__c = system.now();
                        lstresponse.add(rt);
                    }          
                }
               
            }
           
            
            if(tocreatert == true && message.status=='0') {
                 Response_Time__c rtm = new Response_Time__c();
                 rtm.Inquiry_Time__c = system.now();
                 rtm.Case__c= message.parentid;
                 lstresponse.add(rtm);
            }
            
         
             
         }    
     
     }
      if(lstresponse.size()>0)
     {
       upsert lstresponse;
     }
     }