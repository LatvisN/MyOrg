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
                    '&per_page=1&orientation=squarish';

            request.setEndpoint(endpoint);
            request.setMethod('GET');
            request.setHeader('Authorization', 'Client-ID ' + UNSPLASH_ACCESS_KEY);
            request.setTimeout(10000);

            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                List<Object> results = (List<Object>)result.get('results');

                if (results != null && !results.isEmpty()) {
                    Map<String, Object> firstResult = (Map<String, Object>)results[0];
                    Map<String, Object> urls = (Map<String, Object>)firstResult.get('urls');
                    return (String)urls.get('regular');
                }
            }

            return null;

        } catch (Exception e) {
            System.debug('Unsplash API Error: ' + e.getMessage());
            return null;
        }
    }
}