import { LightningElement, api } from 'lwc';

export default class Paginator extends LightningElement {
    /** The current page number. */
    @api pageNumber;

    /** The number of items on a page. */
    @api pageSize;

    /** The total number of items in the list. */
    @api totalItemCount;

    handlePrevious() {
        this.dispatchEvent(new CustomEvent('previous'));
    }

    handleNext() {
        this.dispatchEvent(new CustomEvent('next'));
    }

    get currentPageNumber() {
        return this.totalItemCount === 0 ? 0 : this.pageNumber;
    }

    get isFirstPage() {
        return this.pageNumber === 1;
    }

    get isLastPage() {
        return this.pageNumber >= this.totalPages;
    }

    get totalPages() {
        // Guard against a page size that is not a positive number
        // (undefined, null, 0 or negative) to avoid returning
        // Infinity or NaN from the division below.
        if (
            typeof this.pageSize !== 'number' ||
            Number.isNaN(this.pageSize) ||
            this.pageSize <= 0
        ) {
            return 0;
        }
        return Math.ceil(this.totalItemCount / this.pageSize);
    }
}
