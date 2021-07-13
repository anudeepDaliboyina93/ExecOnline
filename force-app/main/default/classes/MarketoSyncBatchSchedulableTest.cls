@isTest
public class MarketoSyncBatchSchedulableTest {

@isTest static void MarketoSyncBatch_SchedulableTest() {

Contact cont = new Contact(FirstName ='First Name', LastName ='Last Name', Email='test@test.com');
insert cont;

// Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
String CRON_EXP = '0 6 * * * ?';

Test.startTest();

String jobId = System.schedule('Sync Contacts Marketo', CRON_EXP, new MarketoSyncBatchSchedulable());
CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
System.assertEquals(CRON_EXP, ct.CronExpression);
System.assertEquals(0, ct.TimesTriggered);

Test.stopTest();

}

}