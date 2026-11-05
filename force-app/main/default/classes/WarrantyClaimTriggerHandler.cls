public with sharing class WarrantyClaimTriggerHandler {
    public static final String STATUS_IN_WARRANTY = 'In Warranty';
    public static final String STATUS_OUT_OF_WARRANTY = 'Out of Warranty';
    public static final String STATUS_NEEDS_REVIEW = 'Needs Review';

    private static final String NOTE_OUT_OF_WARRANTY = 'Fault occurred after warranty end date. Offer paid repair.';
    private static final String NOTE_NO_WARRANTY_END = 'Product has no warranty end date; manual review required.';
    private static final String NOTE_FUTURE_FAULT = 'Fault date cannot be in the future.';
    private static final String NOTE_BEFORE_PURCHASE = 'Fault date cannot be before the purchase date.';

    public static void handleBeforeInsert(List<Case> newCases) {
        determineWarrantyStatus(newCases);
    }

    public static void handleBeforeUpdate(List<Case> newCases, Map<Id, Case> oldMap) {
        List<Case> casesToProcess = new List<Case>();
        for (Case c : newCases) {
            Case oldCase = oldMap.get(c.Id);
            if (c.AssetId != oldCase.AssetId || c.Fault_Date__c != oldCase.Fault_Date__c) {
                casesToProcess.add(c);
            }
        }
        if (!casesToProcess.isEmpty()) {
            determineWarrantyStatus(casesToProcess);
        }
    }

    private static void determineWarrantyStatus(List<Case> cases) {
        Set<Id> assetIds = new Set<Id>();
        for (Case c : cases) {
            if (c.AssetId != null) {
                assetIds.add(c.AssetId);
            }
        }

        Map<Id, Asset> assetMap = new Map<Id, Asset>();
        if (!assetIds.isEmpty()) {
            assetMap = new Map<Id, Asset>([
                SELECT Id, PurchaseDate, Warranty_End_Date__c
                FROM Asset
                WHERE Id IN :assetIds
            ]);
        }

        Date today = Date.today();
        for (Case c : cases) {
            if (c.AssetId == null || c.Fault_Date__c == null) {
                c.Warranty_Status__c = STATUS_NEEDS_REVIEW;
                c.Warranty_Note__c = '';
                continue;
            }

            Asset asset = assetMap.get(c.AssetId);
            if (asset == null) {
                c.Warranty_Status__c = STATUS_NEEDS_REVIEW;
                c.Warranty_Note__c = '';
                continue;
            }

            Date faultDate = c.Fault_Date__c;
            if (faultDate > today) {
                c.Warranty_Status__c = STATUS_NEEDS_REVIEW;
                c.Warranty_Note__c = NOTE_FUTURE_FAULT;
                continue;
            }

            if (asset.PurchaseDate != null && faultDate < asset.PurchaseDate) {
                c.Warranty_Status__c = STATUS_NEEDS_REVIEW;
                c.Warranty_Note__c = NOTE_BEFORE_PURCHASE;
                continue;
            }

            if (asset.Warranty_End_Date__c == null) {
                c.Warranty_Status__c = STATUS_NEEDS_REVIEW;
                c.Warranty_Note__c = NOTE_NO_WARRANTY_END;
                continue;
            }

            if (faultDate <= asset.Warranty_End_Date__c) {
                c.Warranty_Status__c = STATUS_IN_WARRANTY;
                c.Warranty_Note__c = '';
            } else {
                c.Warranty_Status__c = STATUS_OUT_OF_WARRANTY;
                c.Warranty_Note__c = NOTE_OUT_OF_WARRANTY;
            }
        }
    }
}