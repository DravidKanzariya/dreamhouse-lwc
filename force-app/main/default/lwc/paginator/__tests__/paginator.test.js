import { createElement } from 'lwc';
import Paginator from 'c/paginator';

describe('c-paginator', () => {
    afterEach(() => {
        // The jsdom instance is shared across test cases in a single file so reset the DOM
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    // Returns the paginator's navigation buttons in template order
    // (Previous first, Next last)
    function getNavButtons(element) {
        return element.shadowRoot.querySelectorAll(
            'lightning-button-icon, lightning-button'
        );
    }

    // Returns the component's rendered text with whitespace collapsed
    function getRenderedText(element) {
        return element.shadowRoot.textContent.replace(/\s+/g, ' ').trim();
    }

    it('sends "next" event on button click', () => {
        // Create initial element
        const element = createElement('c-paginator', {
            is: Paginator
        });
        element.pageNumber = 1;
        element.pageSize = 5;
        element.totalItemCount = 20;
        document.body.appendChild(element);

        // Mock handlers for child events
        const handlerNext = jest.fn();

        // Add event listener to catch child events
        element.addEventListener('next', handlerNext);

        // Click the next(>) button
        const buttons = getNavButtons(element);
        const nextButtonEl = buttons[buttons.length - 1];
        nextButtonEl.click();

        // Validate if mocked events got fired
        return Promise.resolve().then(() => {
            expect(handlerNext.mock.calls.length).toBe(1);
        });
    });

    it('sends "previous" event on button click', () => {
        // Create initial element
        const element = createElement('c-paginator', {
            is: Paginator
        });
        element.pageNumber = 2;
        element.pageSize = 5;
        element.totalItemCount = 20;
        document.body.appendChild(element);

        // Mock handlers for child events
        const handlerPrevious = jest.fn();

        // Add event listener to catch child events
        element.addEventListener('previous', handlerPrevious);

        // Click the Previous(<) button
        const buttons = getNavButtons(element);
        const prevButtonEl = buttons[0];
        prevButtonEl.click();

        // Validate if mocked events got fired
        return Promise.resolve().then(() => {
            expect(handlerPrevious.mock.calls.length).toBe(1);
        });
    });

    it('displays the current page number and page count', () => {
        // Create initial element
        const element = createElement('c-paginator', {
            is: Paginator
        });
        element.pageNumber = 2;
        element.pageSize = 5;
        element.totalItemCount = 12;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            expect(getRenderedText(element)).toContain('Page 2 of 3');
        });
    });

    it('renders a page count of 0 when the page size is zero', () => {
        // Create initial element with a positive item count but a page size of zero
        const element = createElement('c-paginator', {
            is: Paginator
        });
        element.pageNumber = 1;
        element.pageSize = 0;
        element.totalItemCount = 12;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            // Page count must be 0 instead of Infinity
            expect(getRenderedText(element)).toContain('Page 1 of 0');

            // The Next-page button must be disabled when the page count is 0
            const buttons = getNavButtons(element);
            const nextButtonEl = buttons[buttons.length - 1];
            const isDisabled =
                nextButtonEl.disabled === true ||
                nextButtonEl.hasAttribute('disabled');
            expect(isDisabled).toBe(true);
        });
    });

    it('renders a page count of 0 and disables Next when the page size is unset', () => {
        // Create initial element with a positive item count and no page size
        const element = createElement('c-paginator', {
            is: Paginator
        });
        element.pageNumber = 1;
        // pageSize is intentionally left unset
        element.totalItemCount = 12;
        document.body.appendChild(element);

        return Promise.resolve().then(() => {
            // Page count must be 0 instead of NaN
            expect(getRenderedText(element)).toContain('Page 1 of 0');

            // The Next-page button must be disabled when the page count is 0
            const buttons = getNavButtons(element);
            const nextButtonEl = buttons[buttons.length - 1];
            const isDisabled =
                nextButtonEl.disabled === true ||
                nextButtonEl.hasAttribute('disabled');
            expect(isDisabled).toBe(true);
        });
    });
});
