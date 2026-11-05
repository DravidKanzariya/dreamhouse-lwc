public with sharing class CaseFeedbackSyncHelper {
    private static final String STATUS_IN_REVIEW = 'In Review';
    private static final String STATUS_CLOSED = 'Closed';
    private static final String CONTEXT_CASE_FEEDBACK_SYNC = 'CaseFeedbackSyncHelper';

    public static void handleAfterUpdate(List<Case> newCases, Map<Id, Case> oldMap) {
        if (newCases == null || newCases.isEmpty() || oldMap == null || oldMap.isEmpty()) {
            return;
        }

        Set<Id> caseIdsWithClosureChange = new Set<Id>();
        for (Case c : newCases) {
            Case oldCase = oldMap.get(c.Id);
            if (oldCase != null && oldCase.IsClosed != c.IsClosed) {
                caseIdsWithClosureChange.add(c.Id);
            }
        }

        if (caseIdsWithClosureChange.isEmpty()) {
            return;
        }

        Map<Id, List<Feedback__c>> feedbackByCaseId = new Map<Id, List<Feedback__c>>();
        for (Feedback__c feedback : [
            SELECT Id, Status__c, Closed_Date__c, Related_Case__c
            FROM Feedback__c
            WHERE Related_Case__c IN :caseIdsWithClosureChange
        ]) {
            if (!feedbackByCaseId.containsKey(feedback.Related_Case__c)) {
                feedbackByCaseId.put(feedback.Related_Case__c, new List<Feedback__c>());
            }
            feedbackByCaseId.get(feedback.Related_Case__c).add(feedback);
        }

        List<Feedback__c> feedbackToUpdate = new List<Feedback__c>();
        for (Case c : newCases) {
            if (!caseIdsWithClosureChange.contains(c.Id)) {
                continue;
            }

            List<Feedback__c> relatedFeedback = feedbackByCaseId.get(c.Id);
            if (relatedFeedback == null || relatedFeedback.isEmpty()) {
                continue;
            }

            Boolean caseNowClosed = c.IsClosed;
            for (Feedback__c feedback : relatedFeedback) {
                Boolean shouldUpdate = false;
                if (caseNowClosed && feedback.Status__c != STATUS_CLOSED) {
                    feedback.Status__c = STATUS_CLOSED;
                    feedback.Closed_Date__c = Date.today();
                    shouldUpdate = true;
                } else if (!caseNowClosed && STATUS_CLOSED.equals(feedback.Status__c)) {
                    feedback.Status__c = STATUS_IN_REVIEW;
                    feedback.Closed_Date__c = null;
                    shouldUpdate = true;
                }

                if (shouldUpdate) {
                    feedbackToUpdate.add(feedback);
                }
            }
        }

        if (!feedbackToUpdate.isEmpty()) {
            updateFeedbackRecords(feedbackToUpdate);
        }
    }

    @TestVisible
    private static void updateFeedbackRecords(List<Feedback__c> feedbacks) {
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        List<Database.SaveResult> saveResults = Database.update(feedbacks, false);

        for (Integer i = 0; i < saveResults.size(); i++) {
            Database.SaveResult sr = saveResults[i];
            if (!sr.isSuccess()) {
                Feedback__c feedback = feedbacks[i];
                String errorMessage = buildErrorMessage(sr.getErrors());
                errorLogs.add(new Error_Log__c(
                    Message__c = errorMessage,
                    Record_ID__c = feedback.Id,
                    Context__c = CONTEXT_CASE_FEEDBACK_SYNC
                ));
            }
        }

        if (!errorLogs.isEmpty()) {
            try {
                insert errorLogs;
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Failed to insert error logs: ' + e.getMessage());
            }
        }
    }

    private static String buildErrorMessage(List<Database.Error> errors) {
        List<String> messages = new List<String>();
        for (Database.Error err : errors) {
            messages.add(err.getStatusCode() + ': ' + err.getMessage());
        }
        return String.join(messages, '; ');
    }
}