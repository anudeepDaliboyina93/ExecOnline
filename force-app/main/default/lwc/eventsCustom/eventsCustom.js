import { LightningElement, wire, api, track } from 'lwc';
import getEvents from '@salesforce/apex/EventAdmin.getEvents';
import deleteEvent from '@salesforce/apex/EventAdmin.deleteEvent';
import manageEvent from '@salesforce/apex/EventAdmin.manageEvent';
import getEventStatusOptions from '@salesforce/apex/ApexUtility.getPicklistOptions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const actions = [
    {label: 'Manage', name: 'manage'},
    { label: 'Delete', name: 'delete' }
];

const columns = [
    
    { label: 'Date', type:'date-local', fieldName: 'ActivityDate' },
    { label: 'Subject', fieldName: 'Subject' },
    { label: 'Status', fieldName: 'Status__c'},
    { type: 'action', typeAttributes: { rowActions: actions, menuAlignment: 'auto' } }
    
];

export default class EventsCustom extends LightningElement {

    @api recordId;
    error;
    columns = columns;
    events;
    refreshEvents;
    showModal = false;
    showDeleteModal = false;
    @track refreshEventStatusOptions;
    @track eventOptions = [];
    isLoading = false;
    currentEventId;
    notes;
    currentEventStatus;
    currentActivityDate

    closeDeleteModal(){
        this.showDeleteModal= false;
    }

    closeModal (){

        this.showModal = false;
    }

    openModal (){
        this.showModal = true;
    }


    @wire(getEvents, { oppId: '$recordId'})
    eventsRecords(result) {
        this.refreshEvents = result;
        if (result.data) {
            this.events = result.data;
            console.log(this.events);

        }
    }

    @wire(getEventStatusOptions, { customObjInfo: {'sobjectType' : 'Event'},
    selectPicklistApi: 'Status__c'})
        statusOptions(result) {
            this.refreshEventStatusOptions = result;
            if (result.data) {
                console.log(result.data);
                this.eventOptions = [];
                
                 var eventStatuses = result.data
                          for(const list of eventStatuses){
                            const option = {
                                label: list.label,
                                value: list.value
                            };
                            // this.selectOptions.push(option);
                            this.eventOptions = [ ...this.eventOptions, option ];
                            console.log(option);
                        }  
            }
    
        }

    deleteEvent() {
        this.isLoading = true;
        console.log(this.currentEventId);
        deleteEvent({ eventId: this.currentEventId})
.then(result => {
    this.deletedEvent = result;

    const event = new ShowToastEvent({
        title: 'Event Deleted!',
        message: 'The event has been deleted',
        variant: 'Success'
    });
    this.dispatchEvent(event);
    this.isLoading = false;
    this.showDeleteModal = false;
    this.refresh();
 
})
.catch(error => {
    this.error = error;
    console.log(error)

    const event = new ShowToastEvent({
        title: 'Error!',
        message: 'The record could not be deleted! ' + String(error),
        variant: 'Error'
    });
    this.dispatchEvent(event);
});
    }
 
    handleRowAction(event) {
        const action = event.detail.action;
        this.currentEventId = event.detail.row.Id;
        this.eventStatus = event.detail.row.Status__c;
        this.notes = event.detail.row.Description;
        this.currentActivityDate = event.detail.row.ActivityDate;
        console.log(this.currentActivityDate);
        switch (action.name) {
            case 'delete':
          this.showDeleteModal = true;
                break;
        case 'manage':
            const row = event.detail.value;
            this.showModal = true;
                break;
 }
}

saveEvent() {
        this.isLoading = true;
        manageEvent({ eventId: this.currentEventId,
                      status: this.eventStatus,
                      notes: this.notes })
            .then(result => {
                this.eventResult = result;
    
                const event = new ShowToastEvent({
                    title: 'Event Updated!',
                    message: 'The event updated successfully!',
                    variant: 'Success'
                });
                this.dispatchEvent(event);
                this.isLoading = false;
                this.refresh();
             
            })
            .catch(error => {
                this.error = error;

                const event = new ShowToastEvent({
                    title: 'Error!',
                    message: 'The records you selected had an error! ' + String(error),
                    variant: 'Error'
                });
                this.dispatchEvent(event);
            });
}

handleStatusChange(event){
    this.eventStatus = event.detail.value;
    console.log(this.eventStatus);
}

handleCurrentEventNotes(event) {
    this.notes = event.detail.value;
}

refresh() {
   this.showModal = false;
   this.eventStatus = undefined;
   this.notes = undefined;
    return refreshApex(this.refreshEvents)
 
 }

}