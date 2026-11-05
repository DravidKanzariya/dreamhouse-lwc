trigger CaseWarrantyStatusTrigger on Case (before insert, before update) {
    if (Trigger.isInsert) {
        WarrantyClaimTriggerHandler.handleBeforeInsert(Trigger.new);
    } else if (Trigger.isUpdate) {
        WarrantyClaimTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
}