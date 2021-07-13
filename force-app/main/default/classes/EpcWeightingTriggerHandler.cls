public class EpcWeightingTriggerHandler extends TriggerHandler {
    public override void afterInsert(Map<Id, SObject> newItemMap) {
        handleRecalcAccountEpc(newItemMap.values());
    }
    
    public override void afterUpdate(Map<Id, SObject> newItemMap, Map<Id, SObject> oldItemMap) {
        handleRecalcAccountEpc(newItemMap.values());
    }

    public override void afterDelete(Map<Id, SObject> oldItemMap) {
        handleRecalcAccountEpc(oldItemMap.values());
    }

    private void handleRecalcAccountEpc(List<EPC_Weighting__c> changedEpcWeightings) {
        Set<Id> accountIdsToRecalc = new Set<Id>();
        for(EPC_Weighting__c epcw : changedEpcWeightings) {
            accountIdsToRecalc.add(epcw.Account__c);
        }

        if(accountIdsToRecalc.size() > 0) {
            EpcServiceV2 epcHelper = new EpcServiceV2(accountIdsToRecalc);
            System.enqueueJob(epcHelper);
        }
    }
}