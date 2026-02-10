public with sharing class PurchaseLineTriggerHandler {

    public static void handleAfterChange(
            List<PurchaseLine__c> newLines,
            List<PurchaseLine__c> oldLines,
            System.TriggerOperation operationType
    ) {
        Set<Id> purchaseIds = new Set<Id>();

        if (newLines != null) {
            for (PurchaseLine__c line : newLines) {
                if (line.PurchaseId__c != null) {
                    purchaseIds.add(line.PurchaseId__c);
                }
            }
        }

        if (oldLines != null) {
            for (PurchaseLine__c line : oldLines) {
                if (line.PurchaseId__c != null) {
                    purchaseIds.add(line.PurchaseId__c);
                }
            }
        }

        if (!purchaseIds.isEmpty()) {
            updatePurchaseTotals(purchaseIds);
        }
    }

    private static void updatePurchaseTotals(Set<Id> purchaseIds) {
        List<PurchaseLine__c> allLines = [
                SELECT PurchaseId__c, Amount__c, UnitCost__c
                FROM PurchaseLine__c
                WHERE PurchaseId__c IN :purchaseIds
        ];

        Map<Id, Decimal> totalItemsMap = new Map<Id, Decimal>();
        Map<Id, Decimal> grandTotalMap = new Map<Id, Decimal>();

        for (PurchaseLine__c line : allLines) {
            if (!totalItemsMap.containsKey(line.PurchaseId__c)) {
                totalItemsMap.put(line.PurchaseId__c, 0);
                grandTotalMap.put(line.PurchaseId__c, 0);
            }

            Decimal currentTotalItems = totalItemsMap.get(line.PurchaseId__c);
            Decimal amount = line.Amount__c != null ? line.Amount__c : 0;
            totalItemsMap.put(line.PurchaseId__c, currentTotalItems + amount);

            Decimal currentGrandTotal = grandTotalMap.get(line.PurchaseId__c);
            Decimal unitCost = line.UnitCost__c != null ? line.UnitCost__c : 0;
            Decimal lineTotal = amount * unitCost;
            grandTotalMap.put(line.PurchaseId__c, currentGrandTotal + lineTotal);
        }

        List<Purchase__c> purchasesToUpdate = new List<Purchase__c>();

        for (Id purchaseId : purchaseIds) {
            Purchase__c purchase = new Purchase__c(Id = purchaseId);

            if (totalItemsMap.containsKey(purchaseId)) {
                purchase.TotalItems__c = totalItemsMap.get(purchaseId);
                purchase.GrandTotal__c = grandTotalMap.get(purchaseId);
            } else {
                purchase.TotalItems__c = 0;
                purchase.GrandTotal__c = 0;
            }

            purchasesToUpdate.add(purchase);
        }

        if (!purchasesToUpdate.isEmpty()) {
            update purchasesToUpdate;
        }
    }
}