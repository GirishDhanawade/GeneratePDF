public with sharing class PrintJobPDF {
    @AuraEnabled(cacheable = true)
    public static String generateBase64PDFContent() {
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
  
        String pdfContent =
            '<div>' +
            '<div style="display: flex; align-items: flex-start;">' +
            '<div style="width: 33.33%; display: inline-block;">' +
            '<img src="' +
            baseUrl +
            '/resource/SSH_Logo" alt="SSH Logo" style="margin-right: 10px;"/>' +
            '</div>' +
            '<div style="border: 1px solid black; padding: 8px; width: 30%; height: 15%; display:inline-block; margin: 0 auto;">' +
            '<h4 style="margin: 0;">Silver Hill Hospital is a non-profit psychiatric hospital in New Canaan, Connecticut established in 1931. The hospital is accredited by the Joint Commission and provides behavioral health care treatment. This includes psychiatric and addiction services.</h4>' +
            '</div>' +
            '<div style="width: 33.33%; display: inline-block;"></div>' +
            '</div>' +
            '<div style="margin-top: 22px;">' +
            '<div>' +
            '<h2 style="border: 1px solid black; padding: 8px;">Silver Hill Hospital Information</h2>' +
            '</div>' +
            '<table style="border: 1px solid black; border-collapse: collapse;">' +
            '<tr>' +
            '<th style="border: 1px solid black; padding: 8px;">Sr No</th>' +
            '<th style="border: 1px solid black; padding: 8px;">Name</th>' +
            '<th style="border: 1px solid black; padding: 8px;">Email</th>' +
            '<th style="border: 1px solid black; padding: 8px;">Mobile</th>' +
            '<th style="border: 1px solid black; padding: 8px;">Description</th>' +
            '</tr>';
  
        List<Contact> contacts = [SELECT Name, Email, Phone, rowNumber__c, Health_Description__c FROM Contact LIMIT 5];
  
        for (Contact contact : contacts) {
            pdfContent +=
                '<tr>' +
                '<td style="border: 1px solid black; padding: 8px;">' +
                contact.rowNumber__c +
                '</td>' +
                '<td style="border: 1px solid black; padding: 8px;">' +
                contact.Name +
                '</td>' +
                '<td style="border: 1px solid black; padding: 8px;">' +
                contact.Email +
                '</td>' +
                '<td style="border: 1px solid black; padding: 8px;">' +
                contact.Phone +
                '</td>' +
                '<td style="border: 1px solid black; padding: 8px;">' +
                contact.Health_Description__c +
                '</td>' +
                '</tr>';
        }
  
        pdfContent += '</table>' + '</div>' + '</div>';
  
        Blob pdfBlob = Blob.valueOf(pdfContent);
        return EncodingUtil.base64Encode(pdfBlob);
    }
  
    @AuraEnabled
    public static void sharePdf(Id recordId) {
        try {
            Account acc = [SELECT Id, Email__c FROM Account WHERE Id = :recordId LIMIT 1];
  
            if (acc != null && acc.Email__c != null) {
                String base64PDFContent = generateBase64PDFContent();
  
                Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                attachment.setFileName('attachment.pdf');
                attachment.setBody(EncodingUtil.base64Decode(base64PDFContent));
  
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String> { acc.Email__c });
                email.setSubject('PDF Attachment');
                email.setPlainTextBody('Please find attached the PDF document.');
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });
  
                Messaging.SendEmailResult[] sendResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
  
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
