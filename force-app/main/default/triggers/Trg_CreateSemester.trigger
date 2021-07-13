trigger Trg_CreateSemester on Account (after insert) {

    List<Semester__c> Semlist = new List<Semester__c>();
    if(trigger.isinsert && trigger.isafter){
        for(Account acc:trigger.new){
            if (acc.Account_Status__c != 'Active') {
                continue;
            }
            Semester__c sem = new Semester__c();
            //sem.Name = acc.Name;// Auto Number in Prod.
            sem.Account__c = acc.id;
            Semlist.add(sem);
        }
    }

    system.debug('>>>>>>>>>>>>>>Semlist'+Semlist);
    system.debug('>>>>>>>>>>>>>>Semlist.size()'+Semlist.size());
    if(Semlist.size()>0){
        insert Semlist;
    }

}