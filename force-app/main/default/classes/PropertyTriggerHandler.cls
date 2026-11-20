public with sharing class PropertyTriggerHandler {
    /**
     * Sets Date_Closed__c to today for properties whose Status__c is 'Closed'
     * and that do not already have a closing date.
     * Runs in a before trigger context, so values are set directly on the records.
     */
    public static void setClosingDate(List<Property__c> newProperties) {
        for (Property__c propertyRecord : newProperties) {
            if (
                propertyRecord.Status__c == 'Closed' &&
                propertyRecord.Date_Closed__c == null
            ) {
                propertyRecord.Date_Closed__c = Date.today();
            }
        }
    }
}
