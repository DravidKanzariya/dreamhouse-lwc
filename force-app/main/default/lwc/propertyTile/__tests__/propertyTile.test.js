import { createElement } from 'lwc';
import PropertyTile from 'c/propertyTile';

describe('c-property-tile', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('displays a property', () => {
        // Create element
        const element = createElement('c-property-tile', {
            is: PropertyTile
        });
        element.property = {
            Id: '1',
            Name: 'Some name',
            Price__c: 450000,
            Thumbnail_IMG__c:
                'https://s3-us-west-1.amazonaws.com/sfdc-demo/realty/house08sq.jpg'
        };
        document.body.appendChild(element);

        // Verify displayed property
        const imgEl = element.shadowRoot.querySelector('img');
        expect(imgEl.src).toBe(
            'https://s3-us-west-1.amazonaws.com/sfdc-demo/realty/house08sq.jpg'
        );
        const nameEl = element.shadowRoot.querySelector('h1');
        expect(nameEl.textContent).toBe('Some name');
        const priceEl = element.shadowRoot.querySelector(
            'lightning-formatted-number'
        );
        expect(priceEl.value).toBe(450000);
    });

    it('displays "Price on request" when the property has no price', () => {
        // Create element with a property that has no Price__c value
        const element = createElement('c-property-tile', {
            is: PropertyTile
        });
        element.property = {
            Id: '1',
            Name: 'Some name',
            Price__c: null,
            Thumbnail_IMG__c:
                'https://s3-us-west-1.amazonaws.com/sfdc-demo/realty/house08sq.jpg'
        };
        document.body.appendChild(element);

        // Verify that no formatted price is displayed
        const priceEl = element.shadowRoot.querySelector(
            'lightning-formatted-number'
        );
        expect(priceEl).toBeNull();

        // Verify that the fallback text is displayed instead
        const fallbackEl = element.shadowRoot.querySelector(
            '[data-id="price-on-request"]'
        );
        expect(fallbackEl).not.toBeNull();
        expect(fallbackEl.textContent).toBe('Price on request');
    });

    it('fires a "selected" event on click', () => {
        // Create element
        const element = createElement('c-property-tile', {
            is: PropertyTile
        });
        element.property = {
            Id: '1',
            Name: 'Some name',
            Price__c: 450000,
            Thumbnail_IMG__c:
                'https://s3-us-west-1.amazonaws.com/sfdc-demo/realty/house08sq.jpg'
        };
        document.body.appendChild(element);

        // Mock handler for child event
        const handler = jest.fn();
        element.addEventListener('selected', handler);

        // Click tile
        element.shadowRoot.querySelector('div').click();

        // Verify event fired with the property Id
        expect(handler).toHaveBeenCalled();
        expect(handler.mock.calls[0][0].detail).toBe('1');
    });
});
