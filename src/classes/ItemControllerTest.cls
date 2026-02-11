@isTest
private class ItemControllerTest {

    @TestSetup
    static void setupTestData() {
        List<Item__c> testItems = new List<Item__c>();

        testItems.add(new Item__c(
                Name__c = 'Test Laptop',
                Description__c = 'Gaming laptop',
                Type__c = 'Type 1',
                Family__c = 'Family 1',
                Price__c = 1500.00,
                Image__c = 'https://example.com/laptop.jpg'
        ));

        testItems.add(new Item__c(
                Name__c = 'Test Mouse',
                Description__c = 'Wireless mouse',
                Type__c = 'Type 2',
                Family__c = 'Family 1',
                Price__c = 50.00,
                Image__c = 'https://example.com/mouse.jpg'
        ));

        testItems.add(new Item__c(
                Name__c = 'Test Keyboard',
                Description__c = 'Mechanical keyboard',
                Type__c = 'Type 1',
                Family__c = 'Family 2',
                Price__c = 150.00
        ));

        insert testItems;
    }

    @isTest
    static void testGetItems_All() {
        Test.startTest();
        List<Item__c> items = ItemController.getItems('All', 'All', '');
        Test.stopTest();

        System.assertEquals(3, items.size(), 'Should return all 3 items');
    }

    @isTest
    static void testGetItems_FilterByFamily() {
        Test.startTest();
        List<Item__c> items = ItemController.getItems('Family 1', 'All', '');
        Test.stopTest();

        System.assertEquals(2, items.size(), 'Should return 2 items from Family 1');
    }

    @isTest
    static void testGetItems_FilterByType() {
        Test.startTest();
        List<Item__c> items = ItemController.getItems('All', 'Type 1', '');
        Test.stopTest();

        System.assertEquals(2, items.size(), 'Should return 2 items of Type 1');
    }

    @isTest
    static void testGetItems_Search() {
        Test.startTest();
        List<Item__c> items = ItemController.getItems('All', 'All', 'laptop');
        Test.stopTest();

        System.assertEquals(1, items.size(), 'Should return 1 item matching "laptop"');
        System.assertEquals('Test Laptop', items[0].Name__c, 'Should return Test Laptop');
    }

    @isTest
    static void testGetItems_CombinedFilters() {
        Test.startTest();
        List<Item__c> items = ItemController.getItems('Family 1', 'Type 1', 'laptop');
        Test.stopTest();

        System.assertEquals(1, items.size(), 'Should return 1 item matching all filters');
    }

    @isTest
    static void testGetPicklistValues() {
        Test.startTest();
        Map<String, List<String>> picklists = ItemController.getPicklistValues();
        Test.stopTest();

        System.assertNotEquals(null, picklists, 'Picklist map should not be null');
        System.assert(picklists.containsKey('Family'), 'Should contain Family key');
        System.assert(picklists.containsKey('Type'), 'Should contain Type key');
        System.assert(picklists.get('Family').size() > 0, 'Family should have values');
        System.assert(picklists.get('Type').size() > 0, 'Type should have values');
    }

    @isTest
    static void testCreateItem_WithoutImage() {
        Test.startTest();
        Item__c newItem = ItemController.createItem(
                'Test Item',
                'Test Description',
                'Type 1',
                'Family 1',
                99.99
        );
        Test.stopTest();

        System.assertNotEquals(null, newItem.Id, 'Item should be created');
        System.assertEquals('Test Item', newItem.Name__c, 'Name should match');
        System.assertEquals(99.99, newItem.Price__c, 'Price should match');
    }
}