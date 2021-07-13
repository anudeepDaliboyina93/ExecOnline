@isTest
private class readOnlyControllerTest {

   static testMethod void testManualShareRead(){
     
      List<User> users = [SELECT Id FROM User WHERE IsActive = true LIMIT 2];
      Id User1Id = users[0].Id;
      Id User2Id = users[1].Id;
      User user2 = users[1];
   
      
      Contact c = new Contact();
      c.FirstName = 'Test';
      c.LastName = 'Last';
      c.Email = 'test@test.com';
      c.OwnerId = user1Id;
      insert c;    
                
      System.runAs(user2) {
      readOnlyController.setReadAccess(c.Id);
      }
  
   }
   
   static testMethod void findContact(){

    List<User> users = [SELECT Id FROM User WHERE IsActive = true LIMIT 2];
    Id User1Id = users[0].Id;
    Id User2Id = users[1].Id;
    User user2 = users[1];

    Contact c = new Contact();
    c.FirstName = 'Test';
    c.LastName = 'Last';
    c.Email = 'test@test.com';
    c.OwnerId = user1Id;
    insert c;

    List<String> selectedIds = new List<String>();

    readOnlyController.findContacts('Test', selectedIds);

   }
}