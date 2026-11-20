import { createElement } from '@lwc/engine-dom';
import Paginator from 'c/paginator';

describe('c-paginator', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    async function flushPromises() {
        return Promise.resolve();
    }

    it('sends "next" event on button click', async () => {
        // Create initial element
        const element = createElement('c-paginator', {
            is: Paginator
        });
        element.pageNumber = 1;
        element.pageSize = 5;
        element.totalItemCount = 20;
        document.body.appendChild(element);

        // Mock handler for child event
        const handlerNext = jest.fn();
        element.addEventListener('next', handlerNext);

        // Click the next (>) button: it is the last button in the component
        const buttonEls = element.shadowRoot.querySelectorAll(
            'lightning-button-icon'
        );
        const nextButtonEl = buttonEls[buttonEls.length - 1];
        nextButtonEl.click();

        // Wait for any asynchronous DOM updates
        await flushPromises();

        // Validate the mocked event got fired
        expect(handlerNext).toHaveBeenCalled();
    });

    it('sends "previous" event on button click', async () => {
        // Create initial element
        const element = createElement('c-paginator', {
            is: Paginator
        });
        element.pageNumber = 2;
        element.pageSize = 5;
        element.totalItemCount = 20;
        document.body.appendChild(element);

        // Mock handler for child event
        const handlerPrevious = jest.fn();
        element.addEventListener('previous', handlerPrevious);

        // Click the previous (<) button: it is the first button in the component
        const prevButtonEl = element.shadowRoot.querySelector(
            'lightning-button-icon'
        );
        prevButtonEl.click();

        // Wait for any asynchronous DOM updates
        await flushPromises();

        // Validate the mocked event got fired
        expect(handlerPrevious).toHaveBeenCalled();
    });

    it('displays the page count derived from total items and page size', async () => {
        // Create initial element
        const element = createElement('c-paginator', {
            is: Paginator
        });
        element.pageNumber = 1;
        element.pageSize = 5;
        element.totalItemCount = 12;
        document.body.appendChild(element);

        // Wait for any asynchronous DOM updates
        await flushPromises();

        // ceil(12 / 5) = 3 pages
        expect(element.shadowRoot.textContent).toContain('of 3');
    });

    it('displays a page count of 0 and disables the next button when pageSize is zero', async () => {
        // Create initial element with a positive item count and a zero page size
        const element = createElement('c-paginator', {
            is: Paginator
        });
        element.pageNumber = 1;
        element.pageSize = 0;
        element.totalItemCount = 12;
        document.body.appendChild(element);

        // Wait for any asynchronous DOM updates
        await flushPromises();

        // The page count must be 0, not Infinity
        expect(element.shadowRoot.textContent).toContain('of 0');

        // Page 1 of 0 means we are treated as being on the last page,
        // so the next-page button must be disabled
        const buttonEls = element.shadowRoot.querySelectorAll(
            'lightning-button-icon'
        );
        const nextButtonEl = buttonEls[buttonEls.length - 1];
        expect(nextButtonEl.disabled).toBe(true);
    });

    it('displays a page count of 0 and disables the next button when pageSize is unset', async () => {
        // Create initial element with a positive item count and no page size set
        const element = createElement('c-paginator', {
            is: Paginator
        });
        element.pageNumber = 1;
        element.totalItemCount = 12;
        document.body.appendChild(element);

        // Wait for any asynchronous DOM updates
        await flushPromises();

        // The page count must be 0, not NaN
        expect(element.shadowRoot.textContent).toContain('of 0');

        // Page 1 of 0 means we are treated as being on the last page,
        // so the next-page button must be disabled
        const buttonEls = element.shadowRoot.querySelectorAll(
            'lightning-button-icon'
        );
        const nextButtonEl = buttonEls[buttonEls.length - 1];
        expect(nextButtonEl.disabled).toBe(true);
    });

    it('displays a page count of 0 when pageSize is negative', async () => {
        // Create initial element with a positive item count and a negative page size
        const element = createElement('c-paginator', {
            is: Paginator
        });
        element.pageNumber = 1;
        element.pageSize = -5;
        element.totalItemCount = 12;
        document.body.appendChild(element);

        // Wait for any asynchronous DOM updates
        await flushPromises();

        // The page count must be 0, not a negative number
        expect(element.shadowRoot.textContent).toContain('of 0');
    });
});
