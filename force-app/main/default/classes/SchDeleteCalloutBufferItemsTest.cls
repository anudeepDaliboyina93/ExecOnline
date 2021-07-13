@istest()
private class SchDeleteCalloutBufferItemsTest {
  
    @isTest
    static void deleteCalloutBufferItems(){

        List<Callout_Buffer_Item__c> cbiToInsert = new List<Callout_Buffer_Item__c>();
        List<Callout_Buffer_Item__c> cbiToUpdate = new List<Callout_Buffer_Item__c>();


        Datetime fourMonthsAgo = Datetime.now().addDays(-120);
        
        for (Integer i = 0; i < 200; ++i){

            Callout_Buffer_Item__c cbi = new Callout_Buffer_Item__c();

            cbi.Status__c   = 'Complete';
            cbi.Type__c     = 'Test cbi # ' + i;

            cbiToInsert.add(cbi);

        }

         insert cbiToInsert;

        cbiToUpdate = [SELECT Id FROM Callout_Buffer_Item__c];

        Callout_Buffer_Item__c cbiNew = new Callout_Buffer_Item__c();

        cbiNew.Status__c   = 'Complete';
        cbiNew.Type__c     = 'Callout Buffer Item to not be deleted';

        insert cbiNew;

        for (Callout_Buffer_Item__c cbi : cbiToUpdate){
            Test.setCreatedDate(cbi.Id, fourMonthsAgo);
        }

         Test.startTest();

         SchDeleteCalloutBufferItems scheduledTest = new SchDeleteCalloutBufferItems();
         String sch = '0 0 23 * * ?';
         System.schedule('Testing schedule', sch, scheduledTest);

         Test.stopTest();

        List<Callout_Buffer_Item__c> checkCBI = [SELECT Id, Type__c, CreatedDate FROM Callout_Buffer_Item__c];

         System.assertEquals(1, checkCBI.size());
         System.assertEquals('Callout Buffer Item to not be deleted', checkCBI[0].Type__c);

    }
}