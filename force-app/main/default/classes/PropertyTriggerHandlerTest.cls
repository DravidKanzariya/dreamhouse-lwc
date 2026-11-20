@IsTest
private with sharing class PropertyTriggerHandlerTest {
    @IsTest
    static void testInsertClosedPropertySetsDateClosed() {
        Property__c propertyRecord = new Property__c(
            Name = 'Closed Insert Test',
            Status__c = 'Closed'
        );

        Test.startTest();
        insert propertyRecord;
        Test.stopTest();

        Property__c result = [
            SELECT Status__c, Date_Closed__c
            FROM Property__c
            WHERE Id = :propertyRecord.Id
        ];
        System.assertEquals(
            Date.today(),
            result.Date_Closed__c,
            'Date_Closed__c should be set to today when a Closed property is inserted without a closing date'
        );
    }

    @IsTest
    static void testUpdateToClosedSetsDateClosed() {
        Property__c propertyRecord = new Property__c(
            Name = 'Closed Update Test'
        );
        insert propertyRecord;

        propertyRecord.Status__c = 'Closed';

        Test.startTest();
        update propertyRecord;
        Test.stopTest();

        Property__c result = [
            SELECT Status__c, Date_Closed__c
            FROM Property__c
            WHERE Id = :propertyRecord.Id
        ];
        System.assertEquals(
            Date.today(),
            result.Date_Closed__c,
            'Date_Closed__c should be set to today when a property is updated to Closed without a closing date'
        );
    }

    @IsTest
    static void testExistingDateClosedIsPreserved() {
        Date originalDate = Date.today().addDays(-30);
        Property__c propertyRecord = new Property__c(
            Name = 'Existing Date Test',
            Status__c = 'Closed',
            Date_Closed__c = originalDate
        );

        Test.startTest();
        insert propertyRecord;
        propertyRecord.Name = 'Existing Date Test Updated';
        update propertyRecord;
        Test.stopTest();

        Property__c result = [
            SELECT Status__c, Date_Closed__c
            FROM Property__c
            WHERE Id = :propertyRecord.Id
        ];
        System.assertEquals(
            originalDate,
            result.Date_Closed__c,
            'A property that already has a closing date must keep its original date'
        );
    }

    @IsTest
    static void testBulkInsertClosedProperties() {
        Date preservedDate = Date.today().addDays(-10);
        List<Property__c> propertiesToInsert = new List<Property__c>();
        for (Integer i = 0; i < 200; i++) {
            propertiesToInsert.add(
                new Property__c(
                    Name = 'Bulk Closed ' + i,
                    Status__c = 'Closed'
                )
            );
        }
        propertiesToInsert.add(
            new Property__c(
                Name = 'Bulk Preserved Date',
                Status__c = 'Closed',
                Date_Closed__c = preservedDate
            )
        );

        Test.startTest();
        insert propertiesToInsert;
        Test.stopTest();

        List<Property__c> results = [
            SELECT Name, Date_Closed__c
            FROM Property__c
            WHERE Id IN :propertiesToInsert
        ];
        System.assertEquals(
            201,
            results.size(),
            'All 201 bulk records should have been inserted'
        );
        for (Property__c result : results) {
            if (result.Name == 'Bulk Preserved Date') {
                System.assertEquals(
                    preservedDate,
                    result.Date_Closed__c,
                    'The bulk record with an existing closing date must keep its original date'
                );
            } else {
                System.assertEquals(
                    Date.today(),
                    result.Date_Closed__c,
                    'Every bulk Closed property without a date should get today as Date_Closed__c'
                );
            }
        }
    }
}
