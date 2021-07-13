trigger Trgr_CopProgrmsOnContct on Student__c (After insert,after delete,after update){

    
    Set<String> ContIds = new Set<String>();    
    if(Trigger.isafter && (Trigger.isInsert || Trigger.isUpdate)){
        For(Student__c  SObj : Trigger.new){
            if(Trigger.isInsert){
                ContIds.add(SObj.Contact__c);
            }
            if(Trigger.isUpdate){
                if(SObj.Mailing_List_ID__c != trigger.oldmap.get(SObj.id).Mailing_List_ID__c){
                    ContIds.add(SObj.Contact__c);
                }
            }
        }
    }
    
    if(Trigger.isDelete){
        For(Student__c  SObjD : Trigger.old){
            ContIds.add(SObjD.Contact__c);
        }
    }        
    System.debug('>>>>>>>>>>ContIds:: ' + ContIds);
    System.debug('>>>>>>>>>>ContIds.size():: ' + ContIds.size());
    
    
    List<Contact> LstContactUpdate = new List<Contact>();
    For(Contact Obj : [Select id,name,Mailing_List_ID__c,Preferred_Name__c,(select id,name,Program__c,Mailing_List_ID__c from Students__r) from contact where id in:ContIds]){ //Registered_Programs__c  Programformula__c
        Integer Count = 1;
        Integer Count2 = 1;
        Set<String> ss = new Set<String>();
        Set<String> EL = new Set<String>();
        
        For(Student__c StObj : Obj.Students__r){
           /*
            if(!ss.contains(StObj.Programformula__c)){
                if(count == 1){
                    Obj.Registered_Programs__c = StObj.Programformula__c;
                }
                if(count > 1){
                    Obj.Registered_Programs__c = Obj.Registered_Programs__c+';'+StObj.Programformula__c;
                }
                ss.add(StObj.Programformula__c);
            }
            count++;
            */
            System.debug('>>>>>>>>>>StObj.Mailing_List_ID__c:: ' + StObj.Mailing_List_ID__c);            
            if(StObj.Mailing_List_ID__c !=null &&  StObj.Mailing_List_ID__c != ''){
                //if(!EL.contains(StObj.Mailing_List_ID__c)){
                    if(count2 == 1){
                        Obj.Mailing_List_ID__c = StObj.Mailing_List_ID__c;
                    }
                    if(count2 > 1){
                        Obj.Mailing_List_ID__c = Obj.Mailing_List_ID__c +';'+StObj.Mailing_List_ID__c;
                    }
                   // EL.add(StObj.Mailing_List_ID__c);
                //}
                count2++;  
            }                                              
        } 
        if(count2 == 1){
            Obj.Mailing_List_ID__c = '';
        } 
       /* 
        if(Obj.Students__r.size() < 1){
            if(Obj.Registered_Programs__c != null ){
                Obj.Registered_Programs__c = '';
            }            
        } */             
        LstContactUpdate.add(Obj);
    }
    
    System.debug('>>>>>>>>>LstContactUpdate.size()::: ' + LstContactUpdate.size());
    if(LstContactUpdate.size() > 0){
        update LstContactUpdate;
    }
   
}