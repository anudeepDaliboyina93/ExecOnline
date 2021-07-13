global class ApexUtility {
    
    global class wtException extends Exception {}

    global static String getObjectNameFromId(Id objId){
        return objId.getSObjectType().getDescribe().getName();
    }

    global static Boolean isValidId(String Idparam) {
        String idString = String.escapeSingleQuotes(Idparam);
        return idString instanceOf Id;
    }

    global static String join(List<String> strings, String delimiter) {
        return String.join(strings, delimiter);
    }

    global static Map<String,Schema.SObjectType> globalDescribe;
    global static Map<String,Schema.SObjectType> getGlobalDescribe() {
        if (globalDescribe == null) {
            globalDescribe = Schema.getGlobalDescribe();
        }
        return globalDescribe;
    }

    global static Map<String, Map<String,Schema.SObjectField>> objNameToObjFieldMap = new Map<String, Map<String,Schema.SObjectField>>();
    global static Map<String, Schema.SObjectField> getObjectFieldMap(String objName) {
        Map<String, Schema.SObjectField> objFieldMap = objNameToObjFieldMap.get(objName);
        if(objFieldMap == null) {
            objFieldMap = getGlobalDescribe().get(objName).getDescribe().fields.getMap();
            objNameToObjFieldMap.put(objName, objFieldMap);
        }
        return objFieldMap;
    }

    global static String getObjectFieldType(String objName, String fieldName) {
        Map<String, Schema.SObjectField> objectToFieldMap = getObjectFieldMap(objName);
        Schema.SObjectField field = objectToFieldMap.get(fieldName);
        try {
            return field.getDescribe().getType().Name();
        } catch(Exception e) {
            throw new wtException('Invalid field name in Integration Field Configuration : ' + fieldName);
        }
    }

    global static Boolean didFieldValueChangeCaseSensitive(SObject obj1, SObject obj2, String fieldName) {
        String objName = ApexUtility.getObjectNameFromId(obj1.Id);
        String soType = ApexUtility.getObjectFieldType(objName, fieldName);
        if (obj1.get(fieldName) != obj2.get(fieldName)) {
            return true;
        }
        if (obj1.get(fieldName) == null || obj2.get(fieldName) == null) {
            return false;
        }
        if (soType == 'String') {    
            String strBefore = String.valueof(obj1.get(fieldName));
            String strAfter = String.valueof(obj2.get(fieldName));
            return (!strBefore.equals(strAfter));
        }
        return obj1.get(fieldName) != obj2.get(fieldName);
    }
    
    global static Boolean isFieldValDifferent(SObject obj1, SObject obj2, String fieldName) {
        return obj1.get(fieldName) != obj2.get(fieldName);
    }

    global static Set<Id> getIdSetFromList(List<SObject> objList, String fieldName) {
        Set<Id> idSet = new Set<Id>();
        for(SObject obj : objList) {
            idSet.add((Id)obj.get(fieldName));
        }
        return idSet;
    }

    global static String getRecordTypeNameFromId(String sobjName, Id recordTypeId) {
        return getGlobalDescribe().get(sobjName).getDescribe().getRecordTypeInfosById().get(recordTypeId).getName();
    }

         //fetch picklist values from custom object in lwc
        @AuraEnabled(cacheable=true)
         global static List < customValueWrapper > getPicklistOptions(sObject customObjInfo, string selectPicklistApi) {
            Schema.DescribeSObjectResult objDescribe = customObjInfo.getSObjectType().getDescribe();     
            map < String, Schema.SObjectField > customFieldMap = objDescribe.fields.getMap();      
            list < Schema.PicklistEntry > custPickValues = customFieldMap.get(selectPicklistApi).getDescribe().getPickListValues();
            list < customValueWrapper > customObjWrapper = new list < customValueWrapper > ();
            for (Schema.PicklistEntry myCustPick: custPickValues) {
              customValueWrapper selectOptionValueWrapper = new customValueWrapper();
                 selectOptionValueWrapper.label = myCustPick.getLabel();
                 selectOptionValueWrapper.value = myCustPick.getValue();
                customObjWrapper.add(selectOptionValueWrapper);
            }
            system.debug(customObjWrapper);
            return customObjWrapper;
      
          }

          public static Map<String, List<String>> getDependentPicklistValues(Schema.sObjectField dependToken) {
            Schema.DescribeFieldResult depend = dependToken.getDescribe();
            Schema.sObjectField controlToken = depend.getController();
            if (controlToken == null) {
                return new Map<String, List<String>>();
            }
         
            Schema.DescribeFieldResult control = controlToken.getDescribe();
            List<Schema.PicklistEntry> controlEntries;
            if(control.getType() != Schema.DisplayType.Boolean) {
                controlEntries = control.getPicklistValues();
            }
         
            String base64map = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
            Map<String,List<String>> dependentPicklistValues = new Map<String,List<String>>();
            for (Schema.PicklistEntry entry : depend.getPicklistValues()) {
                if (entry.isActive() && String.isNotEmpty(String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')))) {
                    List<String> base64chars =
                            String.valueOf(((Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(entry))).get('validFor')).split('');
                    for (Integer index = 0; index < (controlEntries != null ? controlEntries.size() : 2); index++) {
                        Object controlValue =
                                (controlEntries == null
                                        ?   (Object) (index == 1)
                                        :   (Object) (controlEntries[index].isActive() ? controlEntries[index].getLabel() : null)
                                );
                        Integer bitIndex = index / 6;
                        if (bitIndex > base64chars.size() - 1) {
                            break;
                        }
                        Integer bitShift = 5 - Math.mod(index, 6);
                        if  (controlValue == null || (base64map.indexOf( base64chars[ bitIndex ] ) & (1 << bitShift)) == 0)
                            continue;
                        if (!dependentPicklistValues.containsKey((String) controlValue)) {
                            dependentPicklistValues.put((String) controlValue, new List<String>());
                        }
                        dependentPicklistValues.get((String) controlValue).add(entry.getLabel());
                    }
                }
            }
            return dependentPicklistValues;
        } 

          
          global with sharing class customValueWrapper {
            @AuraEnabled public string label {get;set;}
            @AuraEnabled public string value {get;set;}
         }

}