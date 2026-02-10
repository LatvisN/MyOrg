import { LightningElement, api } from 'lwc';

export default class ItemFilters extends LightningElement {
    @api familyOptions = [];
    @api typeOptions = [];
    @api itemsCount = 0;

    selectedFamily = 'All';
    selectedType = 'All';
    searchTerm = '';

    searchTimeout;

    handleFamilyChange(event) {
        this.selectedFamily = event.detail.value;
        this.dispatchFilterChange();
    }

    handleTypeChange(event) {
        this.selectedType = event.detail.value;
        this.dispatchFilterChange();
    }

    handleSearchChange(event) {
        this.searchTerm = event.detail.value;

        clearTimeout(this.searchTimeout);
        this.searchTimeout = setTimeout(() => {
            this.dispatchEvent(new CustomEvent('searchchange', {
                detail: { searchTerm: this.searchTerm }
            }));
        }, 300);
    }

    dispatchFilterChange() {
        this.dispatchEvent(new CustomEvent('filterchange', {
            detail: {
                family: this.selectedFamily,
                type: this.selectedType
            }
        }));
    }
}