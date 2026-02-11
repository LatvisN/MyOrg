import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getAccountDetails from '@salesforce/apex/AccountController.getAccountDetails';
import getItems from '@salesforce/apex/ItemController.getItems';
import getPicklistValues from '@salesforce/apex/ItemController.getPicklistValues';
import isCurrentUserManager from '@salesforce/apex/UserController.isCurrentUserManager';

export default class ItemList extends LightningElement {
    isManager = false;
    showCreateItemModal = false;
    familyOptionsForCreate = [];
    typeOptionsForCreate = [];

    @api recordId;

    account;
    items = [];
    isLoading = true;
    error;
    cartItems = [];

    showDetailModal = false;
    selectedItem = null;

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

    @wire(isCurrentUserManager)
    wiredIsManager({ error, data }) {
        if (data !== undefined) {
            this.isManager = data;
            console.log('Is manager:', data);
        }
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

            this.familyOptionsForCreate = data.Family
                .filter(v => v !== 'All')
                .map(value => ({ label: value, value: value }));
            this.typeOptionsForCreate = data.Type
                .filter(v => v !== 'All')
                .map(value => ({ label: value, value: value }));
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

    handleOpenCreateItem() {
        this.showCreateItemModal = true;
    }

    handleCloseCreateItem() {
        this.showCreateItemModal = false;
    }

    handleItemCreated(event) {
        console.log('Item created:', event.detail.item);
        this.showCreateItemModal = false;
        return refreshApex(this.wiredItemsResult);
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

handleViewDetails(event) {
    console.log('=== handleViewDetails START ===');
    console.log('Event received:', event);
    console.log('Event detail:', event.detail);
    console.log('Current showDetailModal:', this.showDetailModal);

    this.selectedItem = event.detail.item;
    this.showDetailModal = true;

    console.log('After update - showDetailModal:', this.showDetailModal);
    console.log('After update - selectedItem:', this.selectedItem);
    console.log('=== handleViewDetails END ===');
}

    handleCloseDetailModal() {
        this.showDetailModal = false;
        this.selectedItem = null;
    }

    handleAddToCartFromModal(event) {
        this.handleAddToCart({
            detail: {
                itemId: event.detail.item.Id,
                itemName: event.detail.item.Name__c || event.detail.item.Name
            }
        });
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