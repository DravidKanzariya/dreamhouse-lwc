@isTest
private class AssetWarrantyHandlerTest {
    @TestSetup
    static void setup() {
        Account testAccount = new Account(Name = 'Warranty Test Account');
        insert testAccount;

        List<Product2> products = new List<Product2>{
            new Product2(Name = '1 Year Warranty Product', Warranty_Term_Years__c = 1),
            new Product2(Name = '2 Year Warranty Product', Warranty_Term_Years__c = 2),
            new Product2(Name = '5 Year Warranty Product', Warranty_Term_Years__c = 5),
            new Product2(Name = 'No Warranty Term Product', Warranty_Term_Years__c = null)
        };
        insert products;
    }

    static Id getAccountId() {
        return [SELECT Id FROM Account WHERE Name = 'Warranty Test Account' LIMIT 1].Id;
    }

    static Id getProductIdByTerm(Decimal term) {
        return [SELECT Id FROM Product2 WHERE Warranty_Term_Years__c = :term LIMIT 1].Id;
    }

    static Id getProductIdByName(String productName) {
        return [SELECT Id FROM Product2 WHERE Name = :productName LIMIT 1].Id;
    }

    @isTest
    static void testOneYearTerm() {
        Id accountId = getAccountId();
        Id productId = getProductIdByTerm(1);

        Asset asset = new Asset(
            Name = 'One Year Asset',
            AccountId = accountId,
            Product2Id = productId,
            PurchaseDate = Date.newInstance(2023, 6, 15)
        );

        Test.startTest();
        insert asset;
        Test.stopTest();

        Asset result = [SELECT Warranty_End_Date__c FROM Asset WHERE Id = :asset.Id];
        System.assertEquals(Date.newInstance(2024, 6, 15), result.Warranty_End_Date__c, 'One year term should be added to purchase date');
    }

    @isTest
    static void testTwoYearTerm() {
        Id accountId = getAccountId();
        Id productId = getProductIdByTerm(2);

        Asset asset = new Asset(
            Name = 'Two Year Asset',
            AccountId = accountId,
            Product2Id = productId,
            PurchaseDate = Date.newInstance(2022, 3, 10)
        );

        Test.startTest();
        insert asset;
        Test.stopTest();

        Asset result = [SELECT Warranty_End_Date__c FROM Asset WHERE Id = :asset.Id];
        System.assertEquals(Date.newInstance(2024, 3, 10), result.Warranty_End_Date__c, 'Two year term should be added to purchase date');
    }

    @isTest
    static void testFiveYearTerm() {
        Id accountId = getAccountId();
        Id productId = getProductIdByTerm(5);

        Asset asset = new Asset(
            Name = 'Five Year Asset',
            AccountId = accountId,
            Product2Id = productId,
            PurchaseDate = Date.newInstance(2019, 7, 1)
        );

        Test.startTest();
        insert asset;
        Test.stopTest();

        Asset result = [SELECT Warranty_End_Date__c FROM Asset WHERE Id = :asset.Id];
        System.assertEquals(Date.newInstance(2024, 7, 1), result.Warranty_End_Date__c, 'Five year term should be added to purchase date');
    }

    @isTest
    static void testLeapYear() {
        Id accountId = getAccountId();
        Id productId = getProductIdByTerm(1);

        Asset asset = new Asset(
            Name = 'Leap Year Asset',
            AccountId = accountId,
            Product2Id = productId,
            PurchaseDate = Date.newInstance(2020, 2, 29)
        );

        Test.startTest();
        insert asset;
        Test.stopTest();

        Asset result = [SELECT Warranty_End_Date__c FROM Asset WHERE Id = :asset.Id];
        System.assertEquals(Date.newInstance(2021, 2, 28), result.Warranty_End_Date__c, 'Leap year date should roll to the last day of the month');
    }

    @isTest
    static void testMissingWarrantyTerm() {
        Id accountId = getAccountId();
        Id productId = getProductIdByName('No Warranty Term Product');

        Asset asset = new Asset(
            Name = 'Missing Term Asset',
            AccountId = accountId,
            Product2Id = productId,
            PurchaseDate = Date.newInstance(2023, 1, 1)
        );

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            insert asset;
        } catch (DmlException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('registered online'), 'Expected missing warranty term error message');
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Expected a DmlException when the product model has no warranty term');
    }

    @isTest
    static void testFuturePurchaseDate() {
        Id accountId = getAccountId();
        Id productId = getProductIdByTerm(1);

        Asset asset = new Asset(
            Name = 'Future Purchase Asset',
            AccountId = accountId,
            Product2Id = productId,
            PurchaseDate = Date.today().addDays(1)
        );

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            insert asset;
        } catch (DmlException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('future'), 'Expected future purchase date error message');
        }
        Test.stopTest();

        System.assert(exceptionThrown, 'Expected a DmlException when the purchase date is in the future');
    }

    @isTest
    static void testUpdateRecalculation() {
        Id accountId = getAccountId();
        Id twoYearProductId = getProductIdByTerm(2);
        Id fiveYearProductId = getProductIdByTerm(5);

        Asset asset = new Asset(
            Name = 'Update Asset',
            AccountId = accountId,
            Product2Id = twoYearProductId,
            PurchaseDate = Date.newInstance(2023, 1, 1)
        );
        insert asset;

        Asset beforeUpdate = [SELECT Warranty_End_Date__c FROM Asset WHERE Id = :asset.Id];
        System.assertEquals(Date.newInstance(2025, 1, 1), beforeUpdate.Warranty_End_Date__c, 'Initial warranty end date should be two years from purchase');

        asset.PurchaseDate = Date.newInstance(2024, 2, 1);
        asset.Product2Id = fiveYearProductId;

        Test.startTest();
        update asset;
        Test.stopTest();

        Asset result = [SELECT Warranty_End_Date__c FROM Asset WHERE Id = :asset.Id];
        System.assertEquals(Date.newInstance(2029, 2, 1), result.Warranty_End_Date__c, 'Warranty end date should be recalculated on update');
    }

    @isTest
    static void testBulkInsert() {
        Id accountId = getAccountId();
        Id productId = getProductIdByTerm(1);

        List<Asset> assets = new List<Asset>();
        for (Integer i = 0; i < 200; i++) {
            assets.add(new Asset(
                Name = 'Bulk Asset ' + i,
                AccountId = accountId,
                Product2Id = productId,
                PurchaseDate = Date.newInstance(2023, 1, 1)
            ));
        }

        Test.startTest();
        insert assets;
        Test.stopTest();

        List<Asset> results = [SELECT Warranty_End_Date__c FROM Asset WHERE Id IN :assets];
        System.assertEquals(200, results.size(), 'All 200 assets should be inserted');

        for (Asset result : results) {
            System.assertEquals(Date.newInstance(2024, 1, 1), result.Warranty_End_Date__c, 'Bulk assets should have the calculated warranty end date');
        }
    }
}