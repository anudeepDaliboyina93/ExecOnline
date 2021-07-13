import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, updateRecord } from 'lightning/uiRecordApi'
import getIsEpcAdmin from '@salesforce/apex/AccountEpcBalanceController.isEpcAdmin';
import getJsonBalanceLineItemsForAccountId from '@salesforce/apex/AccountEpcBalanceController.getJsonBalanceLineItemsForAccountId';

const ACC_FIELDS = [
    'Account.Finance_Audit_Status__c',
    'Account.Uses_NM_Core__c',
    'Account.EPC_Utilization_Last_Recalc__c',
    'Account.EPCs_Total_Balance__c',
    'Account.EPCs_Total_Reserved__c'
];

const COLUMNS = [
    { label: 'Date', fieldName: 'itemDate', type: 'date-local', fixedWidth: 125 },
    { label: 'Type', fieldName: 'type', type: 'string', fixedWidth: 87 },
    { label: 'Description', fieldName: 'url', type: 'url', 
        typeAttributes: { label: { fieldName: 'description' }, tooltip: { fieldName: 'description' }, target: '_blank' } },
    { label: 'Amount', fieldName: 'displayAmount', type: 'string', fixedWidth: 83 }
];

export default class AccountEpcBalance extends LightningElement {

    @api recordId;
    @api isEpcAdmin;
    @api columns = COLUMNS;
    @api tableData;
    @api showData = false;
    @api showSupportModal = false;
    @api supportComment;
    @api isSubmitPending = false;

    @wire(getIsEpcAdmin)
    wiredIsEpcAdmin({ error, data }) {
        if (data) {
            this.isEpcAdmin = data;
            if(this.columns[this.columns.length-1].label !== 'Ending Balance') {
                this.columns.push({ label: 'Ending Balance', fieldName: 'displayBalance', type: 'string', fixedWidth: 130 });
            }
        }
    }

    @wire(getRecord, { recordId : '$recordId', fields : ACC_FIELDS })
    account;

    get usesNmCore() {
        return this.account.data.fields.Uses_NM_Core__c.value;
    }
    get currentEpcBalance() {
        return this.account.data.fields.EPCs_Total_Balance__c.value;
    }
    get reservedEpcs() {
        return this.account.data.fields.EPCs_Total_Reserved__c.value;
    }
    get financeAuditStatus() {
        return this.account.data.fields.Finance_Audit_Status__c.value;
    }
    get epcCalcDate() {
        return this.formatDate(new Date(this.account.data.fields.EPC_Utilization_Last_Recalc__c.value));
    }
    get auditIsCompleteClass() {
        if(this.account.data.fields.Finance_Audit_Status__c.value === 'Complete') {
            return 'audit-complete slds-p-around_small'; 
        }
        return 'audit-pending slds-p-around_small';
    }

    @wire(getJsonBalanceLineItemsForAccountId, { accountId : '$recordId' }) wiredContent({error, data}) {
        if (data) {
            this.tableData = JSON.parse(data);
        } else if (error) {
            console.log('error: ', error);
        }
    };

    get submitSupportLabel() {
        if(this.isSubmitPending) {
            return 'Sending...';
        }
        return 'Submit';
    }

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
        fields['EPC_Balance_Comment__c'] = this.supportComment;
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

    get toggleShowDataIcon() {
        if(this.showData) {
            return 'utility:hide';
        }
        return 'utility:preview';
    }

    get toggleShowDataLabel() {
        if(this.showData) {
            return 'Hide Details';
        }
        return 'Show Details';
    }

    toggleShowData() {
        this.showData = !this.showData;
    }

    formatDate(date) {
        var hours = date.getHours();
        var minutes = date.getMinutes();
        var ampm = hours >= 12 ? 'PM' : 'AM';
        hours = hours % 12;
        hours = hours ? hours : 12; // the hour '0' should be '12'
        minutes = minutes < 10 ? '0'+minutes : minutes;
        var strTime = hours + ':' + minutes + ' ' + ampm;
        return date.getMonth()+1 + "/" + date.getDate() + "/" + date.getFullYear() + " " + strTime;
    }

}