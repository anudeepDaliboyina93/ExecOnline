@isTest
public class TeamHandlerTest {

	public static testMethod void testTeamHandler() {
        Program__c program = new Program__c(friendly_name__c='test', short_name__c='test');
        insert program;

		Team__c team = new Team__c(Program__c= program.Id, Team_Name__c='test');
        insert team;

        team.Team_Name__c = 'test2';
        update team;

        delete team;

        undelete team;
	}
}