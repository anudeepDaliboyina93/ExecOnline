@isTest
public class TriggerDispatcherTest {

    /* 
    * Test__z is used as a fake custom object to test with
    * Strictly tests the TriggerDispatcher.cls only. No custom triggers will be hit in this unit test 
    * 49/52 lines 94% coverage
    * Only lines uncovered are the mapping of custom metadata - these will get covered once custom handlers are added
    */

    @isTest
    static void testInsert() {
        TriggerDispatcher.handlerExecutionMap = new Map<String, List<String>>();
        TriggerDispatcher.handlerExecutionMap.put('Test__z', new List<String>{ 'TriggerDispatcherTest.TestHandler' });
        Test.startTest();
        TriggerDispatcher.triggerObjectOverride = 'Test__z';
        TriggerDispatcher.triggerContextOverride = System.TriggerOperation.BEFORE_INSERT;
        TriggerDispatcher.run();
        TriggerDispatcher.triggerContextOverride = System.TriggerOperation.AFTER_INSERT;
        TriggerDispatcher.run();
        Test.stopTest();

        System.assertEquals(2, TriggerDispatcher.executedTriggerContexts.size());
        System.assert(TriggerDispatcher.executedTriggerContexts.contains('TriggerDispatcherTest.TestHandlerBEFORE_INSERT'));
        System.assert(TriggerDispatcher.executedTriggerContexts.contains('TriggerDispatcherTest.TestHandlerAFTER_INSERT'));
    }
    
    @isTest
    static void testUpdate() {
        TriggerDispatcher.handlerExecutionMap = new Map<String, List<String>>();
        TriggerDispatcher.handlerExecutionMap.put('Test__z', new List<String>{ 'TriggerDispatcherTest.TestHandler' });
        Test.startTest();
        TriggerDispatcher.triggerObjectOverride = 'Test__z';
        TriggerDispatcher.triggerContextOverride = System.TriggerOperation.BEFORE_UPDATE;
        TriggerDispatcher.run();
        TriggerDispatcher.triggerContextOverride = System.TriggerOperation.AFTER_UPDATE;
        TriggerDispatcher.run();
        Test.stopTest();

        System.assertEquals(2, TriggerDispatcher.executedTriggerContexts.size());
        System.assert(TriggerDispatcher.executedTriggerContexts.contains('TriggerDispatcherTest.TestHandlerBEFORE_UPDATE'));
        System.assert(TriggerDispatcher.executedTriggerContexts.contains('TriggerDispatcherTest.TestHandlerAFTER_UPDATE'));
    }
    
    @isTest
    static void testDeleteUndelete() {
        TriggerDispatcher.handlerExecutionMap = new Map<String, List<String>>();
        TriggerDispatcher.handlerExecutionMap.put('Test__z', new List<String>{ 'TriggerDispatcherTest.TestHandler' });
        Test.startTest();
        TriggerDispatcher.triggerObjectOverride = 'Test__z';
        TriggerDispatcher.triggerContextOverride = System.TriggerOperation.BEFORE_DELETE;
        TriggerDispatcher.run();
        TriggerDispatcher.triggerContextOverride = System.TriggerOperation.AFTER_DELETE;
        TriggerDispatcher.run();
        TriggerDispatcher.triggerContextOverride = System.TriggerOperation.AFTER_UNDELETE;
        TriggerDispatcher.run();
        Test.stopTest();

        System.assertEquals(3, TriggerDispatcher.executedTriggerContexts.size());
        System.assert(TriggerDispatcher.executedTriggerContexts.contains('TriggerDispatcherTest.TestHandlerBEFORE_DELETE'));
        System.assert(TriggerDispatcher.executedTriggerContexts.contains('TriggerDispatcherTest.TestHandlerAFTER_DELETE'));
        System.assert(TriggerDispatcher.executedTriggerContexts.contains('TriggerDispatcherTest.TestHandlerAFTER_UNDELETE'));
    }
    
    @isTest
    static void testRecursion() {
        TriggerDispatcher.handlerExecutionMap = new Map<String, List<String>>();
        TriggerDispatcher.handlerExecutionMap.put('Test__z', new List<String>{ 'TriggerDispatcherTest.TestHandler' });
        Test.startTest();
        TriggerDispatcher.triggerObjectOverride = 'Test__z';
        TriggerDispatcher.triggerContextOverride = System.TriggerOperation.BEFORE_UPDATE;
        TriggerDispatcher.run();
        TriggerDispatcher.run();
        Test.stopTest();

        System.assertEquals(1, TriggerDispatcher.executedTriggerContexts.size());
        System.assert(TriggerDispatcher.executedTriggerContexts.contains('TriggerDispatcherTest.TestHandlerBEFORE_UPDATE'));
    }
    
    @isTest
    static void testGetTriggerHandlerExecutionMdt() {
        Test.startTest();
        TriggerDispatcher.triggerObjectOverride = 'Test__z';
        TriggerDispatcher.triggerContextOverride = System.TriggerOperation.BEFORE_UPDATE;
        TriggerDispatcher.run();
        Test.stopTest();
        
        System.assertEquals(0, TriggerDispatcher.executedTriggerContexts.size());
    }

    public class TestHandler extends TriggerHandler {}

}