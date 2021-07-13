/**
 * EPCUtilizationHandler.cls
 * Copyright 2019 Wired Triangle, LLC
 * http://www.wiredtriangle.com
 */
global with sharing class EPCUtilizationHandler implements ITrigger {

    global static TriggerConfiguration__c triggerConfig = TriggerConfiguration__c.getInstance();
    global static Boolean enableAutoCalculateEPCUtilization = triggerConfig.Enable_Auto_Calculate_EPC_Utilization__c;
	private Set<Id> studentIdsToCalculate = new Set<Id>();
	private Set<Id> epcuiIdsToCalculate = new Set<Id>();

    public EpcUtilizationHandler() {}

    public void bulkBefore() {
    }

    public void bulkAfter() {
    }

    public void beforeInsert(SObject so) {
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
    }

    public void beforeDelete(SObject so) {
    }

    public void beforeUnDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
        EPC_Utilization__c epcu = (EPC_Utilization__c) so;
        if(epcu.Type__c == 'Actual') {
            if (epcu.EPC_Utilization_Item__c != null) {
                epcuiIdsToCalculate.add(epcu.EPC_Utilization_Item__c);
            } else if(epcu.Student__c != null) {
                studentIdsToCalculate.add(epcu.Student__c);
            }
        }
    }

    public void afterUpdate(SObject oldSo, SObject so) {
    }

    public void afterDelete(SObject so) {
    }

    public void afterUnDelete(SObject so) {
    }

    public void andFinally() {
        if (Trigger.isAfter && Trigger.isInsert) {
            recalculateEpcuiEpcsUtilized();
            recalculateStudentEpcsUtilized();
        }
    }

    void recalculateEpcuiEpcsUtilized() {
        if(epcuiIdsToCalculate.isEmpty()) {
            return;
        }
        List<EPC_Utilization__c> epcuiEPCUs = new List<EPC_Utilization__c>([
            SELECT Id, EPC_Utilization_Item__c, EPCs_Utilized__c 
            FROM EPC_Utilization__c 
            WHERE EPC_Utilization_Item__c in :epcuiIdsToCalculate AND Type__c = 'Actual']);
        Map<Id,EPC_Utilization_Item__c> epcuiMap = new Map<Id,EPC_Utilization_Item__c>([
            SELECT Id, EPCs_Utilized__c 
            FROM EPC_Utilization_Item__c 
            WHERE Id IN :epcuiIdsToCalculate]);
        //zero out EPCUI.EPCs_Utilized
        for (EPC_Utilization_Item__c epcui:epcuiMap.values()) {
            epcui.EPCs_Utilized__c=0;
        }
        //recalculate EPCUI.EPCs_Utilized
        for (EPC_Utilization__c epcu:epcuiEPCUs) {
            epcuiMap.get(epcu.EPC_Utilization_Item__c).EPCs_Utilized__c += epcu.EPCs_Utilized__c;
        }
        // we are updating the EPCs_Utilized__c fields because we just completed an EPC recalc
        // don't trigger another recalc
        EPCUtilizationItemHandler.bypassTriggerLogic = true;
        update epcuiMap.values();
        EPCUtilizationItemHandler.bypassTriggerLogic = false;
    }

    void recalculateStudentEpcsUtilized() {
        if(studentIdsToCalculate.isEmpty()) {
            return;
        }
        List<EPC_Utilization__c> studentEPCUs = new List<EPC_Utilization__c>([
            SELECT Id, Student__c, EPCs_Utilized__c 
            FROM EPC_Utilization__c 
            WHERE Student__c in :studentIdsToCalculate AND Type__c = 'Actual']);
        Map<Id,Student__c> studentMap = new Map<Id,Student__c>([
            SELECT Id, EPCs_Utilized__c 
            FROM Student__c 
            WHERE Id IN :studentIdsToCalculate]);
        //zero out Student.EPCs_Utilized
        for (Student__c student:studentMap.values()) {
            student.EPCs_Utilized__c=0;
        }
        //recalculate Student.EPCs_Utilized
        for (EPC_Utilization__c epcu:studentEPCUs) {
            studentMap.get(epcu.Student__c).EPCs_Utilized__c += epcu.EPCs_Utilized__c;
        }
        // we are updating the EPCs_Utilized__c fields because we just completed an EPC recalc
        // don't trigger another recalc
        StudentHandler.bypassTriggerLogic = true;
        update studentMap.values();
        StudentHandler.bypassTriggerLogic = false;
    }

}