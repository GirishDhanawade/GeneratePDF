import { LightningElement, track, wire,api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { getRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference } from 'lightning/navigation';
import downloadjs from '@salesforce/resourceUrl/downloadjs';
import downloadPDF from '@salesforce/apex/PrintJobPDFController.getPDFprint';
import sharePdf from '@salesforce/apex/PrintJobPDFController.sharePdf';
import USER_EMAIL_FIELD from '@salesforce/schema/User.Email';
import { CloseActionScreenEvent } from 'lightning/actions';

const USER_FIELDS = [USER_EMAIL_FIELD];
export default class CreateNewPDF extends LightningElement {
    @track showButtons = true;
    @track pdfUrl;
    @track boolShowSpinner = false;
    userEmail;
    recordId;
    async connectedCallback(){
       await this.generatePdf();
       await this.sharePDF();
    }
    @wire(CurrentPageReference)
    currentPageReferenceHandler(currentPageReference) {
        if (currentPageReference && currentPageReference.state) {
            this.recordId = currentPageReference.state.recordId;
        }
    }
    @wire(CurrentPageReference) pageRef;
    @wire(getRecord, { recordId: '$accountId', fields: USER_FIELDS })
    wireAccount({ error, data }) {
        if (data) {
            this.userEmail = data.fields.Email.value;
        } else if (error) {
            console.error('Error retrieving account information:', error);
        }
    }
    renderedCallback() {
        loadScript(this, downloadjs)
            .then(() => console.log('Loaded download.js'))
            .catch(error => console.log(error));
    }
    get accountId() {
        return this.pageRef && this.pageRef.state && this.pageRef.state.recordId;
    }
    async generatePdf() {
        this.showButtons = false;
        this.boolShowSpinner = true;
        downloadPDF({})
            .then(response => {
                console.log('response[0]====>' + response[0]);
                this.pdfUrl = response[1];
               //window.location.href = this.pdfUrl; for same page
                window.open(this.pdfUrl);//for new page
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                console.log('Error: ' + error.body.message);
            })
    }

    async sharePDF() {
        this.showButtons = false;
        if (this.recordId) {
            console.log('RecordId = ' + this.recordId);
            sharePdf({ recordId: this.recordId })
                .then(response => {
                    console.log('Success: ' + response);
                })
                .catch(error => {
                    console.error('Error: ' + error.body.message);
                });
        }
    }  
}
