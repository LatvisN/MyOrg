public with sharing class PurchaseController {

    public class CartItem {
        @AuraEnabled public Id itemId { get; set; }
        @AuraEnabled public String itemName { get; set; }
        @AuraEnabled public Integer amount { get; set; }
        @AuraEnabled public Decimal unitCost { get; set; }
    }

    @AuraEnabled
    public static Id createPurchase(Id accountId, List<CartItem> cartItems) {
        if (accountId == null) {
            throw new AuraHandledException('Account ID is required');
        }
        if (cartItems == null || cartItems.isEmpty()) {
            throw new AuraHandledException('Cart is empty');
        }

        Savepoint sp = Database.setSavepoint();

        try {
            Purchase__c purchase = new Purchase__c(
                    Name__c = 'PUR-' + DateTime.now().format('yyyyMMdd-HHmmss'),
                    ClientId__c = accountId,
                    TotalItems__c = 0,
                    GrandTotal__c = 0
            );
            insert purchase;

            List<PurchaseLine__c> purchaseLines = new List<PurchaseLine__c>();
            for (CartItem item : cartItems) {
                PurchaseLine__c line = new PurchaseLine__c(
                        PurchaseId__c = purchase.Id,
                        ItemId__c = item.itemId,
                        Amount__c = item.amount,
                        UnitCost__c = item.unitCost
                );
                purchaseLines.add(line);
            }
            insert purchaseLines;

            return purchase.Id;

        } catch (Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException('Error creating purchase: ' + e.getMessage());
        }
    }
}