public with sharing class ItemController {

    @AuraEnabled(cacheable=true)
    public static List<Item__c> getItems(String familyFilter, String typeFilter, String searchTerm) {
        String query = 'SELECT Id, Name, Name__c, Description__c, Type__c, Family__c, Image__c, Price__c FROM Item__c WHERE Id != null';

        List<String> conditions = new List<String>();

        if (String.isNotBlank(familyFilter) && familyFilter != 'All') {
            conditions.add('Family__c = :familyFilter');
        }
        if (String.isNotBlank(typeFilter) && typeFilter != 'All') {
            conditions.add('Type__c = :typeFilter');
        }
        if (String.isNotBlank(searchTerm)) {
            String searchKey = '%' + String.escapeSingleQuotes(searchTerm) + '%';
            conditions.add('(Name LIKE :searchKey OR Description__c LIKE :searchKey)');
        }

        if (!conditions.isEmpty()) {
            query += ' AND ' + String.join(conditions, ' AND ');
        }

        query += ' ORDER BY Name LIMIT 200';

        return Database.query(query);
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<String>> getPicklistValues() {
        Map<String, List<String>> picklistMap = new Map<String, List<String>>();

        List<String> familyValues = new List<String>();
        familyValues.add('All');
        Schema.DescribeFieldResult familyField = Item__c.Family__c.getDescribe();
        for (Schema.PicklistEntry entry : familyField.getPicklistValues()) {
            if (entry.isActive()) {
                familyValues.add(entry.getValue());
            }
        }
        picklistMap.put('Family', familyValues);

        List<String> typeValues = new List<String>();
        typeValues.add('All');
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
        Item__c newItem = new Item__c(
                Name__c = name,
                Description__c = description,
                Type__c = itemType,
                Family__c = family,
                Price__c = price
        );

        String imageUrl = UnsplashService.getImageUrl(name);
        if (String.isNotBlank(imageUrl)) {
            newItem.Image__c = imageUrl;
        }

        insert newItem;
        return newItem;
    }
}