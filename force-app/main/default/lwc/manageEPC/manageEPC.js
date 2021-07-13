import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi'
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class manageEPC extends LightningElement {

    @api recordId;
    showSupportModal = false;
    supportComment;
    isSubmitPending = false;
    submitSupportLabel = 'Submit';
    
    handleRequestSupport() {
        this.showSupportModal = true;
    }

    closeModal() {
        this.showSupportModal = false;
        this.template.querySelectorAll('lightning-textarea').forEach(each => {
            each.value = undefined;
        });
        this.supportComment = '';
        this.isSubmitPending = false;
    }

    handleSupportCommentChange(evt) {
        this.supportComment = evt.target.value;
    }

    submitSupportRequest() {
        this.isSubmitPending = true;
        const fields = {};
        fields['Id'] = this.recordId;
        fields['Request_Support__c'] = true;
        fields['Manage_EPC_Comment__c'] = this.supportComment;
        const recordInput = { fields };
        
        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Support requested!',
                        variant: 'success'
                    })
                );
                this.closeModal();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error requesting support',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
                this.closeModal();
            });
    }

}