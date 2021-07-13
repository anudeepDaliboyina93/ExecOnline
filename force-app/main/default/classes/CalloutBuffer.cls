/* CalloutBuffer.cls
* Copyright 2014 Wired Triangle, LLC
* http://www.wiredtriangle.com
*
* This class provides static methods to manipulate the callout buffer
*
*/

public with sharing class CalloutBuffer {
    public static Callout_Buffer_Configuration__c calloutBufferConfig = Callout_Buffer_Configuration__c.getInstance();

    public static Integer bufferBatchLimit = CalloutBufferService.BUFFER_BATCH_LIMIT;

    public static Integer nextCalloutInterval {
        get{
            if (nextCalloutInterval == null) {
                nextCalloutInterval = (Integer)Callout_Buffer_Configuration__c.getInstance().Next_Callout_Interval__c;
                if (nextCalloutInterval == null) {
                    nextCalloutInterval = 30;
                }
                return nextCalloutInterval;
            }
            return nextCalloutInterval;
        }
    }
//edit
    public static List<Integration_Field_Configuration__c> integrationFieldConfigs  {
        get{
            if (integrationFieldConfigs == null) {
                integrationFieldConfigs = [select  Field__c, Id, Integration_Key__c, Name, Object_Type__c from Integration_Field_Configuration__c];
                return integrationFieldConfigs;
            } else {
                return integrationFieldConfigs;
            }
        }
        private set;
    }

    public static Set<String> excludedUserIds {
        get{
            if (excludedUserIds == null) {
                List<String> excludedUserIdList = new List<String>();

                String excludedUserIdsString = (String)Callout_Buffer_Configuration__c.getInstance().User_Exclusion_List__c;
                if (excludedUserIdsString != null) {
                    excludedUserIdList = excludedUserIdsString.split(',');  // can't split a list of type Id
                    excludedUserIds = new Set<String>(excludedUserIdList);
                    return excludedUserIds;
                }
                else {
                    excludedUserIds = new Set<String>();
                    return excludedUserIds;
                }
            }
            return excludedUserIds;
        }
    }

    public static Map<String, Map<String, Integration_Field_Configuration__c>> integrationObjectToFieldMap {
        get{
            for (Integration_Field_Configuration__c integrationFieldConfig : integrationFieldConfigs) {
                List<Integration_Field_Configuration__c> fieldConfigs = new List<Integration_Field_Configuration__c>();

                if (integrationObjectToFieldMap == null) {
                    integrationObjectToFieldMap = new Map<String, Map<String, Integration_Field_Configuration__c>>();
                }

                Map <String, Integration_Field_Configuration__c> fieldConfigMap = integrationObjectToFieldMap.get(integrationFieldConfig.Object_Type__c);
                if (fieldConfigMap == null) {
                    fieldConfigMap = new Map<String, Integration_Field_Configuration__c>();
                }

                fieldConfigMap.put(integrationFieldConfig.Field__c, integrationFieldConfig);
                integrationObjectToFieldMap.put(integrationFieldConfig.Object_Type__c, fieldConfigMap);
            }

            System.debug('***integrationObjectToFieldMap: ' + integrationObjectToFieldMap);
            return integrationObjectToFieldMap;
        }
        private set;
    }

    public static String booleanStringWrapper {
        get{
            if (booleanStringWrapper == null) {
                booleanStringWrapper = '~~~';
            }
            return booleanStringWrapper;
        }
    }

    public CalloutBuffer() {
    }

    public static Boolean excludeUserFromCallouts() {
        if (excludedUserIds.size() > 0){
            return excludedUserIds.contains(UserInfo.getUserId());
        }
        return false;
    }

    public static Boolean hasIntegrationFieldChanged(SObject updatedObject, SOBject previousObject) {
        Map<String, Integration_Field_Configuration__c> objectFieldConfigMap = getObjectFieldConfigMap(updatedObject);
        if (objectFieldConfigMap != null) {
            for (String field : objectFieldConfigMap.keySet()) {
                if (ApexUtility.didFieldValueChangeCaseSensitive(updatedObject, previousObject, field)) {
                    return true;
                }
            }
        }
        return false;
    }


    public static void enqueueObjects(ObjectsToEnqueueWrapper objectsToEnqueue) {
        enqueueObjects(objectsToEnqueue.objects, objectsToEnqueue.actionType);
    }


    public static void enqueueObjects(List<SObject> objectsToEnqueue, String action) {
        if (!excludeUserFromCallouts()) {
            if (!objectsToEnqueue.isEmpty()) {
                List<String> results = setupCallouts(objectsToEnqueue, action);

                if (results.size() == objectsToEnqueue.size()) {
                    flushBuffer();
                } else {
                    //for (SObject objectToEnqueue : objectsToEnqueue) {
                    //    objectToEnqueue.addError('Callout not correctly buffered.');
                    //}
                    //update objectsToEnqueue;
                }
            }
        }
        else {
            System.debug('Callouts not executed for user ' + UserInfo.getUserId());
        }
    }

    public static List<String> setupCallouts(List<SObject> sourceObjects, String action) {
        Map<String, String> headers = CalloutBufferService.REQUEST_HEADERS;

        List<CalloutBuffer.calloutBufferItem> calloutBufferItems = new List<CalloutBuffer.calloutBufferItem>();

        for (Sobject sourceObject : sourceObjects) {
            Callout_Buffer_Resources__c bufferResource =  Callout_Buffer_Resources__c.getInstance(sourceObject.getSObjectType().getDescribe().getName());
            if (bufferResource != null && bufferResource.Enabled__c) {
                String resourceName = (String) bufferResource.Resource__c;

                String body = '{"' + resourceName + '":[' + buildJSONbody(sourceObject, action) + ']}';

                String resource = '/{versionNum}/salesforce/' + resourceName;

                System.debug('***resourceName:' + resourceName);

                CalloutBuffer.calloutBufferItem calloutBufferItem = new calloutBufferItem(resource, action, body, null, headers, null);
                calloutBufferItems.add(calloutBufferItem);
            }
        }

        // Now add the buffer items we just created to the queue
        List<String> results = CalloutBuffer.addBufferItems(calloutBufferItems);
        return results;
    }

    // NOT USED
    // public static void checkForCallout(List<SObject> objectsToCallout) {
    //     for (SObject objectToCallout : objectsToCallout) {
    //         System.debug('***objectToCallout:' + objectToCallout);
    //         String jsonBody = buildJSONbody(objectToCallout);
    //         System.debug('***jsonBody: ' + jsonBody);
    //     }
    // }

    public static List<Callout_Buffer_Item__C> buildCalloutBufferItems(List<Sobject> objectsToBuffer) {
        List<Callout_Buffer_Item__C> calloutBufferItems = new List<Callout_Buffer_Item__C>();

        return calloutBufferItems;
    }

    public static Map<String, Integration_Field_Configuration__c> getObjectFieldConfigMap(SObject sourceObject) {
        String objectTypeString = sourceObject.getSObjectType().getDescribe().getName();

        if (integrationObjectToFieldMap != null) {
            return integrationObjectToFieldMap.get(objectTypeString);
        } else {
            return null;
        }
    }

    public static String buildJSONbody(Sobject sourceObject, String action) {
        Schema.SObjectType objectType = sourceObject.getSObjectType();
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
        String objectTypeString = objectType.getDescribe().getName();
        System.debug('***objectTypeString: ' + objectTypeString);
        Map<String, Integration_Field_Configuration__c> objectFieldConfigMap = integrationObjectToFieldMap.get(objectTypeString);

        System.debug('***objectFieldConfigMap: ' + objectFieldConfigMap);

        Map<String, String> jsonBodyMap = new Map<String, String>();

        jsonBodyMap.put('sfid', sourceObject.id);
        jsonBodyMap.put('Action', action);

        for (Schema.SObjectField field : fieldMap.values()) {
            String fieldName = (String) field.getDescribe().getName();
            System.debug('***fieldName: ' + fieldName);

            List<Integration_Field_Configuration__c> fieldConfigEntries = new List<Integration_Field_Configuration__c>();
            Integration_Field_Configuration__c fieldConfig = objectFieldConfigMap.get(fieldName);

            System.debug('***fieldConfig: ' + fieldConfig);

            if (fieldConfig != null) {
                String objectFieldValue = '';

                if (field.getDescribe().getType() == Schema.DisplayType.Date) {
                    if (sourceObject.get(fieldConfig.Field__c) != null) {
                        objectFieldValue = ((Date)sourceObject.get(fieldConfig.Field__c)).format();
                    } else {
                        objectFieldValue = (String)sourceObject.get(fieldConfig.Field__c);
                    }
                } else if (field.getDescribe().getType() == Schema.DisplayType.Datetime) {
                    if (sourceObject.get(fieldConfig.Field__c) != null) {
                        objectFieldValue = ((Datetime)sourceObject.get(fieldConfig.Field__c)).format();
                    } else {
                        objectFieldValue = (String)sourceObject.get(fieldConfig.Field__c);
                    }
                } else if (field.getDescribe().getType() == Schema.DisplayType.Double) {
                    if (sourceObject.get(fieldConfig.Field__c) != null) {
                        objectFieldValue = ((Decimal)sourceObject.get(fieldConfig.Field__c)).format();
                    } else {
                        objectFieldValue = (String)sourceObject.get(fieldConfig.Field__c);
                    }
                } else if (field.getDescribe().getType() == Schema.DisplayType.Boolean) {
                    objectFieldValue = String.valueOf(sourceObject.get(fieldConfig.Field__c));
                    objectFieldValue = booleanStringWrapper + objectFieldValue + booleanStringWrapper;
                } else {
                    objectFieldValue = (String)sourceObject.get(fieldConfig.Field__c);
                }

                System.debug('***objectFieldValue: ' + objectFieldValue);
                jsonBodyMap.put(fieldConfig.Integration_Key__c, objectFieldValue );
            }

        }

        String jsonBodyString = convertJSONBodyMapToString(jsonBodyMap);

        return jsonBodyString;
    }

    // Add an item to the buffer. Returns the SFId of the newly-inserted buffer item
    public static List<String> addBufferItems(List<calloutBufferItem> cbs) {
        List<Callout_Buffer_Item__c> cbis = new List<Callout_Buffer_Item__c>();
        for (calloutBufferItem cb : cbs) {
            Callout_Buffer_Item__c cbi = new Callout_Buffer_Item__c();
            cbi.Endpoint__c = cb.endpoint;
            cbi.Type__c = cb.type;
            cbi.Callout_Body__c = cb.body;
            cbi.Callback_Handler__c = cb.handler;
            cbi.Headers__c = JSON.serialize(cb.headers);
            cbi.Item_Data__c = cb.itemData;
            cbi.Status__c = 'Queued';
            cbis.add(cbi);
        }
        try {
            insert cbis;
        } catch (DMLException e) {
            return new List<String>();
        }
        // Let's go through and get all of our new ids to return
        List<String> insertedCBIs = new List<String>();
        for (Callout_Buffer_Item__c cbi : cbis) {
            insertedCBIs.add(cbi.id);
        }
        return insertedCBIs;
    }


    // Delete an item from the buffer
    public static List<String> deleteBufferItems(List<String> bufferItemIds) {
        List<String> r = new List<String>();
        Callout_Buffer_Item__c[]  cbis = [select id from Callout_Buffer_Item__c where id in :bufferItemIds AND Status__c = 'Queued'];
        for (Callout_Buffer_Item__c c : cbis) {
            r.add(c.id);
        }
        try {
            delete cbis;
        } catch (Exception e) {
            return new List<String>();
        }
        return r;
    }

    // Flush the buffer. This is the generic, not from a scheduled call flush.
    public static List<String> flushBuffer() {
        return flushBuffer(false);
    }


    // Flush the bufffer. That is, grab the oldest unreserved, unfinished buffer item, and submit it for execution
    public static List<Id> flushBuffer(Boolean fromSchedule) {
        if (!Callout_Buffer_Configuration__c.getInstance().Callout_Buffer_Enabled__c) {
            return new List<String>();
        }

        if (!Test.isRunningTest()) {
            Integer ct = [select count() from CronTrigger where CronJobDetail.Name = 'ScheduleNextCOBufferFlush' AND State != 'DELETED'];
            // If we have a scheduled job, let's let that do it's job in a minute, and return a blank list
            // (we check to see if this flush was called from a scheduled job, because in that case, it hasn't been marked as deleted
            // yet and will return a false positve.)
            if (ct > 0 && !fromSchedule) {
                return new List<String>();
            }
        }

        // Let's check and see if anything is in progress, and if it is, return
        Integer ip = [select count() from Callout_Buffer_Item__c where Status__c = 'In-progress'];
        if (ip > 0) {
            CalloutBufferService.updateInProgressTimes();
            return new List<String>();
        }
        // And finally, grab the first n incomplete item and invoke the callout on it
        Callout_Buffer_Item__c[] cbis = [select id, name, Status__c from Callout_Buffer_Item__c where Status__c = 'Queued' OR Status__c = 'Error' order by name asc];
        Integer count = 0;
        for (Callout_Buffer_Item__c cbi : cbis) {
            cbi.Status__c = count < bufferBatchLimit ? 'In-progress' : 'Queued';
            system.debug('CBI.name : ' + cbi);
            system.debug('Count : ' + count + '  bufferBatchLimit : ' + bufferBatchLimit + ' CBI Status : ' + cbi.Status__c);
            count++;
        }
        update cbis;
        if (!cbis.isEmpty()) {
            List<Id> cbiIds = new List<Id>();
            for (Callout_Buffer_Item__c cbi : cbis) {
                cbiIds.add(cbi.id);
            }
            CalloutBuffer.invokeCallout(cbiIds);
        }
        return new List<Id>();
    }


    // The actual callout, handled via a future method. Takes a buffer item id as an argument
    @future (callout = true)
    public static void invokeCallout(String[] bufferItemIds) {

        DateTime nowTime = DateTime.now();

        Callout_Buffer_Item__c[] cbis = [select id, Item_Data__c, Status__c, Endpoint__c, Type__c, Callout_Body__c, Callback_Handler__c, Initial_Response_Body__c, Initial_Response_Status_Code__c, Initial_Response_Timestamp__c, Retry_Attempts__c, Last_Response_Body__c, Headers__c, Last_Response_Timestamp__c, Last_Response_Status_Code__c, Name from Callout_Buffer_Item__c where id in :bufferItemIds order by name asc LIMIT :bufferBatchLimit];
        // if (cbis.size() != 1) return;

        // System.debug('***Endpoint__c at invokeCallout:' + cbis[0].Endpoint__c);

        String username = Callout_Buffer_Configuration__c.getInstance().UserName__c;
        String password = Callout_Buffer_Configuration__c.getInstance().Password__c;
        String endpoint = Callout_Buffer_Configuration__c.getInstance().Endpoint_Address__c;
        String version = Callout_Buffer_Configuration__c.getInstance().Version__c;
        String token = Callout_Buffer_Configuration__c.getInstance().Token__c;

        if (username == null || password == null || endpoint == null || version == null) {
            CalloutBufferService.calloutConfigNotSet(cbis);
            return;
        }

        Http httpProtocol = new Http();
        HttpRequest request = new HttpRequest();

        Long messageTime = nowTime.getTime();

        // Set the endpoint URL.
        String thisEndpoint =  endpoint + '/{versionNum}/salesforce/batches'.replace('{versionNum}', version);

        request.setEndPoint(thisEndpoint);
        request.setMethod('POST');
        //TODO headers
        Map<String, String> headers = CalloutBufferService.REQUEST_HEADERS;
        for (String s : headers.keySet()) {
            request.setHeader(s, headers.get(s));
        }
        //request.setHeader('Authorization','Basic '+EncodingUtil.base64encode(Blob.valueOf(username+password)));
        request.setHeader('X-Partner-Token', token);
        request.setTimeout(60000);
        CalloutBufferService.addCalloutIds(cbis);
        String calloutBody = CalloutBufferService.generateCalloutBody(cbis);
        System.debug('***request headers' + request );
        system.debug('callout body: ' + calloutBody);
        request.setBody(calloutBody);
        HttpResponse response;
        Boolean gotError = false;
        try {
            response = httpProtocol.send(request);
            Integer responseCode = response.getStatusCode();

            // Did the callout work, but we got an http error? If so, log the http error to the buffer item
            if (!gotError && (responseCode != 200 && responseCode != 201)) {
                gotError = CalloutBufferService.calloutHttpError(cbis, responseCode);
            }

            // If we've gotten this far, we had a successful callout, and can pass the data off to the callout response handler
            // (Note that the reponse handler is currently unneeded and unused, but exists for future expandability)
            if (!gotError) {
                String body = response.getBody();
                system.debug('***RESPONSE BODY : ' + body);
                // Here we call the handler class, and pass it the response body, as well as whatever data the original calling class wanted to send along
                //Not currenlty getting any response
                String calloutResponse = CalloutBufferResponseHandlers.responseHandler(null, body, null);
                CalloutBufferService.calloutSuccess(cbis, responseCode, body);
            }
        }
        // Did we get an error on the actual callout? If so, log the error message to the buffer item
        catch (CalloutException e) {
            gotError = CalloutBufferService.calloutError(cbis);
        }


    }


    private static String convertJSONBodyMapToString(Map<String, String> JSONBodyMap) {
        String jsonBodyString = JSON.serialize(jsonBodyMap);
        jsonBodyString = jsonBodyString.replace(('"'+booleanStringWrapper),'');
        jsonBodyString = jsonBodyString.replace((booleanStringWrapper+'"'),'');
        return jsonBodyString;
    }



    public static Map<String, Object> generateObjectBody(String objectType, SObject so) {
        Map<String, Object> r = new Map<String, Object>();
        for (CRM_Integration_Services_Field__c f : [select field__c, integration_key__c from CRM_Integration_Services_Field__c where Object_Type__c = :objectType]) {
            try {
                r.put(f.integration_key__c, so.get(f.field__c));
            }
            Catch (Exception e) {

            }
        }
        return r;
    }

    public class calloutBufferItem {
        String endpoint;
        String type;
        String body;
        String handler;
        Map<String, String> headers;
        String itemData;

        public calloutBufferItem(String endpoint, String type, String body, String handler, Map<String, String> headers, String itemData) {
            this.endpoint = endpoint;
            this.type = type;
            this.body = body;
            this.handler = handler;
            this.headers = headers;
            this.itemData = itemData;
        }
    }

    public class objectsToEnqueueWrapper {
        public String actionType;
        public List<SObject> objects;

        public objectsToEnqueueWrapper() {
            this.objects = new List<SObject>();
        }

        public objectsToEnqueueWrapper(String type, List<SObject> objects) {
            this.actionType = actionType;
            this.objects = objects;
        }

        public Boolean isEmpty() {
            return (objects.size() == 0);
        }
    }
}