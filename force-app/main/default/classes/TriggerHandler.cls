public virtual class TriggerHandler {
    
    public virtual void beforeInsert(List<SObject> newItemList) {}
    public virtual void beforeUpdate(Map<Id, SObject> newItemMap, Map<Id, SObject> oldItemMap) {}
    public virtual void beforeDelete(Map<Id, SObject> oldItemMap) {}
    
    public virtual void afterInsert(Map<Id, SObject> newItemMap) {}
    public virtual void afterUpdate(Map<Id, SObject> newItemMap, Map<Id, SObject> oldItemMap) {}
    public virtual void afterDelete(Map<Id, SObject> oldItemMap) {}
    public virtual void afterUndelete(Map<Id, SObject> newItemMap) {}

    /*
        Replace [SObjectName] with the API name of the triggered SObject
        // Object trigger
        trigger [SObjectName] on [SObjectName] (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
            TriggerDispatcher.run();
        }
        // TriggerHandler class
        public class [SObjectName]TriggerHandler extends TriggerHandler {
            public override void beforeInsert(List<SObject> newItemList) {}
            public override void beforeUpdate(Map<Id, SObject> newItemMap, Map<Id, SObject> oldItemMap) {}
            public override void beforeDelete(Map<Id, SObject> oldItemMap) {}
            
            public override void afterInsert(LMap<Id, SObject> newItemMap) {}
            public override void afterUpdate(Map<Id, SObject> newItemMap, Map<Id, SObject> oldItemMap) {}
            public override void afterDelete(Map<Id, SObject> oldItemMap) {}
            public override void afterUndelete(Map<Id, SObject> newItemMap) {}
        }
    */

}