import { LightningElement, api, track, wire } from 'lwc';
import studentsNeedApproval from '@salesforce/apex/ManageEPCController.studentsTree';
import approveStudentRecords from '@salesforce/apex/ManageEPCController.approveRecords';
import getOpps from '@salesforce/apex/ManageEPCController.getOpps';
import saveStudentRecords from '@salesforce/apex/ManageEPCController.saveStudent';
import getCompedReasonOptions from '@salesforce/apex/ApexUtility.getPicklistOptions';
import getTagCompedReasonOptions from '@salesforce/apex/ApexUtility.getPicklistOptions';
import canEdit from '@salesforce/apex/ManageEPCController.canEdit';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import { publish, MessageContext } from 'lightning/messageService';
import treeGridMC from "@salesforce/messageChannel/TreeGridChannel__c";

export default class UnapprovedEpc extends NavigationMixin(LightningElement) {
    @api recordId;
    @track refreshTree;
    @track treeItems = [];
    @track expanded;
    @track rowToExpand;
    @track recordIdList = new Array();
    @track showNotes = false;
    @track rowStatus = "closed";
    @track totalEPCUnapproved = 0;
    @track totalEPCUnapprovedRounded;
    @track particpantCountUnapproved = 0;
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
    @track oppOptions = new Array();
    @track currentChildren = new Array();
    @track showTags = false;
    @track studentTagJson = {};
    @track refreshTreeDateChanged;
    @api startDate = null;
    @api endDate = null;
    @track isLoading = false;
    @track notes;
    @track showCompOptions;
    @track showCompOptionsAddOn;
    @track compedReason
    @track compedOptions;
    @track refreshcompReasons;
    studentUrl;
    currentOpp;
    override = false;
    isModalLoading = false;
    isEpcAdmin = false;
    showTotals = false;
    totalAddOn = 0;
    totalProgram = 0;
    totalProgramRounded = 0;
    totalAddOnRounded = 0;

    fixedWidth = "width:15rem;";
    @track page = 1; //this will initialize 1st page
    @track items = []; //it contains all the records.
    @track data = []; //data to be displayed in the table
    @track columns; //holds column info.
    @track startingRecord = 1; //start record position per page
    @track endingRecord = 0; //end record position per page
    @track pageSize = 10; //default value we are assigning
    @track totalRecountCount = 0; //total record count received from all retrieved records
    @track totalPage = 0; //total number of page is needed to display all records
    fixedWidth = "width:15rem;";
    showPagination = false;
    hasRendered = false;
    jsonForWirePending = {};
    @api pendingToParse;
    tagNotes;
    compedTagReason;
    showTagNotes = false;

    renderedCallback(){

        if (!this.hasRendered){
            this.hasRendered = true;
            this.createJsonForWirePending();
        }
    }

    createJsonForWirePending(){

        this.jsonForWirePending = {};

        this.jsonForWirePending.accountId = this.recordId;
        this.jsonForWirePending.approval = false;
        this.jsonForWirePending.startDate = this.startDate;
        this.jsonForWirePending.endDate = this.endDate;

        this.pendingToParse = JSON.stringify(this.jsonForWirePending);
    }

    @wire(canEdit, {accountId: '$recordId'}) isEpcAdmin;

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
    

    @wire(getCompedReasonOptions, { customObjInfo: {'sobjectType' : 'Student__c'},
    selectPicklistApi: 'Comped_Reason_Category__c'})
        compedReasons(result) {
            this.refreshcompReasons = result;
            if (result.data) {
                this.compedOptions = [];
                
                 var compedReasons = result.data
                          for(const list of compedReasons){
                            const option = {
                                label: list.label,
                                value: list.value
                            };
                            // this.selectOptions.push(option);
                            this.compedOptions = [ ...this.compedOptions, option ];
                            console.log(option);
                        }  
            }
    
        }

        @wire(getTagCompedReasonOptions, { customObjInfo: {'sobjectType' : 'EPC_Utilization_Item__c'},
        selectPicklistApi: 'Comped_Reason_Category__c'})
            compedTagReasons(result) {
                this.refreshcompReasons = result;
                if (result.data) {
                    this.compedOptions = [];
                    
                     var compedReasons = result.data
                              for(const list of compedReasons){
                                const option = {
                                    label: list.label,
                                    value: list.value
                                };
                                // this.selectOptions.push(option);
                                this.compedOptions = [ ...this.compedOptions, option ];
                                console.log(option);
                            }  
                }
        
            }

handleChangeCompedReason(event){
    this.compedReason = event.target.value;

    if (this.compedReason == 'Other'){
        this.showNotes = true;
    }
    else if(this.notes == null && this.compedReason != 'Other'|| this.notes == '' && this.compedReason != 'Other'){
        this.showNotes = false;
    }

}

handleChangeTagCompedReason(event){
    this.compedTagReason = event.target.value;

    if (this.compedTagReason == 'Other'){
        this.showTagNotes = true;
    }
    else if(this.tagNotes == null && this.compedTagReason != 'Other'|| this.tagNotes == '' && this.compedTagReason != 'Other'){
        this.showTagNotes = false;
    }

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

    selectAllApprove(event){
        this.recordIdList = new Array();
        let checkboxes = this.template.querySelectorAll('[data-id="checkbox"]')
        for(let i=0; i<checkboxes.length; i++) {
            checkboxes[i].checked = event.target.checked;

            if (event.target.checked == true){
                this.showApproveButton = true;
                this.recordIdList.push(checkboxes[i].getAttribute("data-checkbox-id"));
            }

            else {
                this.showApproveButton = false;
            }
        }

        console.log(this.recordIdList);
    }

    handleApprovePrep(event){
        this.recordIdList = new Array();
        let row = event.target.value;
        console.log(row);

        const rows = this.template.querySelectorAll('[data-id="checkbox"]')

        for (var i = 0; i < rows.length; i++){
            
            if (rows[i].checked == true){
                this.recordIdList.push(rows[i].getAttribute("data-checkbox-id"));
            }
        }

        if (this.recordIdList.length > 0){
            this.showApproveButton = true;
        }

        else {
            this.showApproveButton = false;
        }
        console.log(this.recordIdList);
    }
       
    handleApprove() {
        console.log(this.recordIdList);
        this.isLoading = true;
        approveStudentRecords({ studentIds: this.recordIdList })
            .then(result => {
                this.contacts = result;
    
                const event = new ShowToastEvent({
                    title: 'Records Approved!',
                    message: 'The records you selected were approved!',
                    variant: 'Success'
                });
                this.dispatchEvent(event);
                this.isLoading = false;
                this.showApproveButton = false;
                this.recordIdList = undefined;
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

    handleGetOpps() {
        
        getOpps({ accountId: this.recordId })
            .then(result => {
                this.refreshOpps = result;
                this.oppOptions = [];
                
                       //  alert(data);
                       var opps = result
                      for(const list of opps){
                        const option = {
                            label: list.OppName + ': ' + 'EPC Available ' + list.EPCLeft,
                            value: list.OppId
                        };
                        // this.selectOptions.push(option);
                        this.oppOptions = [ ...this.oppOptions, option ];
                        console.log(option);
                    }
                
             console.log(this.oppOptions);
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

   @wire(studentsNeedApproval, { jsonStringToParse: '$pendingToParse'})
    students(result) {
        this.isLoading = true;
        this.refreshTree = result;
        if (result.data) {
               this.items = [];
               this.treeItems = [];
               var data = result.data;
               this.isLoading = false;
               this.totalEPCUnapproved = 0;
               this.particpantCountUnapproved = 0;
               this.totalProgram = 0;
               this.totalAddOn = 0;
               var tempjson = JSON.parse(JSON.stringify(data).split('epcuis').join('_children'));
              // this.treeItems = tempjson;

               this.items = tempjson;
               this.totalRecountCount = result.data.length;
               this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);

               this.treeItems = this.items.slice(0,this.pageSize);

               this.endingRecord = this.totalRecountCount < this.pageSize ? this.totalRecountCount : this.pageSize;
           
               //tempjson = undefined;
               console.log(this.treeItems.length);
               this.showPagination = this.treeItems.length > 0 ? true : false;

               for (let i = 0; i < data.length; i++){
                  
                if (data[i].EPC || data[i].tagOnly == true){

                    this.particpantCountUnapproved = this.particpantCountUnapproved + 1;
   
                    data[i].epcuis.forEach(epcu =>{
   
                       this.totalEPCUnapproved = this.totalEPCUnapproved + epcu.EPC;
                       
                       if (!epcu.tag){
                        this.totalProgram = this.totalProgram + epcu.EPC
                       }

                       else {
                           this.totalAddOn = this.totalAddOn + epcu.EPC;
                       }
   
                    })
   
                }
console.log(data[i].isAEP);
                if (data[i].isAEP){
                    this.particpantCountUnapproved = this.particpantCountUnapproved + 1;
                }
            }

            this.totalProgramRounded       = (Math.round(this.totalProgram * 100) / 100).toFixed(3);
            this.totalAddOnRounded         = (Math.round(this.totalAddOn * 100) / 100).toFixed(3);
            this.totalEPCUnapprovedRounded = (Math.round(this.totalEPCUnapproved * 100) / 100).toFixed(3);
   
        }

        else {
            this.isLoading = false;
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

                this.currentEPCUtilized = this.currentEPCUtilized == undefined ? 0 : this.currentEPCUtilized;
       
                this.currentChildren = row._children;
                this.showOverrideModal = true;
                this.currentOppName = row.oppName;
                this.currentStudentId = row.StudentId;
                this.currentOpp = row.OppId;
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
                this.handleGetOpps();
                
 
}

handleShowTotals(event){
    this.showTotals = !this.showTotals;
}

handleChange(event) {

    this.selectedOppId = event.detail.value;
    if (this.selectedOppId != this.currentOpp){
        this.override = true;
    }
    else {
        this.override = false;
    }
    console.log(this.selectedOppId);
}

handleCurrentStudentNotes(event) {
    this.notes = event.detail.value;
}

handleCurrentStudentTagNotes(event){
    this.tagNotes = event.detail.value;
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
                this.createJsonForWirePending();
                return refreshApex(this.refreshTree);

            }

            break;
        } 
    }
    console.log(inputType);

}

changeEPC(event) {

    this.EPC = event.detail.value;
    console.log(this.EPC);
    console.log(this.currentEPCUtilized);
    console.log(Number.isFinite(Number(this.EPC)));

    if ((this.EPC || this.EPC != '0.') && this.currentEPCUtilized > this.EPC || this.compedReason != null){
        this.showCompOptions = true;
    }

    else {this.showCompOptions = false;
          this.compedReason = undefined;  }
}

changeAddOnEPC(event) {

    if (event.target.dataset.targetId != event.detail.value){
        this.showCompOptionsAddOn = true;
    }

    else {this.showCompOptionsAddOn = false;
        this.compedReason = undefined;  }

}

saveStudent() {

    if ((this.compedReason == null & this.showCompOptions == true) || (this.compedReason == undefined && this.showCompOptions == true)){
        const event = new ShowToastEvent({
            title: 'Error!',
            message: 'Adjustment reason is required when EPC Utilized is less than default weighting!',
            variant: 'Error'
        });
        this.dispatchEvent(event);

        return;
    }

    if (this.compedReason == 'Other' && this.notes == undefined || this.notes == ' '){
        const event = new ShowToastEvent({
            title: 'Error!',
            message: 'The notes are required when comped reason is other!',
            variant: 'Error'
        });
        this.dispatchEvent(event);

        return;
    }
    this.epcToComp = 0.00;

    this.studentTagJson = {};

        this.epcToComp = this.currentEPCUtilized - this.EPC;

    this.studentTagJson.studentId = this.currentStudentId;
    this.studentTagJson.oppId = this.selectedOppId;
    this.studentTagJson.studentEPC = this.EPC;
    this.studentTagJson.notes = this.notes;
    this.studentTagJson.compCategory = this.compedReason;
    this.studentTagJson.overrideBoolean = this.override == undefined ? false : this.override ;
    

    const tagInputs = this.template.querySelectorAll('lightning-input');

    this.studentTagJson.tags = [];

    if (tagInputs){
   
        tagInputs.forEach(field => {
            if (field.name != 'epcUtilized' && field.name != 'inputDate'){
console.log(field);
                this.studentTagJson.tags.push({
                    'Id' : field.name ,
                    'tagEpc' : field.value,
                    'tagStartingEpc' : field.title,
                    'tagNotes' : this.tagNotes,
                    'compedCategory' : this.compedTagReason
                });
            }
        })
    }

    this.jsonToParse = JSON.stringify(this.studentTagJson);
    this.isModalLoading = true;

    saveStudentRecords({ jsonStringToParse: this.jsonToParse})
        .then(result => {
            this.savedStudents = result;

            const event = new ShowToastEvent({
                title: 'Records Approved!',
                message: 'Student was saved!',
                variant: 'Success'
            });
            this.dispatchEvent(event);
            this.isModalLoading = false;
            this.refresh();
            this.closeUnapprovedModal();
         
        })
        .catch(error => {
            this.error = error;
            console.log(error)

            const event = new ShowToastEvent({
                title: 'Error!',
                message: 'The records you selected had an error! ' + String(error),
                variant: 'Error'
            });
            this.dispatchEvent(event);
        });
}

@wire(MessageContext)
    messageContext;

refresh() {
    this.currentStudentId = undefined;
    this.selectedOppId = undefined;
    this.studentTagJson = undefined;
    this.override = undefined;
    this.currentOppName = undefined;
    this.currentOpp = undefined;
    this.notes = undefined;
    this.compedReason = undefined;
    this.currentChildren = undefined;
    this.page = 1; //this will initialize 1st page
    this.items = undefined; //it contains all the records.
    this.data = undefined; //data to be displayed in the table
    this.columns; //holds column info.
    this.startingRecord = 1; //start record position per page
    this.endingRecord = 0; //end record position per page
    this.pageSize = 10; //default value we are assigning
    this.totalRecountCount = 0; //total record count received from all retrieved records
    this.totalPage = 0;
    this.treeItems = undefined;
    refreshApex(this.refreshTree);
    refreshApex(this.refreshcompReasons);
    const message = {
        refreshApex: "true",
    };
    
    return publish(this.messageContext, treeGridMC, message);
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

    this.treeItems = this.items.slice(this.startingRecord, this.endingRecord);

    console.log(this.treeItems.length);

    this.startingRecord = this.startingRecord + 1;
} 

get maxYearDate(){

    var maxD = new Date();
    var maxDate = maxD.getFullYear() + 1;

    return maxDate +'-12-31';
}

get isReadOnly(){

    return this.isEpcAdmin.data == true ? false : true;
    
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