import { LightningElement, api, track, wire } from 'lwc';
import getApprovedStudents from '@salesforce/apex/ManageEPCController.studentsTree';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import {
    subscribe,
    unsubscribe,
    APPLICATION_SCOPE,
    MessageContext
} from 'lightning/messageService';
import treeGridMC from "@salesforce/messageChannel/TreeGridChannel__c";

export default class ApprovedEpc extends NavigationMixin(LightningElement) {
    refreshApex;
    subscription = null;

    @api recordId;
    @track refreshTree;
    @track treeItems;
    @track studentsApproved;
    @track baseClassName = '';
    @track expanded;
    @track rowToExpand;
    @track recordIdList = new Array();
    @track showApproveButton = false;
    @track showNotes = false;
    @track rowStatus = "closed";
    @track totalEPCApproved = 0;
    @track particpantCountApproved = 0;
    @track currentOpenRowAction;
    @api selectedOppId;
    @track currentOppName;
    @track currentStudentId;
    @track showOverrideModal = false;
    @track showApproveButton = false;
    @track preparedStudents;
    @track currentStudentId;
    @track EPC;
    @track currentStudentName;
    @track currentChildren = new Array();
    @track showTags = false;
    @track studentTagJson = {};
    @track refreshTreeDateChanged;
    @api startDate = null;
    @api endDate = null;
    @track isLoading = false;
    @track notes;
    @track compedReason

    @track page = 1; //this will initialize 1st page
    @track items = []; //it contains all the records.
    @track data = []; //data to be displayed in the table
    @track columns; //holds column info.
    @track startingRecord = 1; //start record position per page
    @track endingRecord = 0; //end record position per page
    @track pageSize = 10; //default value we are assigning
    @track totalRecountCount = 0; //total record count received from all retrieved records
    @track totalPage = 0; //total number of page is needed to display all records
    showPagination = false;
    hasRendered = false;
    showTotals = false;
    totalAddOn = 0;
    totalProgram = 0;
    totalProgramRounded = 0;
    totalAddOnRounded = 0;

    jsonForWireApproved = {};
    @api approvedToParse;

    renderedCallback(){

        if (!this.hasRendered){
            this.hasRendered = true;
            this.createJsonForWireApproved();
        }
    }

    createJsonForWireApproved(){

        this.jsonForWireApproved = {};

        this.jsonForWireApproved.accountId = this.recordId;
        this.jsonForWireApproved.approval = true;
        this.jsonForWireApproved.startDate = this.startDate;
        this.jsonForWireApproved.endDate = this.endDate;

        this.approvedToParse = JSON.stringify(this.jsonForWireApproved);
    }

    handleStudentNav(event) {
        console.log(event.currentTarget.dataset.value);
        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: event.currentTarget.dataset.value,
                objectApiName: 'Student__c',
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }

    handleOppNav(event) {
        console.log(event.currentTarget.dataset.value);
        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: event.currentTarget.dataset.value,
                objectApiName: 'Opportunity',
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });
    }

    @wire(MessageContext)
    messageContext;


    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                treeGridMC,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }


    handleMessage(message) {
        if (message.refreshApex == 'true'){
            this.refresh();
        } 
    }

 
    connectedCallback() {
        this.subscribeToMessageChannel();
    }

    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }

    openUnapprovedModal() {
        this.showOverrideModal = true;
    }
    closeUnapprovedModal() {
        this.showOverrideModal = false;
        this.showNotes = false;
    } 

    handleExpandCollapse(event){

      
      this.rowToExpand = event.currentTarget.getAttribute("data-target-id");
      const treeChildren = this.template.querySelectorAll(`[data-child-id="${this.rowToExpand}"]`);
      this.expanded = event.currentTarget.getAttribute("aria-expanded");
      console.log(this.rowToExpand);
      console.log(this.expanded);

      if (this.expanded == "false"){

        this.expanded = true;
      }

      else {
          this.expanded = false;
      }
      console.log(this.expanded);

      var row = this.template.querySelector(`[data-id="${this.rowToExpand}"]`);

     if (row){
        row.setAttribute("aria-expanded", this.expanded);
        event.currentTarget.setAttribute("aria-expanded", this.expanded);
     }

     for (var i = 0; i < treeChildren.length; i++){
         if (this.expanded == true){
             treeChildren[i].className='slds-hint-parent';
         }
         else {
             treeChildren[i].className='slds-hint-parent slds-hide'
         }
     }
    
    }

    @wire(getApprovedStudents, { jsonStringToParse: '$approvedToParse'})
    approvedStudentsData(result) {
        this.isLoading = true;
        this.refreshTreeApproved = result;
        if (result.data) {
            this.studentsApproved = [];
            this.items = [];
            this.isLoading = false;
            var data = result.data
            this.totalEPCApproved = 0;
            this.particpantCountApproved = 0;
            this.totalProgram = 0;
            this.totalAddOn = 0;
            console.log(data);
            var tempjson = JSON.parse(JSON.stringify(data).split('epcuis').join('_children'));
            console.log(tempjson);
            this.studentsApproved = tempjson;
            console.log(JSON.stringify(tempjson, null, '\t'));

               this.items = tempjson;
               this.totalRecountCount = result.data.length;
               this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);

               this.studentsApproved = this.items.slice(0,this.pageSize);

               this.endingRecord = this.totalRecountCount < this.pageSize ? this.totalRecountCount : this.pageSize;
           
               //tempjson = undefined;
               console.log(this.studentsApproved.length);
               this.showPagination = this.studentsApproved.length > 0 ? true : false;

        
console.log(this.studentsApproved.length);
console.log(this.studentsApproved.length > 0);
            this.showPagination = this.studentsApproved.length > 0 ? true : false;
            
            for (let i = 0; i < data.length; i++){
             if (data[i].EPC || data[i].tagOnly){

                 this.particpantCountApproved = this.particpantCountApproved + 1;

                 data[i].epcuis.forEach(epcu =>{

                    this.totalEPCApproved = this.totalEPCApproved + epcu.EPC;

                    if (!epcu.tag){
                        this.totalProgram = this.totalProgram + epcu.EPC
                       }

                       else {
                           this.totalAddOn = this.totalAddOn + epcu.EPC;
                       }

                 })

             }

             

             if (data[i].isAEP){
                this.particpantCountApproved = this.particpantCountApproved + 1;
            }
         }

         console.log(this.totalEPCApproved);
         this.totalProgramRounded       = (Math.round(this.totalProgram * 100) / 100).toFixed(2);
            this.totalAddOnRounded         = (Math.round(this.totalAddOn * 100) / 100).toFixed(2);
         this.totalEPCApprovedRounded = (Math.round(this.totalEPCApproved * 100) / 100).toFixed(2);
            console.log(this.studentsApproved);
        }

    }

    handleDropRowActions(event){

        const rowActions = event.currentTarget.getAttribute("data-row-id");
        const rowStatus = event.currentTarget.getAttribute("data-row-status");
        var row = this.template.querySelector(`[data-rowaction-id="${rowActions}"]`);

        if (rowStatus == "closed"){
            event.currentTarget.setAttribute("data-row-status", "open");
            row.className ='slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open'
            this.currentOpenRowAction = rowActions;
        }
        else {
            event.currentTarget.setAttribute("data-row-status", "closed");
            row.className ='slds-dropdown-trigger slds-dropdown-trigger_click slds-is-closed'
           
        }
        console.log(row);
        
    }

    handleRowAction(event) {

        this.showTags = false;
        const row = event.detail.value;

        console.log(row._children);

        for (let i = 0; i < row._children.length; i++){
            if (row._children[i].tag == true){
                this.showTags = true;
                
            }
            else {
                this.EPC = row.EPC;
                this.currentEPCUtilized = row.EPC;
            }
        }
       
                this.currentChildren = row._children;
                this.showOverrideModal = true;
                this.currentOppName = row.oppName;
                this.currentStudentId = row.StudentId;
                this.selectedOppId = row.OppId;
                this.notes = row.notes;
                this.compedReason = row.compedCategory;
                
                
                this.currentStudentName = row.name;
                
                if (this.compedReason != null){
                    this.showCompOptions = true;
                    if (this.compedReason == 'Other' || this.notes != null){
                        this.showNotes = true;

                    }
                }
                else {
                    this.showCompOptions = false
                    this.showNotes = false;
                }
                console.log(JSON.stringify(row));

}

handleShowTotals(event){
    this.showTotals = !this.showTotals;
}


handleDateChange(event) {

    const inputType = event.currentTarget.getAttribute("data-id");

    switch (inputType) {
        case 'startDate': {

            this.startDate = event.detail.value;
            console.log(this.startDate);
            break;
        }
        case 'endDate': {

            this.endDate = event.detail.value;
            console.log(this.endDate);

            if (this.startDate > this.endDate){
                const event = new ShowToastEvent({
                    title: 'Error!',
                    message: 'The end date must be after the start date! ',
                    variant: 'Error'
                });
                this.dispatchEvent(event);
                const dateElement = this.template.querySelector('.endDate');

                dateElement.value = '';
                
            }

            else {
                this.isLoading = true;
                this.createJsonForWireApproved();
                refreshApex(this.refreshTreeApproved);
                this.isLoading = false;
                return 

            }

            break;
        } 
    }
    console.log(inputType);

}

refresh() {
    this.currentStudentId = undefined;
    this.selectedOppId = undefined;
    this.page = 1; //this will initialize 1st page
    this.items = undefined; //it contains all the records.
    this.data = undefined; //data to be displayed in the table
    this.columns; //holds column info.
    this.startingRecord = 1; //start record position per page
    this.endingRecord = 0; //end record position per page
    this.pageSize = 10; //default value we are assigning
    this.totalRecountCount = 0; //total record count received from all retrieved records
    this.totalPage = 0;
    return refreshApex(this.refreshTreeApproved);
 }


 previousHandler() {
    if (this.page > 1) {
        this.page = this.page - 1; 
        this.displayRecordPerPage(this.page);
    }
}


nextHandler() {
    if((this.page<this.totalPage) && this.page !== this.totalPage){
        this.page = this.page + 1; 
        this.displayRecordPerPage(this.page);            
    }             
}


displayRecordPerPage(page){

    this.startingRecord = ((page -1) * this.pageSize) ;
    this.endingRecord = (this.pageSize * page);

    this.endingRecord = (this.endingRecord > this.totalRecountCount) 
                        ? this.totalRecountCount : this.endingRecord; 

    this.studentsApproved = this.items.slice(this.startingRecord, this.endingRecord);

    this.startingRecord = this.startingRecord + 1;
}   

handlemouseup(e) {
    this._tableThColumn = undefined;
    this._tableThInnerDiv = undefined;
    this._pageX = undefined;
    this._tableThWidth = undefined;
}

handlemousedown(e) {
    if (!this._initWidths) {
        this._initWidths = [];
        let tableThs = this.template.querySelectorAll("table thead .dv-dynamic-width");
        tableThs.forEach(th => {
            this._initWidths.push(th.style.width);
        });
    }

    this._tableThColumn = e.target.parentElement;
    this._tableThInnerDiv = e.target.parentElement;
    while (this._tableThColumn.tagName !== "TH") {
        this._tableThColumn = this._tableThColumn.parentNode;
    }
    while (!this._tableThInnerDiv.className.includes("slds-cell-fixed")) {
        this._tableThInnerDiv = this._tableThInnerDiv.parentNode;
    }
    console.log("handlemousedown this._tableThColumn.tagName => ", this._tableThColumn.tagName);
    this._pageX = e.pageX;

    this._padding = this.paddingDiff(this._tableThColumn);

    this._tableThWidth = this._tableThColumn.offsetWidth - this._padding;
    console.log("handlemousedown this._tableThColumn.tagName => ", this._tableThColumn.tagName);
}

handlemousemove(e) {
    console.log("mousemove this._tableThColumn => ", this._tableThColumn);
    if (this._tableThColumn && this._tableThColumn.tagName === "TH") {
        this._diffX = e.pageX - this._pageX;

        this.template.querySelector("table").style.width = (this.template.querySelector("table") - (this._diffX)) + 'px';

        this._tableThColumn.style.width = (this._tableThWidth + this._diffX) + 'px';
        this._tableThInnerDiv.style.width = this._tableThColumn.style.width;

        let tableThs = this.template.querySelectorAll("table thead .dv-dynamic-width");
        let tableBodyRows = this.template.querySelectorAll("table tbody tr");
        let tableBodyTds = this.template.querySelectorAll("table tbody .dv-dynamic-width");
        tableBodyRows.forEach(row => {
            let rowTds = row.querySelectorAll(".dv-dynamic-width");
            rowTds.forEach((td, ind) => {
                rowTds[ind].style.width = tableThs[ind].style.width;
            });
        });
    }
}

handledblclickresizable() {
    let tableThs = this.template.querySelectorAll("table thead .dv-dynamic-width");
    let tableBodyRows = this.template.querySelectorAll("table tbody tr");
    tableThs.forEach((th, ind) => {
        th.style.width = this._initWidths[ind];
        th.querySelector(".slds-cell-fixed").style.width = this._initWidths[ind];
    });
    tableBodyRows.forEach(row => {
        let rowTds = row.querySelectorAll(".dv-dynamic-width");
        rowTds.forEach((td, ind) => {
            rowTds[ind].style.width = this._initWidths[ind];
        });
    });
}

paddingDiff(col) {
 
    if (this.getStyleVal(col, 'box-sizing') === 'border-box') {
        return 0;
    }

    this._padLeft = this.getStyleVal(col, 'padding-left');
    this._padRight = this.getStyleVal(col, 'padding-right');
    return (parseInt(this._padLeft, 10) + parseInt(this._padRight, 10));

}

getStyleVal(elm, css) {
    return (window.getComputedStyle(elm, null).getPropertyValue(css))
}

}