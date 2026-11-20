trigger PropertyTrigger on Property__c(before insert, before update) {
    PropertyTriggerHandler.setClosingDate(Trigger.new);
}
