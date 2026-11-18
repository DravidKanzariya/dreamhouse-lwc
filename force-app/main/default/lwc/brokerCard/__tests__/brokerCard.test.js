import { createElement } from 'lwc';
import BrokerCard from 'c/brokerCard';
import { getRecord } from 'lightning/uiRecordApi';
import { registerLdsTestWireAdapter } from '@salesforce/sfdx-lwc-jest';
import { getNavigateCalledWith } from 'lightning/navigation';

// Mock realistic data
const mockGetPropertyRecord = require('./data/getPropertyRecord.json');

// Register as a standard wire adapter because the data is coming from LDS
const getRecordAdapter = registerLdsTestWireAdapter(getRecord);

describe('c-broker-card', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        // Prevent data saved on mocks from leaking between tests
        jest.clearAllMocks();
    });

    it('renders a broker record form for the current property', async () => {
        // Arrange
        const element = createElement('c-broker-card', {
            is: BrokerCard
        });

        // Act
        document.body.appendChild(element);

        // Emit data from @wire
        getRecordAdapter.emit(mockGetPropertyRecord);

        // Wait for any asynchronous DOM updates
        await Promise.resolve();

        // Assert
        const recordFormEl = element.shadowRoot.querySelector(
            'lightning-record-form'
        );
        expect(recordFormEl).not.toBeNull();
        expect(recordFormEl.recordId).toBe(
            mockGetPropertyRecord.fields.Broker__c.value
        );
    });

    it('navigates to the broker record when the button is clicked', async () => {
        // Arrange
        const element = createElement('c-broker-card', {
            is: BrokerCard
        });

        // Act
        document.body.appendChild(element);

        // Emit data from @wire
        getRecordAdapter.emit(mockGetPropertyRecord);

        // Wait for any asynchronous DOM updates
        await Promise.resolve();

        // Click button
        const buttonEl = element.shadowRoot.querySelector('lightning-button');
        buttonEl.click();

        // Assert
        const { pageReference } = getNavigateCalledWith();
        expect(pageReference.type).toBe('standard__recordPage');
        expect(pageReference.attributes.recordId).toBe(
            mockGetPropertyRecord.fields.Broker__c.value
        );
        expect(pageReference.attributes.objectApiName).toBe('Broker__c');
        expect(pageReference.attributes.actionName).toBe('view');
    });
});
