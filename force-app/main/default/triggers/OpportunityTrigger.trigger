trigger OpportunityTrigger on Opportunity (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    
    if(OpportunityHandler.firstRun){
        
        if (Trigger.isAfter){
            OpportunityHandler.firstRun = false;
        }
       
        TriggerFactory.createHandler(Opportunity.sObjectType);
   }
}