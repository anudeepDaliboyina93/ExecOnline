import { LightningElement,api,wire,track } from 'lwc';
import getOpportunityLineItems from '@salesforce/apex/OpportunityLineItemController.getOpportunityLineItems';

import OPP_NAME from '@salesforce/schema/Opportunity.Name';
import OPP_CLOSEDATE from '@salesforce/schema/Opportunity.CloseDate';

const actions = [
    { label: 'Delete', name: 'delete' }
];

const columns = [
    { label: 'Line Item', fieldName: 'Product_Name__c' },
    { label: 'Sales Price', fieldName: 'UnitPrice', type: 'currency', editable: 'true' },
    {
        type: 'action',
        typeAttributes: { rowActions: actions },
    },
];

export default class OpportunityLineItems extends LightningElement {
    // Exposing fields to make them available in the template
    oppCloseDate = OPP_CLOSEDATE;
    oppName = OPP_NAME;

    @track data = [];
    @track columns = columns;
    @track actions = actions;

    @api recordId;
    @api objectApiName;
    @wire(getOpportunityLineItems, {opportunityId:'$recordId' })
      opportunityLineItems;
    
    handleAdd() {
        // Using immutable data structures. Creating a new array with old and new items instead of mutating the existing array with push()
        this.opportunityLineItems.data = [
            ...this.opportunityLineItems.data,
            {
                Name: 'New Item',
                UnitPrice: 100
            }
        ];
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        switch (actionName) {
            case 'delete':
                this.deleteRow(row);
                break;
            default:
        }
    }

    deleteRow(row) {
        const { id } = row;
        const index = this.findRowIndexById(id);
        if (index !== -1) {
            this.data = this.data
                .slice(0, index)
                .concat(this.data.slice(index + 1));
        }
    }

    findRowIndexById(id) {
        let ret = -1;
        this.data.some((row, index) => {
            if (row.id === id) {
                ret = index;
                return true;
            }
            return false;
        });
        return ret;
    }


}