import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation'

import getMyEvents from '@salesforce/apex/MyEventsController.getMyEvents';
import setEventStatus from '@salesforce/apex/MyEventsController.setEventStatus';

export default class MyEvents extends NavigationMixin(LightningElement) {

    @track myEvents;

    @wire(getMyEvents)
    getEvents({ error, data }) {
        if (error) {
            console.log(JSON.stringify(error));
        } else if(data) {
            this.addRightNowToEventsList(data);
        }
    }

    addRightNowToEventsList = (data) => {
        let myEvents = [];
        let rightNow = new Date().getTime();
        let prevEventStartTime;
        for(let i=0; i<data.length; i++) {
            let event = Object.assign({}, data[i]);
            let eventStartTime = new Date(event.ActivityDateTime).getTime();
            event.isFutureEvent = rightNow < eventStartTime;
            event.cssClass = this.getCssClasses(event);
            event.iconName = this.getIconName(event.Status__c);

            if(eventStartTime < rightNow && (i===0 || rightNow < prevEventStartTime )) {
                myEvents.push({ ActivityDateTime: rightNow, Subject: 'Right now', cssClass: 'right-now slds-text-title_caps' });
            }

            myEvents.push(event);
            prevEventStartTime = eventStartTime;
        }
        this.myEvents = myEvents;
    }

    getIconName = (status) => {
        switch (status) {
            case 'Completed':
                return 'utility:check';
            case 'Scheduled':
                return 'utility:clock';
            case 'Canceled': 
                return 'utility:close';
            default:
                return null;
        }
    }

    getCssClasses = (event) => {
        let cssClass = '';
        cssClass += event.isFutureEvent ? 'in-future' : 'in-past';
        cssClass += event.Status__c === 'Scheduled' ? ' scheduled' : ' not-scheduled';
        return cssClass;
    }

    handleCompleteClick = (event) => {
        let eventId = event.target.getAttribute('data-event-id');
        this.updateEvent(eventId, 'Completed');
    }

    handleCancelClick = (event) => {
        let eventId = event.target.getAttribute('data-event-id');
        this.updateEvent(eventId, 'Canceled');
    }

    updateEvent = (eventId, eventStatus) => {
        this.setEventIsSaving(eventId);
        
        setEventStatus({eventId: eventId, status: eventStatus})
            .then((result) => {
                console.log(JSON.stringify(result));
                this.setEventIsSaved(eventId, eventStatus);
            })
            .catch(error => {
                console.log(JSON.stringify(error));
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Did not update event. ' + error.body.pageErrors[0].message,
                        variant: 'error'
                    })
                );
            });
    }

    setEventIsSaving = (eventId) => {
        let myEvents = [...this.myEvents];
        for(let i=0; i<myEvents.length; i++) {
            if(myEvents[i].Id === eventId) {
                myEvents[i].isSaving = true;
                break;
            }
        }
        this.myEvents = myEvents;
    }

    setEventIsSaved = (eventId, eventStatus) => {
        let myEvents = [...this.myEvents];
        for(let i=0; i<myEvents.length; i++) {
            if(myEvents[i].Id === eventId) {
                myEvents[i].isSaving = false;
                myEvents[i].Status__c = eventStatus;
                myEvents[i].cssClass = this.getCssClasses(myEvents[i]);
                myEvents[i].iconName = this.getIconName(myEvents[i].Status__c);
                break;
            }
        }
        this.myEvents = myEvents;
    }

    navigateToEvent = (event) => {
        let eventId = event.target.getAttribute('data-event-id');
        if(eventId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    "recordId": eventId,
                    "objectApiName": "Event",
                    "actionName": "view"
                }
            }, true);
        }
    }

}