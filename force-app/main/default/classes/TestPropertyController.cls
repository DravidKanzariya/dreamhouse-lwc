@isTest
private class TestPropertyController {
    private static final String MOCK_PICTURE_NAME = 'MockPictureName';

    @testSetup
    static void makeData() {
        List<Property__c> properties = new List<Property__c>{
            new Property__c(
                Name = 'Stunning Victorian',
                Address__c = '18 Henry St',
                City__c = 'Cambridge',
                State__c = 'MA',
                Zip__c = '02139',
                Price__c = 975000,
                Beds__c = 4,
                Baths__c = 3,
                Tags__c = 'victorian'
            ),
            new Property__c(
                Name = 'Waterfront Studio',
                Address__c = '24 Brattle St',
                City__c = 'Cambridge',
                State__c = 'MA',
                Zip__c = '02138',
                Price__c = 450000,
                Beds__c = 1,
                Baths__c = 1,
                Tags__c = 'waterfront'
            ),
            new Property__c(
                Name = 'Downtown Loft',
                Address__c = '100 Main St',
                City__c = 'Boston',
                State__c = 'MA',
                Zip__c = '02110',
                Price__c = 650000,
                Beds__c = 2,
                Baths__c = 2,
                Tags__c = 'loft'
            )
        };
        insert properties;

        ContentVersion picture = new ContentVersion(
            Title = MOCK_PICTURE_NAME,
            PathOnClient = 'picture.jpg',
            VersionData = Blob.valueOf('MockPictureData')
        );
        insert picture;

        ContentVersion insertedPicture = [
            SELECT Id, ContentDocumentId
            FROM ContentVersion
            WHERE Id = :picture.Id
            LIMIT 1
        ];

        ContentDocumentLink link = new ContentDocumentLink(
            LinkedEntityId = properties[0].Id,
            ContentDocumentId = insertedPicture.ContentDocumentId,
            ShareType = 'V'
        );
        insert link;
    }

    @isTest
    static void testGetPagedPropertyListWithSearchKey() {
        Test.startTest();
        PagedResult result = PropertyController.getPagedPropertyList(
            'Victorian',
            1000000,
            0,
            0,
            10,
            1
        );
        Test.stopTest();

        System.assertEquals(
            1,
            result.records.size(),
            'Expected exactly one property to match the search key'
        );
        System.assertEquals(
            1,
            result.totalItemCount,
            'Total item count should reflect the keyed search matches'
        );
        Property__c matched = (Property__c) result.records[0];
        System.assertEquals(
            'Stunning Victorian',
            matched.Name,
            'Keyed search returned an unexpected property'
        );
    }

    @isTest
    static void testGetPagedPropertyListNullSearchKey() {
        Test.startTest();
        PagedResult filteredResult = PropertyController.getPagedPropertyList(
            null,
            1000000,
            2,
            2,
            10,
            1
        );
        PagedResult unfilteredResult = PropertyController.getPagedPropertyList(
            null,
            null,
            null,
            null,
            null,
            null
        );
        Test.stopTest();

        System.assertEquals(
            2,
            filteredResult.records.size(),
            'A null search key should return every property passing the price, bedroom and bathroom filters'
        );
        System.assertEquals(
            2,
            filteredResult.totalItemCount,
            'Total item count should match the number of properties passing the filters when the search key is null'
        );
        System.assertEquals(
            3,
            unfilteredResult.records.size(),
            'A null search key with no other filters should return every property'
        );
        System.assertEquals(
            3,
            unfilteredResult.totalItemCount,
            'Total item count should equal the number of existing properties when the search key is null'
        );
    }

    @isTest
    static void testGetPagedPropertyListBlankSearchKey() {
        Test.startTest();
        PagedResult result = PropertyController.getPagedPropertyList(
            '',
            1000000,
            0,
            0,
            10,
            1
        );
        Test.stopTest();

        System.assertEquals(
            3,
            result.records.size(),
            'A blank search key should return every property passing the filters'
        );
        System.assertEquals(
            3,
            result.totalItemCount,
            'Total item count should include every property when the search key is blank'
        );
    }

    @isTest
    static void testGetPagedPropertyListNullSearchKeyBulk() {
        List<Property__c> bulkProperties = new List<Property__c>();
        for (Integer i = 0; i < 200; i++) {
            bulkProperties.add(
                new Property__c(
                    Name = 'Bulk Property ' + i,
                    City__c = 'Boston',
                    State__c = 'MA',
                    Price__c = 300000,
                    Beds__c = 3,
                    Baths__c = 2
                )
            );
        }
        insert bulkProperties;

        Test.startTest();
        PagedResult result = PropertyController.getPagedPropertyList(
            null,
            500000,
            3,
            2,
            50,
            1
        );
        Test.stopTest();

        System.assertEquals(
            200,
            result.totalItemCount,
            'Total item count should include every bulk property passing the filters when the search key is null'
        );
        System.assertEquals(
            50,
            result.records.size(),
            'First page should contain exactly one page of records'
        );
    }

    @isTest
    static void testGetPictures() {
        Property__c property = [
            SELECT Id
            FROM Property__c
            WHERE Name = 'Stunning Victorian'
            LIMIT 1
        ];

        Test.startTest();
        List<ContentVersion> pictures = PropertyController.getPictures(
            property.Id
        );
        Test.stopTest();

        System.assertEquals(
            1,
            pictures.size(),
            'Expected one picture attached to the property'
        );
        System.assertEquals(
            MOCK_PICTURE_NAME,
            pictures[0].Title,
            'Unexpected picture title'
        );
    }

    @isTest
    static void testGetPicturesWithoutPictures() {
        Property__c property = [
            SELECT Id
            FROM Property__c
            WHERE Name = 'Downtown Loft'
            LIMIT 1
        ];

        Test.startTest();
        List<ContentVersion> pictures = PropertyController.getPictures(
            property.Id
        );
        Test.stopTest();

        System.assertEquals(
            null,
            pictures,
            'Expected null when the property has no attached pictures'
        );
    }
}
