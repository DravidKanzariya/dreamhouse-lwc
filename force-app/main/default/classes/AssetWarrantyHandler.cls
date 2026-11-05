public with sharing class AssetWarrantyHandler {
    public static void handleBefore(List<Asset> newAssets, Map<Id, Asset> oldMap) {
        Set<Id> productIds = new Set<Id>();

        for (Asset asset : newAssets) {
            if (asset.Product2Id == null) {
                continue;
            }
            if (oldMap == null || hasRelevantChange(asset, oldMap.get(asset.Id))) {
                productIds.add(asset.Product2Id);
            }
        }

        if (productIds.isEmpty()) {
            return;
        }

        Map<Id, Product2> productMap = new Map<Id, Product2>(
            [SELECT Id, Warranty_Term_Years__c FROM Product2 WHERE Id IN :productIds]
        );

        Date today = Date.today();

        for (Asset asset : newAssets) {
            if (asset.Product2Id == null) {
                continue;
            }
            if (oldMap != null && !hasRelevantChange(asset, oldMap.get(asset.Id))) {
                continue;
            }

            Product2 product = productMap.get(asset.Product2Id);

            if (asset.PurchaseDate != null && asset.PurchaseDate > today) {
                asset.PurchaseDate.addError('The purchase date can\'t be in the future.');
                continue;
            }

            if (product == null || product.Warranty_Term_Years__c == null) {
                asset.addError('This model can\'t be registered online yet — please contact support.');
                continue;
            }

            if (asset.PurchaseDate == null) {
                continue;
            }

            asset.Warranty_End_Date__c = asset.PurchaseDate.addYears(product.Warranty_Term_Years__c.intValue());
        }
    }

    private static Boolean hasRelevantChange(Asset newAsset, Asset oldAsset) {
        if (oldAsset == null) {
            return true;
        }
        return newAsset.PurchaseDate != oldAsset.PurchaseDate || newAsset.Product2Id != oldAsset.Product2Id;
    }
}