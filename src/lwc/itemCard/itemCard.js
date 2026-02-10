import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ItemCard extends LightningElement {
    @api item;

get itemName() {
    return this.item?.Name__c || this.item?.Name || 'Unknown Item';
}

    get itemDescription() {
        return this.item?.Description__c || 'No description';
    }

    get itemPrice() {
        return this.item?.Price__c?.toFixed(2) || '0.00';
    }

    get itemFamily() {
        return this.item?.Family__c || 'N/A';
    }

    get itemType() {
        return this.item?.Type__c || 'N/A';
    }

    handleAddToCart() {
        this.dispatchEvent(new CustomEvent('addtocart', {
            detail: { itemId: this.item.Id, itemName: this.item.Name }
        }));

        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: this.item.Name + ' added to cart',
            variant: 'success'
        }));
    }
}