global with sharing class SetCurrentStudent { 
    @InvocableMethod(label='Set Current Student' description='For a Program, sets all Student records to be Current Student on the corresponding Contact lookup field Current Student.')
    Webservice static List<String> execute(List<ID> programIds) {
        List<String> result = new List<String>();
        Integer count = 0;
        for (Id programId:programIds) {
            Database.executeBatch(new SetCurrentStudentBatch(programId));
            count = database.countQuery('select count() from Student__c where Program__c = :programId');
            result.add(String.valueOf(count) + ' students updated');
        }
        return result;
    }
}