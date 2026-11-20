import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import FORM_FACTOR from '@salesforce/client/formFactor';

export default class PropertyTile extends NavigationMixin(LightningElement) {
    /// Property__c to display.
    @api property;

    /// Whether the property has a price to display.
    get hasPrice() {
        return (
            this.property !== undefined &&
            this.property !== null &&
            this.property.Price__c !== undefined &&
            this.property.Price__c !== null
        );
    }

    handleClick() {
        if (FORM_FACTOR === 'Large') {
            const selectedEvent = new CustomEvent('selected', {
                detail: this.property.Id
            });
            this.dispatchEvent(selectedEvent);
        } else {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.property.Id,
                    objectApiName: 'Property__c',
                    actionName: 'view'
                }
            });
        }
    }
}
