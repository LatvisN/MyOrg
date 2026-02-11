public with sharing class ItemController {

    @AuraEnabled(cacheable=true)
    public static List<Item__c> getItems(String familyFilter, String typeFilter, String searchTerm) {
        try {
            String query = 'SELECT Id, Name, Description__c, Type__c, Family__c, Image__c, Price__c';

            if (Schema.sObjectType.Item__c.fields.Name__c.isAccessible()) {
                query += ', Name__c';
            }

            query += ' FROM Item__c';

            List<String> conditions = new List<String>();

            if (String.isNotBlank(familyFilter) && familyFilter != 'All') {
                conditions.add('Family__c = :familyFilter');
            }
            if (String.isNotBlank(typeFilter) && typeFilter != 'All') {
                conditions.add('Type__c = :typeFilter');
            }

            if (String.isNotBlank(searchTerm)) {
                String searchKey = '%' + searchTerm + '%';

                if (Schema.sObjectType.Item__c.fields.Name__c.isAccessible()) {
                    conditions.add('(Name__c LIKE :searchKey OR Description__c LIKE :searchKey)');
                } else {
                    conditions.add('Description__c LIKE :searchKey');
                }
            }

            if (!conditions.isEmpty()) {
                query += ' WHERE ' + String.join(conditions, ' AND ');
            }

            query += ' ORDER BY Name LIMIT 200';

            System.debug('Final query: ' + query);
            return Database.query(query);

        } catch (Exception e) {
            System.debug('Error in getItems: ' + e.getMessage());
            throw new AuraHandledException('Error loading items: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getPicklistValues() {
        Map<String, List<String>> picklistMap = new Map<String, List<String>>();

        List<String> familyValues = new List<String>{'All'};
        Schema.DescribeFieldResult familyField = Item__c.Family__c.getDescribe();
        for (Schema.PicklistEntry entry : familyField.getPicklistValues()) {
            if (entry.isActive()) {
                familyValues.add(entry.getValue());
            }
        }
        picklistMap.put('Family', familyValues);

        List<String> typeValues = new List<String>{'All'};
        Schema.DescribeFieldResult typeField = Item__c.Type__c.getDescribe();
        for (Schema.PicklistEntry entry : typeField.getPicklistValues()) {
            if (entry.isActive()) {
                typeValues.add(entry.getValue());
            }
        }
        picklistMap.put('Type', typeValues);

        return picklistMap;
    }

    @AuraEnabled
    public static Item__c createItem(String name, String description, String itemType,
            String family, Decimal price) {
        System.debug('=== createItem START ===');
        System.debug('Creating item with name: ' + name);

        Item__c newItem = new Item__c(
                Name__c = name,
                Description__c = description,
                Type__c = itemType,
                Family__c = family,
                Price__c = price
        );

        try {
            System.debug('Calling Unsplash API for item: ' + name);
            String imageUrl = UnsplashService.getImageUrl(name);

            System.debug('Received image URL: ' + imageUrl);

            if (String.isNotBlank(imageUrl)) {
                newItem.Image__c = imageUrl;
                System.debug('Image set to item');
            } else {
                System.debug('No image URL returned from Unsplash');
            }
        } catch (Exception e) {
            System.debug('Error getting image: ' + e.getMessage());
        }

        System.debug('Inserting item...');
        insert newItem;
        System.debug('Item created with Id: ' + newItem.Id);

        return newItem;
    }
}