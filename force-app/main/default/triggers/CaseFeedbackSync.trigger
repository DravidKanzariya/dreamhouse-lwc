trigger CaseFeedbackSync on Case (after update) {
    CaseFeedbackSyncHelper.handleAfterUpdate(Trigger.new, Trigger.oldMap);
}