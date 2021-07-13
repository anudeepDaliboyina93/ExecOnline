({
	init: function (component, event, helper) {
        helper.doInit(component);
    },
    oppRecordLoaded : function(component, event, helper) {
        let oppRecord = component.get('v.oppRecord');
        if(oppRecord) {
            component.set('v.accountId', oppRecord.Account.Id);
            helper.getUseCaseOppRecords(component);
        }
    },
    onMenuSelect: function (component, event, helper) {
        helper.handleButtonMenu(component,event);
    },
    createNewUseCase: function (component, event, helper) {

        component.set("v.showSpinner", true);
        $A.createComponent(
            "c:OpportunityNewUseCaseComponent", {
                fields: component.get("v.useCaseNewEditFieldsList"),
                opportunityId : component.get("v.oppId"),
                accountId : component.get("v.accountId")
            },
            function (msgBox) {
                if (component.isValid()) {
                    var targetCmp = component.find('NewUseCaseModel');
                    var body = targetCmp.get("v.body");
                    body.push(msgBox);
                    targetCmp.set("v.body", body);
                }
                component.set("v.showSpinner", false);
            }
        );
    },
    addExisting: function (component, event, helper) {
        component.set("v.showSpinner", true);
        $A.createComponent(
            "c:OpportunityAddExistingUseCaseComponent", {
                records: component.get("v.useCaseList"),
                opportunityId : component.get("v.oppId"),
                columnsToShow : component.get("v.useCaseListBuilderFieldsList")
            },
            function (msgBox) {
                if (component.isValid()) {
                    var targetCmp = component.find('AddExistingUseCaseModel');
                    var body = targetCmp.get("v.body");
                    body.push(msgBox);
                    targetCmp.set("v.body", body);
                }
                component.set("v.showSpinner", false);
            }
        );
    },
    handleEvent: function (component, event, helper) {
        var self = this;
        component.set("v.showSpinner", true);        
        var payload = event.getParam("payload");
        var type = event.getParam("type");

        if(!$A.util.isEmpty(type) && type === "RemoveUseCase" && !$A.util.isEmpty(payload)){
            helper.removeUseCase(component, payload);
        } else if(!$A.util.isEmpty(type) && type === "RefreshComponent"){
            helper.doInit(component);
        }
    },
})