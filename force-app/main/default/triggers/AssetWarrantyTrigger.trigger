trigger AssetWarrantyTrigger on Asset (before insert, before update) {
    AssetWarrantyHandler.handleBefore(Trigger.new, Trigger.oldMap);
}