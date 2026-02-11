import { LightningElement, api } from 'lwc';

export default class CartModal extends LightningElement {
    @api cartItems = [];

    get hasItems() {
        return this.cartItems && this.cartItems.length > 0;
    }

    get isCartEmpty() {
        return !this.hasItems;
    }

    get totalItems() {
        return this.cartItems.reduce((sum, item) => sum + item.amount, 0);
    }

    get grandTotal() {
        const total = this.cartItems.reduce((sum, item) => sum + (item.unitCost * item.amount), 0);
        return total.toFixed(2);
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleCheckout() {
        this.dispatchEvent(new CustomEvent('checkout'));
    }
}