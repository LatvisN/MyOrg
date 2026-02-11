@isTest
private class PurchaseControllerTest {

    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(
                Name = 'Test Account',
                AccountNumber = 'ACC-001'
        );
        insert testAccount;

        List<Item__c> items = new List<Item__c>();
        items.add(new Item__c(
                Name__c = 'Item 1',
                Price__c = 100.00
        ));
        items.add(new Item__c(
                Name__c = 'Item 2',
                Price__c = 200.00
        ));
        insert items;
    }

    @isTest
    static void testCreatePurchase_Success() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Item__c> items = [SELECT Id, Name__c, Price__c FROM Item__c];

        List<PurchaseController.CartItem> cartItems = new List<PurchaseController.CartItem>();

        PurchaseController.CartItem item1 = new PurchaseController.CartItem();
        item1.itemId = items[0].Id;
        item1.itemName = items[0].Name__c;
        item1.amount = 2;
        item1.unitCost = items[0].Price__c;
        cartItems.add(item1);

        PurchaseController.CartItem item2 = new PurchaseController.CartItem();
        item2.itemId = items[1].Id;
        item2.itemName = items[1].Name__c;
        item2.amount = 1;
        item2.unitCost = items[1].Price__c;
        cartItems.add(item2);

        Test.startTest();
        Id purchaseId = PurchaseController.createPurchase(acc.Id, cartItems);
        Test.stopTest();

        System.assertNotEquals(null, purchaseId, 'Purchase should be created');

        Purchase__c purchase = [SELECT Id, TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchaseId];
        System.assertEquals(3, purchase.TotalItems__c, 'Total items should be 3 (2+1)');
        System.assertEquals(400.00, purchase.GrandTotal__c, 'Grand total should be 400 (2*100 + 1*200)');

        List<PurchaseLine__c> lines = [SELECT Id FROM PurchaseLine__c WHERE PurchaseId__c = :purchaseId];
        System.assertEquals(2, lines.size(), 'Should have 2 purchase lines');
    }

    @isTest
    static void testCreatePurchase_NullAccount() {
        List<PurchaseController.CartItem> cartItems = new List<PurchaseController.CartItem>();
        Boolean exceptionThrown = false;

        try {
            Test.startTest();
            PurchaseController.createPurchase(null, cartItems);
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown, 'Should throw exception for null account');
    }

    @isTest
    static void testCreatePurchase_EmptyCart() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Boolean exceptionThrown = false;

        try {
            Test.startTest();
            PurchaseController.createPurchase(acc.Id, new List<PurchaseController.CartItem>());
            Test.stopTest();
        } catch (Exception e) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown, 'Should throw exception for empty cart');
    }
}