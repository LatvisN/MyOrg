@isTest
private class UserControllerTest {

    @isTest
    static void testIsCurrentUserManager_True() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        currentUser.IsManager__c = true;
        update currentUser;

        Test.startTest();
        Boolean result = UserController.isCurrentUserManager();
        Test.stopTest();

        System.assertEquals(true, result, 'Should return true for manager');
    }

    @isTest
    static void testIsCurrentUserManager_False() {
        User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        currentUser.IsManager__c = false;
        update currentUser;

        Test.startTest();
        Boolean result = UserController.isCurrentUserManager();
        Test.stopTest();

        System.assertEquals(false, result, 'Should return false for non-manager');
    }
}