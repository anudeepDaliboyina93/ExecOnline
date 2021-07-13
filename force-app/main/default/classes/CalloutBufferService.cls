public with sharing class CalloutBufferService {

    // public static Map <String, String> resourceUrls = new Map<String, String> {
    //     'Opportunity' => '/{versionNum}/salesforce/opportunities'
    // };
    //
    // public static Callout_Buffer_Configuration__c calloutBufferConfig = Callout_Buffer_Configuration__c.getInstance();
    // public static List<Integration_Field_Configuration__c> integrationFieldConfigs  {
    //     get{
    //         if (integrationFieldConfigs == null) {
    //             integrationFieldConfigs = [select  Field__c, Id, Integration_Key__c, Name, Object_Type__c from Integration_Field_Configuration__c];
    //             return integrationFieldConfigs;
    //         } else {
    //             return integrationFieldConfigs;
    //         }
    //     }
    //     private set;
    // }

    public static final Map<String, String> REQUEST_HEADERS = new Map<String, String> {'Content-Type' => 'application/json', 'Accept' => 'application/json'};

    public static final Integer BUFFER_BATCH_LIMIT = 5;

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

    public static String booleanStringWrapper {
        get{
            if (booleanStringWrapper == null) {
                booleanStringWrapper = '~~~';
            }
            return booleanStringWrapper;
        }
    }
    //
    // public static Map<String, Map<String, Integration_Field_Configuration__c>> integrationObjectToFieldMap {
    //     get{
    //         for (Integration_Field_Configuration__c integrationFieldConfig : integrationFieldConfigs) {
    //             List<Integration_Field_Configuration__c> fieldConfigs = new List<Integration_Field_Configuration__c>();
    //
    //             if (integrationObjectToFieldMap == null) {
    //                 integrationObjectToFieldMap = new Map<String, Map<String, Integration_Field_Configuration__c>>();
    //             }
    //
    //             Map <String, Integration_Field_Configuration__c> fieldConfigMap = integrationObjectToFieldMap.get(integrationFieldConfig.Object_Type__c);
    //             if (fieldConfigMap == null) {
    //                 fieldConfigMap = new Map<String, Integration_Field_Configuration__c>();
    //             }
    //
    //             fieldConfigMap.put(integrationFieldConfig.Field__c, integrationFieldConfig);
    //             integrationObjectToFieldMap.put(integrationFieldConfig.Object_Type__c, fieldConfigMap);
    //         }
    //
    //         System.debug('***integrationObjectToFieldMap: ' + integrationObjectToFieldMap);
    //         return integrationObjectToFieldMap;
    //     }
    //     private set;
    // }
    //
    // public static Boolean hasIntegrationFieldChanged(SObject updatedObject, SOBject previousObject) {
    //     Map<String, Integration_Field_Configuration__c> objectFieldConfigMap = getObjectFieldConfigMap(updatedObject);
    //     for (String field : objectFieldConfigMap.keySet()) {
    //         if (updatedObject.get(field) != previousObject.get(field)) {
    //             return true;
    //         }
    //     }
    //     return false;
    // }
    //
    // public static void enqueueObjects(List<SObject> objectsToEnqueue) {
    //     if (!objectsToEnqueue.isEmpty()) {
    //         List<String> results = setupCallouts(objectsToEnqueue);
    //
    //         if (results.size() == objectsToEnqueue.size()) {
    //             CalloutBuffer.flushBuffer();
    //         } else {
    //             for (SObject objectToEnqueue : objectsToEnqueue) {
    //                 objectToEnqueue.addError('Callout not correctly buffered.');
    //             }
    //             update objectsToEnqueue;
    //         }
    //     }
    // }
    //
    // public static List<String> setupCallouts(List<SObject> sourceObjects) {
    //     Map<String, String> headers = new Map<String, String> {'Content-Type' => 'application/json', 'Accept' => 'application/json'};
    //
    //     List<CalloutBuffer.calloutBufferItem> calloutBufferItems = new List<CalloutBuffer.calloutBufferItem>();
    //
    //     for (Sobject sourceObject : sourceObjects) {
    //         String resourceName = (String) Callout_Buffer_Resources__c.getInstance(sourceObject.getSObjectType().getDescribe().getName()).Resource__c;
    //         String body = '{"' + resourceName + '":[' + CalloutBufferService.buildJSONbody(sourceObject) + ']}';
    //
    //         String resource = '/{versionNum}/salesforce/' + resourceName;
    //
    //         System.debug('***resourceName:' + resourceName);
    //
    //         CalloutBuffer.calloutBufferItem calloutBufferItem = new CalloutBuffer.calloutBufferItem(resource, 'POST', body, null, headers, null);
    //         calloutBufferItems.add(calloutBufferItem);
    //     }
    //
    //     // Now add the buffer items we just created to the queue
    //     List<String> results = CalloutBuffer.addBufferItems(calloutBufferItems);
    //     return results;
    // }
    //
    // public static void checkForCallout(List<SObject> objectsToCallout) {
    //     for (SObject objectToCallout : objectsToCallout) {
    //         System.debug('***objectToCallout:' + objectToCallout);
    //         String jsonBody = CalloutBufferService.buildJSONbody(objectToCallout);
    //         System.debug('***jsonBody: ' + jsonBody);
    //     }
    // }
    //
    // public static List<Callout_Buffer_Item__C> buildCalloutBufferItems(List<Sobject> objectsToBuffer) {
    //     List<Callout_Buffer_Item__C> calloutBufferItems = new List<Callout_Buffer_Item__C>();
    //
    //
    //     return calloutBufferItems;
    // }
    //
    // public static Map<String, Integration_Field_Configuration__c> getObjectFieldConfigMap(SObject sourceObject) {
    //     String objectTypeString = sourceObject.getSObjectType().getDescribe().getName();
    //     return integrationObjectToFieldMap.get(objectTypeString);
    // }
    //
    // public static String buildJSONbody(Sobject sourceObject) {
    //     Schema.SObjectType objectType = sourceObject.getSObjectType();
    //     Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
    //     String objectTypeString = objectType.getDescribe().getName();
    //     System.debug('***objectTypeString: ' + objectTypeString);
    //     Map<String, Integration_Field_Configuration__c> objectFieldConfigMap = integrationObjectToFieldMap.get(objectTypeString);
    //
    //     System.debug('***objectFieldConfigMap: ' + objectFieldConfigMap);
    //
    //     Map<String, String> jsonBodyMap = new Map<String, String>();
    //
    //     jsonBodyMap.put('Id', sourceObject.id);
    //
    //     for (Schema.SObjectField field : fieldMap.values()) {
    //         String fieldName = (String) field.getDescribe().getName();
    //         System.debug('***fieldName: ' + fieldName);
    //
    //         List<Integration_Field_Configuration__c> fieldConfigEntries = new List<Integration_Field_Configuration__c>();
    //         Integration_Field_Configuration__c fieldConfig = objectFieldConfigMap.get(fieldName);
    //
    //         System.debug('***fieldConfig: ' + fieldConfig);
    //
    //         if (fieldConfig != null) {
    //             String objectFieldValue = '';
    //
    //             if (field.getDescribe().getType() == Schema.DisplayType.Date) {
    //                 objectFieldValue = ((Date)sourceObject.get(fieldConfig.Field__c)).format();
    //             } else if (field.getDescribe().getType() == Schema.DisplayType.Double) {
    //                 objectFieldValue = ((Decimal)sourceObject.get(fieldConfig.Field__c)).format();
    //             } else {
    //                 objectFieldValue = (String)sourceObject.get(fieldConfig.Field__c);
    //             }
    //
    //             System.debug('***objectFieldValue: ' + objectFieldValue);
    //             jsonBodyMap.put(fieldConfig.Integration_Key__c, objectFieldValue );
    //         }
    //
    //     }
    //
    //     System.debug('***jsonBodyMap: ' + jsonBodyMap);
    //
    //     return JSON.serialize(jsonBodyMap);
    // }

    public static void updateInProgressTimes() {
        Callout_Buffer_Item__c[] inProgress = [select id, Processing_Time__c, CreatedDate from Callout_Buffer_Item__c where Status__c = 'In-progress'];
        if (inProgress != null) {
            for (Callout_Buffer_Item__c cbi : inProgress) {
                cbi.Processing_Time__c = ((Decimal)(DateTime.now().getTime()) - (Decimal)(cbi.CreatedDate.getTime()))/60000;
            }
            update inProgress;
        }
    }

    public static void calloutConfigNotSet(Callout_Buffer_Item__c[] cbis) {
        updateCalloutItemsOnError(cbis, 999);
        scheduleNextCallout(cbis);
    }

    public static Boolean calloutError(Callout_Buffer_Item__c[] cbis) {
        updateCalloutItemsOnError(cbis, 999);
        return true;
    }

    public static Boolean calloutHttpError(Callout_Buffer_Item__c[] cbis, Integer httpResponseCode) {
        updateCalloutItemsOnError(cbis, httpResponseCode);
        return true;
    }

    public static void calloutSuccess(Callout_Buffer_Item__c[] cbis, Integer httpResponseCode, String response) {
        system.debug(response);
        // Map<String, String> responseJSON = (Map<String, String>)JSON.deserialize(response, Map<String, String>.class);
        List<Map<String, List<Map<String,String>>>> responseJSON = (List<Map<String, List<Map<String,String>>>>)JSON.deserialize(response, List<Map<String, List<Map<String,String>>>>.class);

        if (responseJSON[0].containsKey('SUCCESS')) {
            updateCalloutItemsOnJSONSuccess(cbis, httpResponseCode, response);
        }
        else {
            updateCalloutItemsOnJSONSuccessNot(cbis, httpResponseCode, response);
        }
        scheduleNextCallout();
        
    }
 
    private static void scheduleNextCallout() {
        // And finally we check to see if there's anything else on the buffer. If there is, schedule a job to invoke the flush method again. We have to do this, as future
        // methods can't call future methods.

        // TODO if status is new, run immediately, otherwise leave it at a minute

        Callout_Buffer_Item__c[] cbis = [select id, Status__c from Callout_Buffer_Item__c where Status__c != 'Complete'];
        if (!cbis.isEmpty() && Callout_Buffer_Configuration__c.getInstance().Callout_buffer_Enabled__c) {
            for (CronTrigger ct : [select id from CronTrigger where state = 'DELETED' AND CronJobDetail.Name = 'ScheduleNextCOBufferFlush']) {
                try {
                    system.abortJob(ct.id);
                } catch (Exception e) {}

            }
            // Boolean immediate = cbis[0].status__c != 'Error' ? true : false;
            DateTime retryDelay = DateTime.now().addSeconds(nextCalloutInterval);
            ScheduleCalloutBufferFlush j1 = new ScheduleCalloutBufferFlush();
            String sch = String.valueOf(retryDelay.second()) + ' ' + String.valueOf(retryDelay.minute()) + ' ' + String.valueOf(retryDelay.hour()) + ' ' + String.valueOf(retryDelay.day()) + ' ' + String.valueOf(retryDelay.month()) + ' ? ' + String.valueOf(retryDelay.year());
            system.debug(sch);
            try {
                system.schedule('ScheduleNextCOBufferFlush', sch, j1);
            } catch (Exception e) {}
        }
    }

    private static void updateCalloutItemsOnError(Callout_Buffer_Item__c[] cbis, Integer httpResponseCode) {
        DateTime nowTime = DateTime.now();
        for (Callout_Buffer_Item__c cbi : cbis) {
            cbi.Retry_Attempts__c = cbi.Retry_Attempts__c == null ? 1 : cbi.Retry_Attempts__c + 1;
            cbi.Last_Response_Body__c = 'Callout username, password, endpoint, or version not set';
            cbi.Last_Response_Timestamp__c = nowTime;
            cbi.Last_Response_Status_Code__c = httpResponseCode;
            cbi.Status__c = 'Error';
        }
        update cbis;
    }

    public static void updateCalloutItemsOnJSONSuccess(Callout_Buffer_Item__c[] cbis, Integer httpResponseCode, String response) {
        Map<String, String> responseJSON = (Map<String, String>)JSON.deserialize(response, Map<String, String>.class);
        DateTime nowTime = DateTime.now();
        for (Callout_Buffer_Item__c cbi : cbis) {
            if (!Test.isRunningTest()) {
	            cbi.Last_Response_Body__c = response.substring(0,32000);
            }
            cbi.Last_Response_Timestamp__c = nowTime;
            cbi.Last_Response_Status_Code__c = httpResponseCode;
            cbi.Status__c = 'Complete';
            if (responseJSON.get('SUCCESS') != 'SUCCESS') {
                cbi.warning_text__c = responseJSON.get('SUCCESS');
            }
        }
        if (!Test.isRunningTest()) {
            update cbis;
        }
    }

    private static void updateCalloutItemsOnJSONSuccessNot(Callout_Buffer_Item__c[] cbis, Integer httpResponseCode, String response) {
        DateTime nowTime = DateTime.now();
        for (Callout_Buffer_Item__c cbi : cbis) {
            cbi.Retry_Attempts__c = cbi.Retry_Attempts__c == null ? 1 : cbi.Retry_Attempts__c + 1;
            cbi.Last_Response_Body__c = response;
            cbi.Last_Response_Timestamp__c = nowTime;
            cbi.Last_Response_Status_Code__c = httpResponseCode;
            cbi.Status__c = 'Complete';
        }
        update cbis;
    }


    public static String generateCalloutBody(Callout_Buffer_Item__c[] cbis) {
        String[] cbiBodies = new List<String>();
        for (Callout_Buffer_Item__c cbi : cbis) {
            System.debug('***generatecalloutbody for : ' +cbi );

            cbiBodies.add(cbi.Callout_Body__c);
        }
        String calloutBody = '{ "batch" : [';
        calloutBody += ApexUtility.join(cbiBodies,',');
        calloutBody += ']}';
        return calloutBody;
    }

    public static void addCalloutIds(List<Callout_Buffer_Item__c> cbis) {
        for (Callout_Buffer_Item__c cbi : cbis) {
            addCalloutId(cbi);
        }
    }

    public static Boolean doCalloutForContactType(Contact c) {
        String contactTypeString = c.Contact_Type__c;
        if (contactTypeString == null) {
            return false;
        }
        List<String> contactTypes = contactTypeString.split(';');
        for (String type : contactTypes) {
            if (ContactService.contactTypesToBuffer.contains(type)) {
                return true;
            }
        }
        return false;
    }

    private static void scheduleNextCallout(List<Callout_Buffer_Item__c> cbi) {
        // And finally we check to see if there's anything else on the buffer. If there is, schedule a job to invoke the flush method again. We have to do this, as future
        // methods can't call future methods.

        // TODO if status is new, run immediately, otherwise leave it at a minute

        Callout_Buffer_Item__c[] cbis = [select id, Status__c from Callout_Buffer_Item__c where Status__c != 'Complete'];
        if (!cbis.isEmpty() && Callout_Buffer_Configuration__c.getInstance().Callout_buffer_Enabled__c) {
            for (CronTrigger ct : [select id from CronTrigger where state = 'DELETED' AND CronJobDetail.Name = 'ScheduleNextCOBufferFlush']) {
                try {
                    system.abortJob(ct.id);
                } catch (Exception e) {}

            }
            // Boolean immediate = cbis[0].status__c != 'Error' ? true : false;
            DateTime retryDelay = DateTime.now().addSeconds(nextCalloutInterval);
            ScheduleCalloutBufferFlush j1 = new ScheduleCalloutBufferFlush();
            String sch = String.valueOf(retryDelay.second()) + ' ' + String.valueOf(retryDelay.minute()) + ' ' + String.valueOf(retryDelay.hour()) + ' ' + String.valueOf(retryDelay.day()) + ' ' + String.valueOf(retryDelay.month()) + ' ? ' + String.valueOf(retryDelay.year());
            system.debug(sch);
            try {
                system.schedule('ScheduleNextCOBufferFlush', sch, j1);
            } catch (Exception e) {}
        }
    }

    private static void addCalloutId(Callout_Buffer_Item__c cbi) {
        String calloutBody = cbi.Callout_Body__c;
        system.debug(calloutBody);
        Map<String, List<Map<String,String>>> bodyJSON = (Map<String, List<Map<String,String>>>)JSON.deserialize(calloutBody, Map<String, List<Map<String,String>>>.class);
        Set<String> resources = bodyJSON.keySet();
        String[] resourceNames = new List<String>();
        resourceNames.addAll(resources);
        bodyJSON.get(resourceNames[0])[0].put('calloutid', cbi.name);
        calloutbody = JSON.serialize(bodyJSON);
        cbi.Callout_Body__c = calloutbody;
    }




}