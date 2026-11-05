@isTest
private class WarrantyClaimTriggerTest {
    private static final String ASSET_IN_WARRANTY = 'In Warranty Asset';
    private static final String ASSET_OUT_OF_WARRANTY = 'Out of Warranty Asset';
    private static final String ASSET_NO_WARRANTY_END = 'No Warranty End Asset';
    private static final String ASSET_FUTURE_PURCHASE = 'Future Purchase Asset';

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        List<Asset> assets = new List<Asset>{
            new Asset(
                Name = ASSET_IN_WARRANTY,
                AccountId = acc.Id,
                PurchaseDate = Date.today().addMonths(-12),
                Warranty_End_Date__c = Date.today().addMonths(12)
            ),
            new Asset(
                Name = ASSET_OUT_OF_WARRANTY,
                AccountId = acc.Id,
                PurchaseDate = Date.today().addMonths(-24),
                Warranty_End_Date__c = Date.today().addMonths(-12)
            ),
            new Asset(
                Name = ASSET_NO_WARRANTY_END,
                AccountId = acc.Id,
                PurchaseDate = Date.today().addMonths(-6)
            ),
            new Asset(
                Name = ASSET_FUTURE_PURCHASE,
                AccountId = acc.Id,
                PurchaseDate = Date.today().addMonths(-6),
                Warranty_End_Date__c = Date.today().addMonths(6)
            )
        };
        insert assets;
    }

    private static Asset getAsset(String name) {
        return [SELECT Id, PurchaseDate, Warranty_End_Date__c FROM Asset WHERE Name = :name LIMIT 1];
    }

    @isTest
    static void testInWarranty() {
        Asset asset = getAsset(ASSET_IN_WARRANTY);
        Case c = new Case(
            Status = 'New',
            Origin = 'Phone',
            AssetId = asset.Id,
            Fault_Date__c = Date.today()
        );

        Test.startTest();
        insert c;
        Test.stopTest();

        Case result = [SELECT Warranty_Status__c, Warranty_Note__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(WarrantyClaimTriggerHandler.STATUS_IN_WARRANTY, result.Warranty_Status__c, 'Case should be marked In Warranty');
        System.assert(String.isBlank(result.Warranty_Note__c), 'In-warranty case should have no note');
    }

    @isTest
    static void testOutOfWarranty() {
        Asset asset = getAsset(ASSET_OUT_OF_WARRANTY);
        Case c = new Case(
            Status = 'New',
            Origin = 'Phone',
            AssetId = asset.Id,
            Fault_Date__c = Date.today()
        );

        Test.startTest();
        insert c;
        Test.stopTest();

        Case result = [SELECT Warranty_Status__c, Warranty_Note__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(WarrantyClaimTriggerHandler.STATUS_OUT_OF_WARRANTY, result.Warranty_Status__c, 'Case should be marked Out of Warranty');
        System.assert(result.Warranty_Note__c.contains('paid repair'), 'Out-of-warranty note should mention paid repair');
    }

    @isTest
    static void testNeedsReviewNoWarrantyEndDate() {
        Asset asset = getAsset(ASSET_NO_WARRANTY_END);
        Case c = new Case(
            Status = 'New',
            Origin = 'Phone',
            AssetId = asset.Id,
            Fault_Date__c = Date.today()
        );

        Test.startTest();
        insert c;
        Test.stopTest();

        Case result = [SELECT Warranty_Status__c, Warranty_Note__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(WarrantyClaimTriggerHandler.STATUS_NEEDS_REVIEW, result.Warranty_Status__c, 'Case with no warranty end date should be Needs Review');
        System.assert(result.Warranty_Note__c.contains('no warranty end'), 'Needs-review note should mention missing warranty end date');
    }

    @isTest
    static void testFutureFaultDateNeedsReview() {
        Asset asset = getAsset(ASSET_FUTURE_PURCHASE);
        Case c = new Case(
            Status = 'New',
            Origin = 'Phone',
            AssetId = asset.Id,
            Fault_Date__c = Date.today().addDays(1)
        );

        Test.startTest();
        insert c;
        Test.stopTest();

        Case result = [SELECT Warranty_Status__c, Warranty_Note__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(WarrantyClaimTriggerHandler.STATUS_NEEDS_REVIEW, result.Warranty_Status__c, 'Future fault date should be Needs Review');
        System.assert(result.Warranty_Note__c.contains('future'), 'Note should mention future fault date');
    }

    @isTest
    static void testFaultDateBeforePurchaseNeedsReview() {
        Asset asset = getAsset(ASSET_IN_WARRANTY);
        Case c = new Case(
            Status = 'New',
            Origin = 'Phone',
            AssetId = asset.Id,
            Fault_Date__c = asset.PurchaseDate.addDays(-1)
        );

        Test.startTest();
        insert c;
        Test.stopTest();

        Case result = [SELECT Warranty_Status__c, Warranty_Note__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(WarrantyClaimTriggerHandler.STATUS_NEEDS_REVIEW, result.Warranty_Status__c, 'Fault date before purchase should be Needs Review');
        System.assert(result.Warranty_Note__c.contains('purchase date'), 'Note should mention purchase date');
    }

    @isTest
    static void testBulkInsert() {
        Asset asset = getAsset(ASSET_IN_WARRANTY);
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 250; i++) {
            cases.add(new Case(
                Status = 'New',
                Origin = 'Phone',
                AssetId = asset.Id,
                Fault_Date__c = Date.today()
            ));
        }

        Test.startTest();
        insert cases;
        Test.stopTest();

        List<Case> results = [SELECT Warranty_Status__c FROM Case WHERE AssetId = :asset.Id];
        System.assertEquals(250, results.size(), 'All 250 cases should be inserted');
        for (Case c : results) {
            System.assertEquals(WarrantyClaimTriggerHandler.STATUS_IN_WARRANTY, c.Warranty_Status__c, 'Bulk case should be In Warranty');
        }
    }

    @isTest
    static void testUpdateOnlyRunsWhenRelevant() {
        Asset asset = getAsset(ASSET_IN_WARRANTY);
        Case c = new Case(
            Status = 'New',
            Origin = 'Phone',
            AssetId = asset.Id,
            Fault_Date__c = Date.today()
        );
        insert c;

        c = [SELECT Id, Subject, Warranty_Status__c FROM Case WHERE Id = :c.Id];
        c.Subject = 'Updated subject';

        Test.startTest();
        update c;
        Test.stopTest();

        Case result = [SELECT Warranty_Status__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(WarrantyClaimTriggerHandler.STATUS_IN_WARRANTY, result.Warranty_Status__c, 'Unrelated update should not change warranty status');
    }

    @isTest
    static void testUpdateChangesStatus() {
        Asset inWarrantyAsset = getAsset(ASSET_IN_WARRANTY);
        Case c = new Case(
            Status = 'New',
            Origin = 'Phone',
            AssetId = inWarrantyAsset.Id,
            Fault_Date__c = Date.today()
        );
        insert c;

        c.Fault_Date__c = Date.today().addDays(1);

        Test.startTest();
        update c;
        Test.stopTest();

        Case result = [SELECT Warranty_Status__c, Warranty_Note__c FROM Case WHERE Id = :c.Id];
        System.assertEquals(WarrantyClaimTriggerHandler.STATUS_NEEDS_REVIEW, result.Warranty_Status__c, 'Updating fault date to future should set Needs Review');
        System.assert(result.Warranty_Note__c.contains('future'), 'Note should mention future fault date after update');
    }
}