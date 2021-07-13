/* CalloutBufferItemHandler.trigger
* Copyright 2014 Wired Triangle, LLC
* http://www.wiredtriangle.com
*/
public with sharing class CalloutBufferItemHandler implements ITrigger
{

  // Constructor
  public CalloutBufferItemHandler()
  {
  }

  public void bulkBefore()
  {

  }

  public void bulkAfter()
  {
  }

  public void beforeInsert(SObject so)
  {
  }

  public void beforeUpdate(SObject oldSo, SObject so)
  {
    Callout_Buffer_Item__c c = (Callout_Buffer_Item__c)so;
    Callout_Buffer_Item__c oc = (Callout_Buffer_Item__c)oldSo;
    if (c.Last_Response_Timestamp__c != oc.Last_Response_Timestamp__c && c.Initial_Response_Timestamp__c == null) {
      c.Initial_Response_Body__c = c.Last_Response_Body__c;
      c.Initial_Response_Timestamp__c = c.Last_Response_Timestamp__c;
      c.Initial_Response_Status_Code__c = c.Last_Response_Status_Code__c;
    }
  }

  public void beforeDelete(SObject so)
  {
  }
  public void beforeUnDelete(SObject so)
  {
  }

  public void afterInsert(SObject so)
  {
  }

  public void afterUpdate(SObject oldSo, SObject so)
  {
  }

  public void afterDelete(SObject so)
  {
  }

  public void afterUnDelete(SObject so)
  {
  }

  /**
   * andFinally
   *
   * This method is called once all records have been processed by the trigger. Use this
   * method to accomplish any final operations such as creation or updates of other records.
   */
  public void andFinally()
  {
  }
}