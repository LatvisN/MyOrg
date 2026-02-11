@isTest
private class AccountControllerTest {

    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(
                Name = 'Test Account',
                AccountNumber = 'ACC-001',
                Industry = 'Technology'
        );
        insert testAccount;
    }

    @isTest
    static void testGetAccountDetails_Success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Account result = AccountController.getAccountDetails(acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Account should be returned');
        System.assertEquals('Test Account', result.Name, 'Name should match');
        System.assertEquals('ACC-001', result.AccountNumber, 'Account Number should match');
        System.assertEquals('Technology', result.Industry, 'Industry should match');
    }

    @isTest
    static void testGetAccountDetails_NullId() {
        Boolean exceptionThrown = false;

        try {
            Test.startTest();
            AccountController.getAccountDetails(null);
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown, 'Should throw exception for null Id');
    }

    @isTest
    static void testGetAccountDetails_InvalidId() {
        Id fakeId = '001000000000000AAA';
        Boolean exceptionThrown = false;

        try {
            Test.startTest();
            AccountController.getAccountDetails(fakeId);
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown, 'Should throw exception for invalid Id');
    }
}