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
        const pageSize = Number(this.pageSize);
        // Guard against page sizes that are not positive numbers
        // (unset/undefined, null, NaN, zero, or negative). Dividing by such
        // a value would produce NaN or Infinity, so the page count is 0.
        if (!Number.isFinite(pageSize) || pageSize <= 0) {
            return 0;
        }
        return Math.ceil(this.totalItemCount / pageSize);
    }
}
