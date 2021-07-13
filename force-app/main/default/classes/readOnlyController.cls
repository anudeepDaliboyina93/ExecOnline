public without sharing class readOnlyController {
    
    private final static Integer MAX_RESULTS = 5;
    @AuraEnabled(cacheable=true)
    public static List<LookupSearchResult> findContacts(String searchTerm, List<String> selectedIds){

               // Prepare query paramters
        searchTerm += '*';

        // Execute search query
        List<List<SObject>> searchResults = [
            FIND :searchTerm
            IN ALL FIELDS
            RETURNING
                Contact(Id, Name, Account.Name WHERE id NOT IN :selectedIds)
                
            LIMIT :MAX_RESULTS
        ];

        // Prepare results
        List<LookupSearchResult> results = new List<LookupSearchResult>();

        // Extract Contacts & convert them into LookupSearchResult
        String contactIcon = 'standard:contact';

        if (!searchResults.isEmpty()){

            Contact[] contacts = (List<Contact>) searchResults[0];
            for (Contact contact : contacts) {
                String subtitle = contact?.Account.Name == null ? 'Contact' : 'Contact • ' + contact?.Account.Name;
                results.add(new LookupSearchResult(contact.Id, 'Contact', contactIcon, contact.Name, subtitle));
            }
        }
      

        // Optionnaly sort all results on title
        results.sort();

        return results;
      
    }

    @AuraEnabled
    public static Boolean setReadAccess(Id contactId){

        Id userId = UserInfo.getUserId();

        system.debug(contactId);

// Create new sharing object for the custom object Job.
ContactShare conShare  = new ContactShare();
   
// Set the ID of record being shared.
conShare.ContactId = contactId;
  
// Set the ID of user or group being granted access.
conShare.UserOrGroupId = userId;
  
// Set the access level.
conShare.ContactAccessLevel = 'Read';
  
// Set rowCause to 'manual' for manual sharing.
// This line can be omitted as 'manual' is the default value for sharing objects.
conShare.RowCause = Schema.ContactShare.RowCause.Manual;
  
// Insert the sharing record and capture the save result. 
// The false parameter allows for partial processing if multiple records passed 
// into the operation.
Database.SaveResult sr = Database.insert(conShare,false);

// Process the save results.
if(sr.isSuccess()){
   // Indicates success
   return true;
}
else {
   // Get first save result error.
   Database.Error err = sr.getErrors()[0];
   
   // Check if the error is related to trival access level.
   // Access level must be more permissive than the object's default.
   // These sharing records are not required and thus an insert exception is acceptable. 
   if(err.getStatusCode() == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION  &&  
            err.getMessage().contains('AccessLevel')){
      // Indicates success.
      return true;
   }
   else{
      // Indicates failure.
      return false;
   }
 }

        
    }

}