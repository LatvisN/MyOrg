@isTest
private class UnsplashServiceTest {

    @isTest
    static void testGetImageUrl_Success() {
        Test.setMock(HttpCalloutMock.class, new UnsplashMockSuccess());

        Test.startTest();
        String imageUrl = UnsplashService.getImageUrl('laptop');
        Test.stopTest();

        System.assertNotEquals(null, imageUrl, 'Should return image URL');
        System.assert(imageUrl.contains('unsplash'), 'URL should contain unsplash domain');
    }

    @isTest
    static void testGetImageUrl_EmptyQuery() {
        Test.startTest();
        String imageUrl = UnsplashService.getImageUrl('');
        Test.stopTest();

        System.assertEquals(null, imageUrl, 'Should return null for empty query');
    }

    @isTest
    static void testGetImageUrl_NoResults() {
        Test.setMock(HttpCalloutMock.class, new UnsplashMockNoResults());

        Test.startTest();
        String imageUrl = UnsplashService.getImageUrl('xyznonexistent');
        Test.stopTest();

        System.assertEquals(null, imageUrl, 'Should return null when no results');
    }

    @isTest
    static void testUpdateExistingItemImages() {
        List<Item__c> items = new List<Item__c>();
        for (Integer i = 0; i < 5; i++) {
            items.add(new Item__c(
                    Name__c = 'Test Item ' + i,
                    Price__c = 100
            ));
        }
        insert items;

        Test.setMock(HttpCalloutMock.class, new UnsplashMockSuccess());

        Test.startTest();
        Integer updated = UnsplashService.updateExistingItemImages();
        Test.stopTest();

        System.assertEquals(5, updated, 'Should update 5 items');

        List<Item__c> updatedItems = [SELECT Image__c FROM Item__c WHERE Image__c != null];
        System.assertEquals(5, updatedItems.size(), 'All items should have images');
    }

    private class UnsplashMockSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"results":[{"urls":{"regular":"https://images.unsplash.com/test.jpg"}}]}');
            return res;
        }
    }

    private class UnsplashMockNoResults implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"results":[]}');
            return res;
        }
    }
}