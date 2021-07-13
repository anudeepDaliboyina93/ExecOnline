import { LightningElement, track, api} from 'lwc';
import findContacts from '@salesforce/apex/readOnlyController.findContacts';
import setReadAccess from '@salesforce/apex/readOnlyController.setReadAccess';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class ContactReadOnly extends NavigationMixin(LightningElement) {

    handleSearch(event) {
        const lookupElement = event.target;
        findContacts(event.detail)
            .then(results => {
                lookupElement.setSearchResults(results);
                console.log('called apex successful');
            })
            .catch(error => {
                // TODO: handle error
            });
    }

    handleSelectionChange(event) {
        // Get the selected ids from the event (same interface as lightning-input-field)
        const selectedIds = event.detail;
        // Or, get the selection objects with ids, labels, icons...
        const selection = event.target.getSelection();
        // TODO: do something with the lookup selection
    }

    handleSelected(event){
       const contactId = event.detail.recordId;

       setReadAccess({ contactId: contactId})
        .then(result => {

            const event = new ShowToastEvent({
                title: 'Read access granted!',
                message: 'Read access granted!',
                variant: 'Success'
            });
            this.dispatchEvent(event);
         
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: contactId,
                    objectApiName: 'Contact',
                    actionName: 'view'
                },
            });

        })
        .catch(error => {
            this.error = error;
            console.log(error)

            const event = new ShowToastEvent({
                title: 'Error!',
                message: 'The record you selected had an error! ' + String(error),
                variant: 'Error'
            });
            this.dispatchEvent(event);
        });
    }
}