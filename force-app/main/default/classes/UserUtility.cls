public class UserUtility {

    static Map<Id, Profile> profileMap;
    static Map<Id, Set<String>> userIdToAssignedPermissionSetsMap = new Map<Id, Set<String>>();
    public static String PROFILE_SYSTEM_ADMINISTRATOR() { return 'System Administrator'; }

    static void getProfileMap() {
        if(profileMap == null) {
            profileMap = new Map<Id, Profile>([SELECT Id, Name FROM Profile]);
        }
    }
    
    public static String getProfileNameFromId(Id profileId) {
        getProfileMap();
        return profileMap.get(profileId).Name;
    }

    public static Boolean isSysAdmin() {
        getProfileMap();
        return getProfileNameFromId(UserInfo.getProfileId()) == PROFILE_SYSTEM_ADMINISTRATOR();
    }

    public static Boolean isEpcAdmin() {
        return hasPermissionSetName('EPC_Admin');
    }

    public static Boolean hasPermissionSetName(String psName) {
        return userHasPermissionSetName(UserInfo.getUserId(), psName);
    }

    public static Boolean userHasPermissionSetName(Id userId, String psName) {
        getAssignedPermissionSetsForUsers(new Set<Id>{ userId });
        return userIdToAssignedPermissionSetsMap.get(userId).contains(psName);
    }

    public static void getAssignedPermissionSetsForUsers(Set<Id> userIds) {
        Set<Id> usersToGetAssignedPermissionSets = new Set<Id>();
        for(Id userId : userIds) {
            if(userIdToAssignedPermissionSetsMap.get(userId) == null) {
                usersToGetAssignedPermissionSets.add(userId);
                userIdToAssignedPermissionSetsMap.put(userId, new Set<String>());
            }
        }
        if(usersToGetAssignedPermissionSets != null) {
            List<PermissionSetAssignment> psas = [SELECT AssigneeId, PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId IN :usersToGetAssignedPermissionSets];
            for(PermissionSetAssignment psa : psas) {
                userIdToAssignedPermissionSetsMap.get(psa.AssigneeId).add(psa.PermissionSet.Name);
            }
        }
    }

    public static Boolean isUsingLightningExperience() {
        return UserInfo.getUiThemeDisplayed() == 'Theme4d';
    }

}