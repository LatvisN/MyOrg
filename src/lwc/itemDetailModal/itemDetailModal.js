import { LightningElement, api } from 'lwc';

export default class ItemDetailModal extends LightningElement {
    @api item;

    get itemName() {
        return this.item?.Name__c || this.item?.Name || 'Unknown Item';
    }

    get formattedPrice() {
        return this.item?.Price__c?.toFixed(2) || '0.00';
    }

    get description() {
        return this.item?.Description__c || 'No description available';
    }

    get hasImage() {
        return this.item?.Image__c ? true : false;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleAddToCart() {
        this.dispatchEvent(new CustomEvent('addtocart', {
            detail: { item: this.item }
        }));
        this.handleClose();
    }
}