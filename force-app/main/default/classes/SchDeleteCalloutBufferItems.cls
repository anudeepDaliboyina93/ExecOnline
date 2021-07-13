/**
     * @description This scheduled class deletes Callout Buffer Items that are older than 3 months.
     * 
     * 
     */

public class SchDeleteCalloutBufferItems implements Schedulable {

    /**
    * @description Get context to execute
    * @param sc Scheduled Context
    */
   public void execute(SchedulableContext sc){
       //Get Callout Buffer Items older than 3 months
       Callout_Buffer_Item__c[] cbiList = [SELECT Id, CreatedDate FROM Callout_Buffer_Item__c WHERE CreatedDate < LAST_N_MONTHS:3];

       if (!cbiList.isEmpty()){
           delete cbiList;
       }
   }
}