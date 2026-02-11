@isTest
private class PurchaseLineTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Purchase__c purchase = new Purchase__c(
                Name__c = 'Test Purchase',
                ClientId__c = acc.Id
        );
        insert purchase;

        List<Item__c> items = new List<Item__c>();
        items.add(new Item__c(Name__c = 'Item 1', Price__c = 100));
        items.add(new Item__c(Name__c = 'Item 2', Price__c = 200));
        insert items;
    }

    @isTest
    static void testTrigger_Insert() {
        Purchase__c purchase = [SELECT Id FROM Purchase__c LIMIT 1];
        List<Item__c> items = [SELECT Id, Price__c FROM Item__c];

        Test.startTest();
        List<PurchaseLine__c> lines = new List<PurchaseLine__c>();
        lines.add(new PurchaseLine__c(
                PurchaseId__c = purchase.Id,
                ItemId__c = items[0].Id,
                Amount__c = 2,
                UnitCost__c = 100
        ));
        lines.add(new PurchaseLine__c(
                PurchaseId__c = purchase.Id,
                ItemId__c = items[1].Id,
                Amount__c = 1,
                UnitCost__c = 200
        ));
        insert lines;
        Test.stopTest();

        Purchase__c updatedPurchase = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchase.Id];
        System.assertEquals(3, updatedPurchase.TotalItems__c, 'Total items should be 3');
        System.assertEquals(400, updatedPurchase.GrandTotal__c, 'Grand total should be 400');
    }

    @isTest
    static void testTrigger_Update() {
        Purchase__c purchase = [SELECT Id FROM Purchase__c LIMIT 1];
        Item__c item = [SELECT Id FROM Item__c LIMIT 1];

        PurchaseLine__c line = new PurchaseLine__c(
                PurchaseId__c = purchase.Id,
                ItemId__c = item.Id,
                Amount__c = 1,
                UnitCost__c = 100
        );
        insert line;

        Test.startTest();
        line.Amount__c = 5;
        update line;
        Test.stopTest();

        Purchase__c updatedPurchase = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchase.Id];
        System.assertEquals(5, updatedPurchase.TotalItems__c, 'Total items should be 5');
        System.assertEquals(500, updatedPurchase.GrandTotal__c, 'Grand total should be 500');
    }

    @isTest
    static void testTrigger_Delete() {
        Purchase__c purchase = [SELECT Id FROM Purchase__c LIMIT 1];
        Item__c item = [SELECT Id FROM Item__c LIMIT 1];

        PurchaseLine__c line = new PurchaseLine__c(
                PurchaseId__c = purchase.Id,
                ItemId__c = item.Id,
                Amount__c = 3,
                UnitCost__c = 100
        );
        insert line;

        Test.startTest();
        delete line;
        Test.stopTest();

        Purchase__c updatedPurchase = [SELECT TotalItems__c, GrandTotal__c FROM Purchase__c WHERE Id = :purchase.Id];
        System.assertEquals(0, updatedPurchase.TotalItems__c, 'Total items should be 0');
        System.assertEquals(0, updatedPurchase.GrandTotal__c, 'Grand total should be 0');
    }
}