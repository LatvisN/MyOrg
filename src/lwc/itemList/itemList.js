import { LightningElement, api, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getAccountDetails from '@salesforce/apex/AccountController.getAccountDetails';
import getItems from '@salesforce/apex/ItemController.getItems';
import getPicklistValues from '@salesforce/apex/ItemController.getPicklistValues';
import isCurrentUserManager from '@salesforce/apex/UserController.isCurrentUserManager';
import { NavigationMixin } from 'lightning/navigation';
import createPurchase from '@salesforce/apex/PurchaseController.createPurchase';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ItemList extends NavigationMixin(LightningElement) {
    isManager = false;
    showCreateItemModal = false;
    familyOptionsForCreate = [];
    typeOptionsForCreate = [];
    showCartModal = false;

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

    //менеджер ли
    @wire(isCurrentUserManager)
    wiredIsManager({ error, data }) {
        if (data !== undefined) {
            this.isManager = data;
            console.log('Is manager:', data);
        }
    }

    //корзина
    get cartButtonLabel() {
        const count = this.cartItems.reduce((sum, item) => sum + item.amount, 0);
        return `Cart (${count})`;
    }

    get cartItemsForModal() {
        return this.cartItems.map(item => ({
            ...item,
            subtotal: (item.unitCost * item.amount).toFixed(2)
        }));
    }

    get cartButtonLabel() {
        const count = this.cartItems.reduce((sum, item) => sum + item.amount, 0);
        return count > 0 ? `Cart (${count})` : 'Cart';
    }

    get cartCount() {
        return this.cartItems.reduce((sum, item) => sum + item.amount, 0);
    }

    get hasItemsInCart() {
        return this.cartItems.length > 0;
    }

    handleOpenCart() {
        this.showCartModal = true;
    }

    handleCloseCart() {
        this.showCartModal = false;
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

        // Отладка
        console.log('About to show toast for:', item.Name__c || item.Name);

        try {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Added to Cart',
                message: `${item.Name__c || item.Name} added to cart`,
                variant: 'success'
            }));
            console.log('Toast dispatched successfully');
        } catch (error) {
            console.error('Toast error:', error);
        }
    }
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
        } finally {
            this.isLoading = false;
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

            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: `${item.Name__c || item.Name} added to cart`,
                variant: 'success'
            }));
        }
    }

    //данные акка
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