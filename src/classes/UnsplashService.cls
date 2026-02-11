public with sharing class UnsplashService {

    private static final String UNSPLASH_ACCESS_KEY = 'p0sUYw_exU393Z6uveM6SaSfM52zPvOEzhqMMml265Y';
    private static final String UNSPLASH_API_URL = 'https://api.unsplash.com/search/photos';

    @AuraEnabled
    public static String getImageUrl(String searchQuery) {
        if (String.isBlank(searchQuery)) {
            return null;
        }

        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();

            String endpoint = UNSPLASH_API_URL +
                    '?query=' + EncodingUtil.urlEncode(searchQuery, 'UTF-8') +
                    '&per_page=1&orientation=landscape';

            request.setEndpoint(endpoint);
            request.setMethod('GET');
            request.setHeader('Authorization', 'Client-ID ' + UNSPLASH_ACCESS_KEY);
            request.setTimeout(10000);

            HttpResponse response = http.send(request);

            System.debug('Unsplash Response Code: ' + response.getStatusCode());
            System.debug('Unsplash Response Body: ' + response.getBody());

            if (response.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                List<Object> results = (List<Object>)result.get('results');

                if (results != null && !results.isEmpty()) {
                    Map<String, Object> firstResult = (Map<String, Object>)results[0];
                    Map<String, Object> urls = (Map<String, Object>)firstResult.get('urls');
                    String imageUrl = (String)urls.get('regular');
                    System.debug('Found image URL: ' + imageUrl);
                    return imageUrl;
                }
            }

            return null;

        } catch (Exception e) {
            System.debug('Error calling Unsplash: ' + e.getMessage());
            throw new AuraHandledException('Error getting image: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Integer updateExistingItemImages() {
        List<Item__c> itemsToUpdate = [
                SELECT Id, Name__c, Image__c
                FROM Item__c
                WHERE Image__c = NULL OR Image__c = ''
                LIMIT 10
        ];

        Integer updatedCount = 0;

        for (Item__c item : itemsToUpdate) {
            try {
                String imageUrl = getImageUrl(item.Name__c);
                if (String.isNotBlank(imageUrl)) {
                    item.Image__c = imageUrl;
                    updatedCount++;
                }
            } catch (Exception e) {
                System.debug('Error updating item ' + item.Id + ': ' + e.getMessage());
            }
        }

        if (updatedCount > 0) {
            update itemsToUpdate;
        }

        return updatedCount;
    }
}