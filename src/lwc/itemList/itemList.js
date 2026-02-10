import { LightningElement, api, wire } from 'lwc';
import getAccountDetails from '@salesforce/apex/AccountController.getAccountDetails';
import getItems from '@salesforce/apex/ItemController.getItems';

export default class ItemList extends LightningElement {
    @api recordId;

    account;
    items = [];
    isLoading = true;
    cartItems = [];

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

    @wire(getItems, { familyFilter: 'All', typeFilter: 'All', searchTerm: '' })
    wiredItems({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.items = data;
        } else if (error) {
            console.error('Error loading items:', error);
            this.items = [];
        }
    }

    handleAddToCart(event) {
        const { itemId, itemName } = event.detail;
        console.log('Item added to cart:', itemName);


        const item = this.items.find(i => i.Id === itemId);
        if (item) {
            this.cartItems.push({
                itemId: item.Id,
                itemName: item.Name,
                unitCost: item.Price__c,
                amount: 1
            });
            console.log('Cart items:', this.cartItems);
        }
    }
}