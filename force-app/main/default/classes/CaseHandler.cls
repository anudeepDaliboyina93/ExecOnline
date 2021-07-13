public with sharing class CaseHandler implements ITrigger {

    private Id defaultCaseEntitlement;
    private List<Case> closedCases = new List<Case>();
    private List<CaseMilestone> milestonesToClose = new List<CaseMilestone>();

    public void bulkBefore() {
        defaultCaseEntitlement = CaseService.getDefaultEntitlement();
    }

    public void bulkAfter() {
    }

    public void beforeInsert(SObject so) {
        Case c = (Case)so;
        if (defaultCaseEntitlement != null) {
            c.EntitlementId = defaultCaseEntitlement;
        }
    }

    public void beforeUpdate(SObject oldSo, SObject so) {

    }

    public void beforeDelete(SObject so) {
    }

    public void beforeUnDelete(SObject so) {
    }

    public void afterInsert(SObject so) {

    }

    public void afterUpdate(SObject oldSo, SObject so) {
        Case c = (Case)so;
        Case cOld = (Case)oldSo;
        if (c.Status == 'Closed' && cOld.Status != 'Closed') {
            closedCases.add(c);
        }
    }

    public void afterDelete(SObject so) {

    }

    public void afterUnDelete(SObject so) {

    }

    public void andFinally() {
        String queryString = 'select CaseId, iscompleted, completiondate from CaseMilestone where caseid in :closedCases';
        milestonesToClose = Database.query(queryString);
        if (milestonesToClose.size() > 0) {
            for (CaseMilestone cm : mileStonesToClose) {
                cm.completiondate = DateTime.now();
            }
            update mileStonesToClose;
        }
    }
}