import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

import getAccountDetails from '@salesforce/apex/AccountController.getAccountDetails';
import getItems from '@salesforce/apex/ItemController.getItems';
import getPicklistValues from '@salesforce/apex/ItemController.getPicklistValues';
import isCurrentUserManager from '@salesforce/apex/UserController.isCurrentUserManager';
import createPurchase from '@salesforce/apex/PurchaseController.createPurchase';

export default class ItemList extends NavigationMixin(LightningElement) {
    @api recordId;

    account;
    items = [];
    isLoading = true;
    error;
    cartItems = [];

    isManager = false;

    showDetailModal = false;
    showCartModal = false;
    showCreateItemModal = false;
    selectedItem = null;

    @track selectedFamily = 'All';
    @track selectedType = 'All';
    @track searchTerm = '';

    familyOptions = [];
    typeOptions = [];
    familyOptionsForCreate = [];
    typeOptionsForCreate = [];

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

    get cartItemsForModal() {
        return this.cartItems.map(item => ({
            ...item,
            subtotal: (item.unitCost * item.amount).toFixed(2)
        }));
    }

    @wire(getAccountDetails, { accountId: '$recordId' })
    wiredAccount({ error, data }) {
        if (data) {
            this.account = data;
        } else if (error) {
            console.error('Error loading account:', error);
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference && !this.recordId) {
            this.recordId = currentPageReference.state.c__recordId;
        }
    }

    @wire(isCurrentUserManager)
    wiredIsManager({ error, data }) {
        if (data !== undefined) {
            this.isManager = data;
            console.log('Is manager:', data);
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
        this.selectedItem = event.detail.item;
        this.showDetailModal = true;
    }

    handleCloseDetailModal() {
        this.showDetailModal = false;
        this.selectedItem = null;
    }

    handleAddToCart(event) {
        const { itemId, itemName } = event.detail;
        const item = this.items.find(i => i.Id === itemId);

        if (item) {
            let updatedCart = [...this.cartItems];
            const existingItem = updatedCart.find(ci => ci.itemId === itemId);

            if (existingItem) {
                existingItem.amount += 1;
            } else {
                updatedCart.push({
                    itemId: item.Id,
                    itemName: item.Name__c || item.Name,
                    unitCost: item.Price__c,
                    amount: 1
                });
            }

            this.cartItems = updatedCart;

            this.showToast('Added to Cart', `${item.Name__c || item.Name} added to cart`, 'success');
        }
    }

    handleAddToCartFromModal(event) {
        const item = event.detail.item;

        if (item) {
            let updatedCart = [...this.cartItems];
            const existingItem = updatedCart.find(ci => ci.itemId === item.Id);

            if (existingItem) {
                existingItem.amount += 1;
            } else {
                updatedCart.push({
                    itemId: item.Id,
                    itemName: item.Name__c || item.Name,
                    unitCost: item.Price__c,
                    amount: 1
                });
            }

            this.cartItems = updatedCart;

            this.showToast('Added to Cart', `${item.Name__c || item.Name} added to cart`, 'success');
        }
    }

    handleOpenCart() {
        this.showCartModal = true;
    }

    handleCloseCart() {
        this.showCartModal = false;
    }

    async handleCheckout() {
        try {
            this.isLoading = true;

            const purchaseId = await createPurchase({
                accountId: this.recordId,
                cartItems: this.cartItems
            });

            this.showCartModal = false;
            this.cartItems = [];

            this.showToast('Success', 'Purchase created successfully!', 'success');

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: purchaseId,
                    objectApiName: 'Purchase__c',
                    actionName: 'view'
                }
            });
        } catch (error) {
            console.error('Checkout error:', error);
            this.showToast('Error', error.body?.message || 'Checkout failed', 'error');
        } finally {
            this.isLoading = false;
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
        this.showToast('Success', 'Item created successfully!', 'success');
        return refreshApex(this.wiredItemsResult);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        }));
    }
}