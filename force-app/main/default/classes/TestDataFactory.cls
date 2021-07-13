@isTest
public class TestDataFactory {
    
    public static Account getAccount() {
        return getAccounts(1)[0];
    }

    public static List<Account> getAccounts(Integer numberOfAccounts) {
        List<Account> newAccounts = new List<Account>();
        for(Integer i = 0; i < numberOfAccounts; i++) {
            newAccounts.add(new Account(Name = 'testAccount' + i));
        }
        return newAccounts;
    }

    public static Opportunity getNewBusinessOpportunity(Id accountId) {
        return new Opportunity(Name = accountId + '_newBusiness', StageName = 'NB - Phase 1', CloseDate = Date.today(), AccountId = accountId, Pricebook2Id = Test.getStandardPricebookId(), Client_Type__c = 'Client', Team_Roll_Up__c = 'New Business Team', Client_Segment__c = 'Mid-Market');
    }
    public static Opportunity getContractRenewalOpportunity(Id accountId) {
        return new Opportunity(Name = accountId + '_contractRenewal', StageName = 'Closed/Won', CloseDate = Date.today(), AccountId = accountId, Pricebook2Id = Test.getStandardPricebookId(), RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Contract Renewal').getRecordTypeId(), Client_Type__c = 'Client', Team_Roll_Up__c = 'New Business Team', Client_Segment__c = 'Mid-Market');
    }

    public static Product2 getEpcProduct() {
        return new Product2(Name = 'EPC', ProductCode = 'EPC', Family = 'Partner Program', IsActive = true);
    }

    public static Contact getContact() {
        Account testAccount = getAccount();
        insert testAccount;
        return getContacts(testAccount.Id, 1)[0];
    }

    public static Contact getContact(Id accountId) {
        return getContacts(accountId, 1)[0];
    }

    public static List<Contact> getContacts(Id accountId, Integer numberOfContacts) {
        List<Contact> newContacts = new List<Contact>();
        for(Integer i = 0; i < numberOfContacts; i++) {
            newContacts.add(new Contact(AccountId = accountId, LastName = 'testContact' + i));
        }
        return newContacts;
    }

    public static Student__c getStudent(Id contactId) {
        Program__c testProgram = getProgram();
        insert testProgram;
        return getStudents(contactId, testProgram.Id, 1)[0];
    }

    public static Student__c getStudent(Id contactId, Id programId) {
        return getStudents(contactId, programId, 1)[0];
    }

    public static List<Student__c> getStudents(Id contactId, Id programId, Integer numberOfStudents) {
        List<Student__c> newStudents = new List<Student__c>();
        for(Integer i = 0; i < numberOfStudents; i++) {
            newStudents.add(new Student__c(Contact__c = contactId, Program__c = programId));
        }
        return newStudents;
    }

    public static Program__c getProgram() {
        return getPrograms(1)[0];
    }

    public static List<Program__c> getPrograms(Integer numberOfPrograms) {
        List<Program__c> newPrograms = new List<Program__c>();
        for(Integer i = 0; i < numberOfPrograms; i++) {
            newPrograms.add(new Program__c(Name = 'testProgram' + i, Friendly_Name__c = 'testProgram' + i, Short_Name__c = 'testProgram' + i));
        }
        return newPrograms;
    }

    public static Service__c getCoreProgramService() {
        return getCoreProgramServices(1)[0];
    }

    public static List<Service__c> getCoreProgramServices(Integer numberOfServices) {
        List<Service__c> newServices = new List<Service__c>();
        for(Integer i = 0; i < numberOfServices; i++) {
            newServices.add(new Service__c(Name = 'Core Program', List_Weighting__c = 0, Service_Category__c= 'All', Status__c = 'Active', Utilization_Date_Formula__c = 'Program Start Date -14d'));
        }
        return newServices;
    }

    public static Program_Family__c getProgramFamily() {
        return getProgramFamilies(1)[0];
    }

    public static List<Program_Family__c> getProgramFamilies(Integer numberOfProgramFamilies) {
        List<Program_Family__c> newProgramFamilies = new List<Program_Family__c>();
        for(Integer i = 0; i < numberOfProgramFamilies; i++) {
            newProgramFamilies.add(new Program_Family__c(Name = 'testProgramFamily' + i, EPC_Weighting__c = 0, Status__c = 'Active', Service_Category__c = 'All'));
        }
        return newProgramFamilies;
    }

    public static Program_Period__c getWinterProgramPeriod() {
        return getProgramPeriod('Winter 2020', Date.newInstance(2020, 2, 24), Date.newInstance(2020, 4, 5));
    }

    public static Program_Period__c getSpringProgramPeriod() {
        return getProgramPeriod('Spring 2020', Date.newInstance(2020, 4, 27), Date.newInstance(2020, 6, 7));
    }

    public static Program_Period__c getProgramPeriod(String name, Date startDate, Date endDate) {
        return new Program_Period__c(Name = name, Start_Date__c = startDate, End_Date__c = endDate);
    }

    public static Program__c getProgramForProgramPeriod(String name, Program_Period__c programPeriod, Program_Family__c programFamily) {
        return new Program__c(Name = name, Friendly_Name__c = name, Short_Name__c = name,
            Program_Period__c = programPeriod.Id, Course_Start_Date__c = programPeriod.Start_Date__c, Course_End_Date__c = programPeriod.End_Date__c,
            Program_Family__c = programFamily.Id);
    }

    public static Tag__c getTag(String tagName) {
        return getTags(new List<String>{ tagName })[0];
    }

    public static List<Tag__c> getTags(List<String> tagNames) {
        List<Tag__c> newTags = new List<Tag__c>();
        for(Integer i = 0; i < tagNames.size(); i++) {
            newTags.add(new Tag__c(Name = tagNames[i], Name_External_Id__c = tagNames[i]));
        }
        return newTags;
    }

    public static Tag_Service__c getTagService(Service__c service, Student_Tag__c studentTag, Tag__c tag) {
        return new Tag_Service__c(Service__c = service == null ? null : service.Id, Student_Tag__c = studentTag == null ? null : studentTag.Id, Tag__c = tag == null ? null : tag.Id);
    }

    public static Student_Event__c getStudentEventCoaching(Id studentId) {
        return new Student_Event__c(Student__c = studentId, Event_Type__c = 'Coaching', Start_Time__c = System.now().addDays(1), Status__c = 'not_set');
    }

}