import { LightningElement, track, wire } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { getRecord, createRecord } from 'lightning/uiRecordApi';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import downloadjs from '@salesforce/resourceUrl/downloadjs';
import USER_EMAIL_FIELD from '@salesforce/schema/User.Email';
import ACCOUNT_OBJECT from '@salesforce/schema/Account';
import generatePDFContent from '@salesforce/apex/PrintJobPDF.generateBase64PDFContent';
import sharePdf from '@salesforce/apex/PrintJobPDF.sharePdf';
import { CloseActionScreenEvent } from 'lightning/actions';

const USER_FIELDS = [USER_EMAIL_FIELD];

export default class CreateNewPDF extends NavigationMixin(LightningElement) {
  @track showButtons = true;
  @track pdfUrl;
  @track boolShowSpinner = false;
  userEmail;
  recordId;

  connectedCallback() {
    this.generatePdf();
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

  async generatePdf() {
    this.showButtons = false;
    this.boolShowSpinner = true;
    try {
      const result = await generatePDFContent();
      console.log('Result = ' + result);
      if (result) {
        const contentDocumentRecord = {
          apiName: 'ContentVersion',
          fields: {
            Title: 'attachment.pdf',
            PathOnClient: 'attachment.pdf',
            VersionData: result,
            FirstPublishLocationId: this.recordId
          }
        };
        console.log('ContentDocumentRecord = ' + contentDocumentRecord);
        console.log('Result123 = ' + result);
        this.dispatchEvent(new CloseActionScreenEvent());
        const createdRecord = await createRecord(contentDocumentRecord);
        console.log('CreateRecord = ' + createdRecord);
        console.log('RecordId = ' + createdRecord.id);
        if (createdRecord.id) {
          this.pdfUrl =
            '/sfc/servlet.shepherd/document/download/'+createdRecord.id;
            console.log('Final log'+ this.pdfUrl);
           // this.sharePDF();
          window.open(this.pdfUrl);
        }
      }
    } catch (error) {
      console.log('Error:', error.body ? error.body.message : error);
    }
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
