@isTest
public class EPCUtilizationItemHandlerTest {
    
    @isTest
    static void testBundleIsAppliedToEpcuis() {
        EPCUI_Bundle__mdt bundle = [SELECT Id, EPCs_Discounted_Per_Item__c, Start_Date__c FROM EPCUI_Bundle__mdt WHERE Label = 'Unit Test Bundle' LIMIT 1];

        List<Service__c> services = TestDataFactory.getCoreProgramServices(2); 
        services[0].Name = 'Written test feedback';
        services[0].List_Weighting__c = .2; 
        services[1].Name = 'Live test feedback';
        services[1].List_Weighting__c = .2;

        insert services;

        Contact contact = TestDataFactory.getContact();
        insert contact;

        Student__c student = TestDataFactory.getStudent(contact.Id);
        insert student;

        Test.startTest();
        List<EPC_Utilization_Item__c> epcuis = new List<EPC_Utilization_Item__c>();
        epcuis.add(new EPC_Utilization_Item__c(Student__c = student.Id, Service__c = services[0].Id, EPC_Utilization_Date__c = bundle.Start_Date__c, Status__c = 'Active'));
        epcuis.add(new EPC_Utilization_Item__c(Student__c = student.Id, Service__c = services[1].Id, EPC_Utilization_Date__c = bundle.Start_Date__c, Status__c = 'Active'));
        insert epcuis;
        update epcuis;
        Test.stopTest();

        epcuis = [SELECT Id, EPCs_Discounted__c FROM EPC_Utilization_Item__c WHERE Id IN :epcuis];
        System.assertEquals(2, epcuis.size());
        System.assertEquals(bundle.EPCs_Discounted_Per_Item__c, epcuis[0].EPCs_Discounted__c);
        System.assertEquals(bundle.EPCs_Discounted_Per_Item__c, epcuis[1].EPCs_Discounted__c);        
    }

}