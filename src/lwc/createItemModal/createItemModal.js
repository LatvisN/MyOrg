import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createItem from '@salesforce/apex/ItemController.createItem';

export default class CreateItemModal extends LightningElement {
    @api familyOptions = [];
    @api typeOptions = [];

    itemName = '';
    description = '';
    family = '';
    itemType = '';
    price = 0;
    isLoading = false;

    get isButtonDisabled() {
        return this.isLoading || !this.itemName || !this.family || !this.itemType || this.price <= 0;
    }

    handleNameChange(event) {
        this.itemName = event.target.value;
    }

    handleDescriptionChange(event) {
        this.description = event.target.value;
    }

    handleFamilyChange(event) {
        this.family = event.detail.value;
    }

    handleTypeChange(event) {
        this.itemType = event.detail.value;
    }

    handlePriceChange(event) {
        this.price = parseFloat(event.target.value) || 0;
    }

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    async handleCreate() {
        if (!this.itemName || !this.family || !this.itemType || this.price <= 0) {
            this.showToast('Error', 'Please fill in all required fields', 'error');
            return;
        }

        this.isLoading = true;

        try {
            console.log('Creating item:', this.itemName);

            const newItem = await createItem({
                name: this.itemName,
                description: this.description,
                itemType: this.itemType,
                family: this.family,
                price: this.price
            });

            console.log('Item created:', newItem);

            this.showToast('Success', `${this.itemName} created successfully!`, 'success');

            this.dispatchEvent(new CustomEvent('itemcreated', {
                detail: { item: newItem }
            }));

            this.handleClose();

        } catch (error) {
            console.error('Error creating item:', error);
            this.showToast('Error', error.body?.message || 'Failed to create item', 'error');
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}