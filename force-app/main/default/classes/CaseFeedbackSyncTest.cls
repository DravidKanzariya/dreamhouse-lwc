@isTest
private with sharing class CaseFeedbackSyncTest {
    private static final String STATUS_IN_REVIEW = 'In Review';
    private static final String STATUS_CLOSED = 'Closed';

    @TestSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(LastName = 'TestContact');
        insert testContact;

        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 5; i++) {
            cases.add(new Case(
                Subject = 'Test Case ' + i,
                Status = 'New',
                Origin = 'Email'
            ));
        }
        insert cases;

        List<Feedback__c> feedbacks = new List<Feedback__c>();

        Feedback__c closeFeedback = new Feedback__c(
            Status__c = STATUS_IN_REVIEW,
            Related_Case__c = cases[0].Id,
            Comments__c = 'Feedback for close test'
        );
        setFieldIfExists(closeFeedback, 'Account__c', testAccount.Id);
        setFieldIfExists(closeFeedback, 'Contact__c', testContact.Id);
        setFieldIfExists(closeFeedback, 'Rating__c', 1);
        feedbacks.add(closeFeedback);

        Feedback__c reopenFeedback = new Feedback__c(
            Status__c = STATUS_CLOSED,
            Closed_Date__c = Date.today().addDays(-1),
            Related_Case__c = cases[1].Id,
            Comments__c = 'Feedback for reopen test'
        );
        setFieldIfExists(reopenFeedback, 'Account__c', testAccount.Id);
        setFieldIfExists(reopenFeedback, 'Contact__c', testContact.Id);
        setFieldIfExists(reopenFeedback, 'Rating__c', 1);
        feedbacks.add(reopenFeedback);

        Feedback__c alreadyClosedFeedback = new Feedback__c(
            Status__c = STATUS_CLOSED,
            Closed_Date__c = Date.today().addDays(-2),
            Related_Case__c = cases[2].Id,
            Comments__c = 'Already closed feedback'
        );
        setFieldIfExists(alreadyClosedFeedback, 'Account__c', testAccount.Id);
        setFieldIfExists(alreadyClosedFeedback, 'Contact__c', testContact.Id);
        setFieldIfExists(alreadyClosedFeedback, 'Rating__c', 1);
        feedbacks.add(alreadyClosedFeedback);

        insert feedbacks;
    }

    @isTest
    static void testClosingCaseClosesLinkedFeedback() {
        Case testCase = [SELECT Id, IsClosed FROM Case WHERE Subject = 'Test Case 0' LIMIT 1];

        Test.startTest();
        testCase.Status = 'Closed';
        update testCase;
        Test.stopTest();

        Feedback__c feedback = [SELECT Status__c, Closed_Date__c FROM Feedback__c WHERE Related_Case__c = :testCase.Id LIMIT 1];
        System.assertEquals(STATUS_CLOSED, feedback.Status__c, 'Feedback status should be Closed when case is closed');
        System.assertEquals(Date.today(), feedback.Closed_Date__c, 'Feedback closed date should be set to today');
    }

    @isTest
    static void testReopeningCaseReopensLinkedFeedback() {
        Case testCase = [SELECT Id, IsClosed FROM Case WHERE Subject = 'Test Case 1' LIMIT 1];
        testCase.Status = 'Closed';
        update testCase;

        Test.startTest();
        testCase.Status = 'New';
        update testCase;
        Test.stopTest();

        Feedback__c feedback = [SELECT Status__c, Closed_Date__c FROM Feedback__c WHERE Related_Case__c = :testCase.Id LIMIT 1];
        System.assertEquals(STATUS_IN_REVIEW, feedback.Status__c, 'Feedback status should return to In Review when case is reopened');
        System.assertEquals(null, feedback.Closed_Date__c, 'Feedback closed date should be cleared when case is reopened');
    }

    @isTest
    static void testAlreadyClosedFeedbackStaysUnchangedOnClose() {
        Case testCase = [SELECT Id, IsClosed FROM Case WHERE Subject = 'Test Case 2' LIMIT 1];
        Feedback__c originalFeedback = [SELECT Status__c, Closed_Date__c FROM Feedback__c WHERE Related_Case__c = :testCase.Id LIMIT 1];
        Date originalClosedDate = originalFeedback.Closed_Date__c;

        Test.startTest();
        testCase.Status = 'Closed';
        update testCase;
        Test.stopTest();

        Feedback__c feedback = [SELECT Status__c, Closed_Date__c FROM Feedback__c WHERE Related_Case__c = :testCase.Id LIMIT 1];
        System.assertEquals(STATUS_CLOSED, feedback.Status__c, 'Already closed feedback should remain Closed');
        System.assertEquals(originalClosedDate, feedback.Closed_Date__c, 'Already closed feedback closed date should not change');
    }

    @isTest
    static void testCaseWithNoLinkedFeedbackDoesNothing() {
        Case testCase = [SELECT Id, IsClosed FROM Case WHERE Subject = 'Test Case 3' LIMIT 1];

        Test.startTest();
        testCase.Status = 'Closed';
        update testCase;
        Test.stopTest();

        List<Feedback__c> feedbacks = [SELECT Id FROM Feedback__c WHERE Related_Case__c = :testCase.Id];
        System.assertEquals(0, feedbacks.size(), 'No feedback should exist for this case');
        System.assertEquals('Closed', [SELECT Status FROM Case WHERE Id = :testCase.Id].Status, 'Case should still be closed');
    }

    @isTest
    static void testBulkCaseCloseAndReopen() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'TestContact' LIMIT 1];

        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < 200; i++) {
            cases.add(new Case(
                Subject = 'Bulk Case ' + i,
                Status = 'New',
                Origin = 'Email'
            ));
        }
        insert cases;

        List<Feedback__c> feedbacks = new List<Feedback__c>();
        for (Integer i = 0; i < 200; i++) {
            Feedback__c feedback = new Feedback__c(
                Status__c = STATUS_IN_REVIEW,
                Related_Case__c = cases[i].Id,
                Comments__c = 'Bulk feedback ' + i
            );
            setFieldIfExists(feedback, 'Account__c', testAccount.Id);
            setFieldIfExists(feedback, 'Contact__c', testContact.Id);
            setFieldIfExists(feedback, 'Rating__c', 2);
            feedbacks.add(feedback);
        }
        insert feedbacks;

        Test.startTest();
        for (Case c : cases) {
            c.Status = 'Closed';
        }
        update cases;
        Test.stopTest();

        List<Feedback__c> updatedFeedbacks = [SELECT Status__c FROM Feedback__c WHERE Related_Case__c IN :cases];
        System.assertEquals(200, updatedFeedbacks.size(), 'All 200 feedback records should be queried');
        for (Feedback__c feedback : updatedFeedbacks) {
            System.assertEquals(STATUS_CLOSED, feedback.Status__c, 'All linked feedback should be Closed in bulk close');
        }
    }

    @isTest
    static void testFeedbackUpdateFailureIsLogged() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'TestContact' LIMIT 1];

        Feedback__c feedback = new Feedback__c(
            Status__c = STATUS_IN_REVIEW,
            Comments__c = 'Feedback to delete'
        );
        setFieldIfExists(feedback, 'Account__c', testAccount.Id);
        setFieldIfExists(feedback, 'Contact__c', testContact.Id);
        setFieldIfExists(feedback, 'Rating__c', 1);
        insert feedback;

        Id feedbackId = feedback.Id;
        delete feedback;

        Test.startTest();
        CaseFeedbackSyncHelper.updateFeedbackRecords(new List<Feedback__c>{
            new Feedback__c(Id = feedbackId, Status__c = STATUS_CLOSED, Closed_Date__c = Date.today())
        });
        Test.stopTest();

        List<Error_Log__c> errorLogs = [SELECT Message__c, Record_ID__c, Context__c FROM Error_Log__c WHERE Context__c = 'CaseFeedbackSyncHelper'];
        System.assertEquals(1, errorLogs.size(), 'One error log should be created for failed feedback update');
        System.assertEquals(feedbackId, errorLogs[0].Record_ID__c, 'Error log should reference the feedback Id');
        System.assert(errorLogs[0].Message__c != null && errorLogs[0].Message__c.length() > 0, 'Error log should contain a message');
    }

    private static void setFieldIfExists(SObject record, String fieldName, Object value) {
        Map<String, Schema.SObjectField> fieldMap = record.getSObjectType().getDescribe().fields.getMap();
        if (fieldMap.containsKey(fieldName.toLowerCase())) {
            record.put(fieldName, value);
        }
    }
}