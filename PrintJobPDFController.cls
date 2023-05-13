public with sharing class PrintJobPDFController {
    @AuraEnabled
    public static List<String> getPDFprint() {
        List<String> pageStrings = new List<String>();
        PageReference pdfPage = Page.generatePdf;
        Blob pdfBlob = pdfPage.getContentAsPDF();
        String downloadURL = '/sfc/servlet.shepherd/document/download/' + pdfPage.getParameters().get('id');
        pageStrings.add(downloadURL);
        pageStrings.add(pdfPage.getUrl());
        return pageStrings;
    } 
    @AuraEnabled
    public static void sharePdf(Id recordId) {
        try {
            Account acc = [SELECT Id, Email__c FROM Account WHERE Id = :recordId];
            if (acc != null && acc.Email__c != null) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{acc.Email__c}); 
                PageReference pdfPage = Page.generatePdf;
                pdfPage.getParameters().put('id', recordId);
                Blob pdfBlob = pdfPage.getContentAsPDF();
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('attachment.pdf');
                attachment.setBody(pdfBlob);
                email.setFileAttachments(new Messaging.EmailFileAttachment[]{attachment});
                email.setSubject('PDF Attachment');
                email.setPlainTextBody('Please find attached the PDF document.'); 
                Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
                for (Messaging.SendEmailResult result : sendResults) {
                    if (!result.isSuccess()) {
                        for (Messaging.SendEmailError error : result.getErrors()) {
                            System.debug('Failed to send email: ' + error.getMessage());
                        }
                    }
                }
            } else {
                System.debug('Invalid account or email address not found.');
            }
        } catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
        }     
    }
}
