public with sharing class OpportunityLineItemController {
    @AuraEnabled(cacheable=true)
    public static List<OpportunityLineItem> getOpportunityLineItems(String opportunityId) {
        System.Debug('OpportunityId = ' + OpportunityId);
        return [SELECT Id, Name, ProductCode, Product_Name__c, UnitPrice, Quantity, TotalPrice from OpportunityLineItem where OpportunityId = :OpportunityId];
    }
}