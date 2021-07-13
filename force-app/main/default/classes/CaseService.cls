/**
 * CaseService.cls
 * Copyright 2016 Wired Triangle, LLC
 * http://www.wiredtriangle.com
 */
public class CaseService
{
	public static Case applyAssignmentRule(Case c)
	{
		AssignmentRule AR = new AssignmentRule();
		AR = [select id from AssignmentRule where SobjectType = 'Case' and Active = true limit 1];

		Database.DMLOptions dmlOpts = new Database.DMLOptions();
		dmlOpts.assignmentRuleHeader.assignmentRuleId= AR.id;

		c.setOptions(dmlOpts);

		return c;
	}

	public static Id getDefaultEntitlement() {
		Id caseEntitlement;
		List<TriggerConfiguration__c> tcs = [select Case_Entitlement__c, CreatedById, CreatedDate, Enable_AccountTrigger__c, Enable_TouchContactBatch__c, Id, IsDeleted, LastModifiedById, LastModifiedDate, Name, SetupOwnerId, SystemModstamp from TriggerConfiguration__c where case_entitlement__c != null];
		if (tcs.size() > 0) {
			if (isValidEntitlement(tcs[0].Case_Entitlement__c)) {
				caseEntitlement = tcs[0].Case_Entitlement__c;
				return caseEntitlement;
			}
			else {
				return null;
			}
		}
		else {
			return null;
		}
	}

	private static Boolean isValidEntitlement(String idString) {
		if (ApexUtility.isValidId(idString)) {
			Id idStringAsId = (Id)idString;
			return (ApexUtility.getObjectNameFromId(idStringAsId) == 'Entitlement');
		}
		else {
			return false;
		}
	}
}