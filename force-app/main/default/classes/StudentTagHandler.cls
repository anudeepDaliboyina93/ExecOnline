/**
 * StudentTagHandler.cls
 * Copyright 2019 Wired Triangle, LLC
 * http://www.wiredtriangle.com
 */
global with sharing class StudentTagHandler implements ITrigger {
    
    public List<Student_Tag__c> triggerListStudentTags = new List<Student_Tag__c>();
    public List<Id> triggerStudentIdList = new List<Id>();
    public static Map<Id,Id> studentIdContactIdMap = new Map<Id,Id>();
    public static Map<Id, Student__c> studentIdStudentMap = new Map<Id, Student__c>();
    public static Map<Id, Map<String, Student_Tag__c>> studentId_TagStringStudentTagMap = new Map<Id,  Map<String,Student_Tag__c>>();
    public List<Student_Tag__c> studentTagsToDelete = new List<Student_Tag__c>();
    public Map<Id, List<Id>> studentIdServiceIdListMap = new Map<Id, List<Id>>();
    public Map<Id, List<EPC_Utilization_Item__c>> studentIdEPCUIListMap = new Map<Id,List<EPC_Utilization_Item__c>>();
    public Map<Id, Map<Id,EPC_Utilization_Item__c>> studentId_ServiceIdEPCUIMap_Map = new Map<Id,Map<Id,EPC_Utilization_Item__c>>();
    public Map<String, List<Service__c>> TagStringServicesListMap = new Map<String,List<Service__c>>();
    public Map<Id, Service__c> serviceIdServiceMap = new Map<Id, Service__c>();
    public Map<Id, List<Id>> tagIdServiceIdListMap = new Map<Id, List<Id>>();
    public static Map<Id,String> tagIdTagNameMap = new Map<Id,String>();
    public List<Student_Tag__c> studentTagList = new List<Student_Tag__c>();
    public Map<Id, List<Student_Tag__c>> studentId_StudentTagAddedList_Map = new Map<Id,List<Student_Tag__c>>();
    public Map<Id, List<Student_Tag__c>> studentId_StudentTagRemovedList_Map = new Map<Id,List<Student_Tag__c>>();
    
    public StudentTagHandler() {}

    public void populateBeforeVariables() {
        //POPULATE List: All Student_Tag__c records for any affected Student
        studentTagList = [SELECT Id, Student__c, Tag__c, Tag__r.Name FROM Student_Tag__c WHERE Student__c IN :triggerStudentIdList];
        system.Debug('STH:'+Trigger.operationType+'studentTagList='+studentTagList);

        //POPULATE Map: Student.Id to existing studentTags
        for (Student_Tag__c studentTag : studentTagList ) {
            if (studentId_TagStringStudentTagMap.get(studentTag.Student__c)==null) {
            studentId_TagStringStudentTagMap.put(studentTag.Student__c,new Map<String,Student_Tag__c>());
            }
            if (studentId_TagStringStudentTagMap.get(studentTag.Student__c).get(studentTag.Tag__r.Name) == null) {
                studentId_TagStringStudentTagMap.get(studentTag.Student__c).put(studentTag.Tag__r.Name, studentTag);
            }
        }
        system.Debug('STH:'+Trigger.operationType + 'studentId_TagStringStudentTagMap='+studentId_TagStringStudentTagMap);
    }

    public void populateVariables() {
        if (Trigger.isDelete) {
            triggerListStudentTags = (List<Student_Tag__c>)Trigger.old;
        } else {
            triggerListStudentTags = (List<Student_Tag__c>)Trigger.new;
        }

        //POPULATE Map: Tag.Id to List of it's Tag_Service__c records
        //POPULATE Map: Tag.Id to Tag.Name (tag string)
        //POPULATE Map keySet : Service.Id to null (placeholder for Service__c record)
        List<Tag_Service__c> tagServiceList = new List<Tag_Service__c>([SELECT Id, Tag__c, Tag__r.Name, Service__c FROM Tag_Service__c]);
        for (Tag_Service__c ts:tagServiceList) {
            if (tagIdServiceIdListMap.get(ts.tag__c)==null) {
                tagIdServiceIdListMap.put(ts.tag__c,new List<Id>());
            }
            tagIdServiceIdListMap.get(ts.tag__c).add(ts.service__c);
            tagIdTagNameMap.put(ts.tag__c, ts.tag__r.Name);
            serviceIdServiceMap.put(ts.service__c,null);
        }
        system.Debug('STH:'+Trigger.operationType+'tagIdServiceIdListMap='+tagIdServiceIdListMap);

        //POPULATE Map keySet : Service.Id to Service__c record
        serviceIdServiceMap = new Map<Id, Service__c>([SELECT Id, Utilization_Date_Formula__c FROM Service__c WHERE Id IN :serviceIdServiceMap.keySet()]);
        system.Debug('STH:'+Trigger.operationType+'serviceIdServiceMap='+serviceIdServiceMap);
        
        //POPULATE List: StudentTag.Id in this Trigger
        //POPULATE Map: StudentId to null List of StudentTagAdded
        //POPULATE Map: StudentId to null List of StudentTagRemoved
        //POPULATE Map: StudentId to null Map of (ServiceId to EPCU.Id)
        for (Student_Tag__c st:triggerListStudentTags) {
            triggerStudentIdList.add(st.student__c);
            if (studentId_StudentTagAddedList_Map.get(st.Student__c) == null) {
                studentId_StudentTagAddedList_Map.put(st.Student__c,new List<Student_Tag__c>());
            }
            if (studentId_StudentTagRemovedList_Map.get(st.Student__c) == null) {
                studentId_StudentTagRemovedList_Map.put(st.Student__c,new List<Student_Tag__c>());
            }
            if (studentId_ServiceIdEPCUIMap_Map.get(st.Student__c) == null) {
                studentId_ServiceIdEPCUIMap_Map.put(st.Student__c, new Map<Id,EPC_Utilization_Item__c>());
            }

        }
        system.Debug('STH:'+Trigger.operationType+'triggerStudentIdList='+triggerStudentIdList);

        //POPULATE Map: Student.Id to Contact.Id
        //POPULATE Map: Student.Id to Student
        List<Student__c> studentList = new List<Student__c>([SELECT Id, Contact__c, Program__c, Program__r.Course_Start_Date__c, Previous_Program__r.Course_Start_Date__c FROM Student__c WHERE Id IN :studentId_StudentTagAddedList_Map.keySet()]);
                system.Debug('STH:'+Trigger.operationType+'studentList='+studentList);

        for (Student__c student:studentList) {
            studentIdContactIdMap.put(student.Id, student.Contact__c);
            studentIdStudentMap.put(student.Id, student);
        } 
        system.Debug('STH:'+Trigger.operationType+'studentIdContactIdMap='+studentIdContactIdMap);

        //POPULATE Map: Student.Id to (List of Services via Student_Tag__c in this Trigger)
        for (Student_Tag__c st:triggerListStudentTags) {
            if (studentIdServiceIdListMap.get(st.student__c)==null) {
                studentIdServiceIdListMap.put(st.student__c, new List<Id>());
            }
            if (tagIdServiceIdListMap.get(st.tag__c) != null) {
                for (Id serviceId:tagIdServiceIdListMap.get(st.tag__c)) {
                studentIdServiceIdListMap.get(st.student__c).add(serviceId);
                }
            }
        }
        system.Debug('STH:'+Trigger.operationType + 'studentIdServiceIdListMap='+studentIdServiceIdListMap);

        List<EPC_Utilization_Item__c> epcuiList = new List<EPC_Utilization_Item__c>([SELECT Id, Service__c, Student__c, Status__c FROM EPC_Utilization_Item__c where Student__c in:triggerStudentIdList]);
        for (EPC_Utilization_Item__c epcui:epcuiList) {
            studentId_ServiceIdEPCUIMap_Map.get(epcui.Student__c).put(epcui.Service__c,epcui);
        }
        system.Debug('STH:'+Trigger.operationType + 'studentId_ServiceIdEPCUIMap_Map='+studentId_ServiceIdEPCUIMap_Map);

    }

    public void bulkBefore() {
            populateVariables();
            populateBeforeVariables();
            system.Debug('STH:'+Trigger.operationType + 'studentId_TagStringStudentTagMap='+studentId_TagStringStudentTagMap);
    }

    public void bulkAfter() {
            populateVariables();
            system.Debug('STH:'+Trigger.operationType + 'studentId_TagStringStudentTagMap='+studentId_TagStringStudentTagMap);
   }

    public void beforeInsert(SObject so) {
        Student_Tag__c studentTag = (Student_Tag__c) so;
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        Student_Tag__c studentTag = (Student_Tag__c) so;
        Student_Tag__c oldStudentTag = (Student_Tag__c) oldSo;
    }

    public void beforeDelete(SObject so) {
    }

    public void beforeUnDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
        Student_Tag__c studentTag = (Student_Tag__c) so;
        studentId_StudentTagAddedList_Map.get(studentTag.Student__c).add(studentTag);
        // upsertEPCUIs(studentTag);
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        Student_Tag__c studentTag = (Student_Tag__c) so;
        Student_Tag__c oldStudentTag = (Student_Tag__c) oldSo;
        if (studentTag.Tag__c != oldStudentTag.Tag__c) {
            studentId_StudentTagAddedList_Map.get(studentTag.Student__c).add(studentTag);
            studentId_StudentTagAddedList_Map.get(studentTag.Student__c).add(oldStudentTag);
        }
        // upsertEPCUIs(studentTag);
        // upsertEPCUIs(studentTag);
    }
    
    public void afterDelete(SObject so) {
        Student_Tag__c studentTag = (Student_Tag__c) so;
        studentId_StudentTagRemovedList_Map.get(studentTag.Student__c).add(studentTag);
        // upsertEPCUIs(studentTag);
    }
    
    public void afterUnDelete(SObject so) {
        Student_Tag__c studentTag = (Student_Tag__c) so;
        studentId_StudentTagAddedList_Map.get(studentTag.Student__c).add(studentTag);
        // upsertEPCUIs(studentTag);
    }

    public void andFinally() {
        List<Student_Tag__c> studentTagsToUpsert = new List<Student_Tag__c>();
        system.Debug('STH:'+Trigger.operationType+'studentId_StudentTagAddedList_Map =' + studentId_StudentTagAddedList_Map);
        system.Debug('STH:'+Trigger.operationType+'studentId_StudentTagRemovedList_Map =' + studentId_StudentTagRemovedList_Map);
        system.Debug('STH:'+Trigger.operationType+'studentId_ServiceIdEPCUIMap_Map =' + studentId_ServiceIdEPCUIMap_Map);

        List<EPC_Utilization_Item__c> epcuiToUpsert = new List<EPC_Utilization_Item__c>();
        if (Trigger.isAfter) {
            for (Id studentId:studentId_StudentTagAddedList_Map.keySet()) {
                for (Student_Tag__c studentTag:studentId_StudentTagAddedList_Map.get(studentId)) {
                    if (tagIdServiceIdListMap.get(studentTag.tag__c)!=null) {
                        for (Id serviceId:tagIdServiceIdListMap.get(studentTag.tag__c)) {
                            Date utilizationStartDate = null;
                            if (serviceIdServiceMap.get(serviceId).Utilization_Date_Formula__c == 'Program Start Date -14d') {
                                utilizationStartDate = studentIdStudentMap.get(studentId).program__r.course_start_date__c;
                                if(utilizationStartDate != null) {
                                    utilizationStartDate = utilizationStartDate.addDays(-14);
                                }
                            } else if (serviceIdServiceMap.get(serviceId).Utilization_Date_Formula__c == 'Previous Program Start Date -14d') {
                                utilizationStartDate = studentIdStudentMap.get(studentId).previous_program__r.course_start_date__c;
                                if(utilizationStartDate != null) {
                                    utilizationStartDate = utilizationStartDate.addDays(-14);
                                }
                            } else if (serviceIdServiceMap.get(serviceId).Utilization_Date_Formula__c == 'Tag Create Date') {
                                utilizationStartDate =studentTag.createdDate.Date();
                            }                        
                            EPC_Utilization_Item__c existingEPCUI = studentId_ServiceIdEPCUIMap_Map.get(studentId).remove(serviceId);
                            if (existingEPCUI==null) {
                                epcuiToUpsert.add(new EPC_Utilization_Item__c(
                                    Student__c=studentId, 
                                    Service__c=serviceId, 
                                    Status__c='Active', 
                                    Student_Tag__c=studentTag.Id,
                                    Category__c=tagIdTagNameMap.get(studentTag.Tag__c),
                                    EPC_Utilization_Date__c= utilizationStartDate,
                                    Contact__c=studentIdContactIdMap.get(studentId))
                                );
                            } else {
                                epcuiToUpsert.add(new EPC_Utilization_Item__c(
                                    Id=existingEPCUI.Id, 
                                    Status__c='Active', 
                                    Student_Tag__c=studentTag.Id, 
                                    Category__c=tagIdTagNameMap.get(studentTag.Tag__c),
                                    EPC_Utilization_Date__c= utilizationStartDate,
                                    Contact__c=studentIdContactIdMap.get(studentId))
                                );
                            }
                        }
                    }
                }
            }

            for (Id studentId:studentId_StudentTagRemovedList_Map.keySet()) {
                for (Student_Tag__c studentTag:studentId_StudentTagRemovedList_Map.get(studentId)) {
                    if ((tagIdServiceIdListMap.get(studentTag.Tag__c))!=null) { //as long as there aren't zero services related to this tag...
                        for (Id serviceId:tagIdServiceIdListMap.get(studentTag.Tag__c)) {
                            EPC_Utilization_Item__c existingEPCUI = studentId_ServiceIdEPCUIMap_Map.get(studentId).remove(serviceId);
                            if (existingEPCUI==null) {
                                System.Debug('Shenanigans! Student_Tag__c record removed but no corresponding EPCUI was found so that we could set EPCUI.Status__c=Void');
                            } else {
                                // existingEPCUI.Status__c='Void';
                                epcuiToUpsert.add(new EPC_Utilization_Item__c(Id=existingEPCUI.Id, Status__c='Void', category__c=tagIdTagNameMap.get(studentTag.Tag__c)));
                            }
                        }
                    }
                }
            }

            system.Debug('STH:'+Trigger.operationType+'epcuiToUpsert =' + epcuiToUpsert);
            if (!epcuiToUpsert.isEmpty()) {
                upsert epcuiToUpsert;
            }
        }
    }
}