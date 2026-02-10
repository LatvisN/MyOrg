import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getAccountDetails from '@salesforce/apex/AccountController.getAccountDetails';
import getItems from '@salesforce/apex/ItemController.getItems';
import getPicklistValues from '@salesforce/apex/ItemController.getPicklistValues';

export default class ItemList extends LightningElement {
    @api recordId;

    account;
    items = [];
    isLoading = true;
    error;
    cartItems = [];

    @track selectedFamily = 'All';
    @track selectedType = 'All';
    @track searchTerm = '';

    familyOptions = [];
    typeOptions = [];

    wiredItemsResult;

    get accountNumber() {
        return this.account?.AccountNumber || 'N/A';
    }

    get accountIndustry() {
        return this.account?.Industry || 'N/A';
    }

    get itemsCount() {
        return this.items ? this.items.length : 0;
    }

    get hasItems() {
        return this.items && this.items.length > 0;
    }

    @wire(getAccountDetails, { accountId: '$recordId' })
    wiredAccount({ error, data }) {
        if (data) {
            this.account = data;
        } else if (error) {
            console.error('Error loading account:', error);
        }
    }

    @wire(getPicklistValues)
    wiredPicklistValues({ error, data }) {
        if (data) {
            this.familyOptions = data.Family.map(value => ({
                label: value,
                value: value
            }));
            this.typeOptions = data.Type.map(value => ({
                label: value,
                value: value
            }));
        }
    }

    @wire(getItems, {
        familyFilter: '$selectedFamily',
        typeFilter: '$selectedType',
        searchTerm: '$searchTerm'
    })
    wiredItems(result) {
        this.wiredItemsResult = result;
        this.isLoading = false;

        if (result.data) {
            this.items = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error;
            this.items = [];
            console.error('Error loading items:', result.error);
        }
    }

    handleFilterChange(event) {
        const { family, type } = event.detail;
        this.selectedFamily = family;
        this.selectedType = type;
        this.isLoading = true;
    }

    handleSearchChange(event) {
        this.searchTerm = event.detail.searchTerm;
        this.isLoading = true;
    }

    handleAddToCart(event) {
        const { itemId, itemName } = event.detail;
        const item = this.items.find(i => i.Id === itemId);

        if (item) {
            const existingItem = this.cartItems.find(ci => ci.itemId === itemId);

            if (existingItem) {
                existingItem.amount += 1;
            } else {
                this.cartItems.push({
                    itemId: item.Id,
                    itemName: item.Name__c || item.Name,
                    unitCost: item.Price__c,
                    amount: 1
                });
            }

            console.log('Cart items:', this.cartItems);
        }
    }
}