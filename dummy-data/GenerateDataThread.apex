//Create a dummy thread for the portal user created in GenerateData.apex.
//Run as a separate execution from GenerateData.apex: inserting a User (setup object) and
//a Thread__c/Message__c/Journal_Entry__c (non-setup objects) in the same transaction hits
//MIXED_DML_OPERATION.
User portalUser = [SELECT Id FROM User WHERE Username = 'harry.potter@test.nav.henvendelse' LIMIT 1];

Thread__c thread = new Thread__c();
thread.CRM_From__c = portalUser.Id;
thread.CRM_isActive__c = true;
insert thread;

Message__c message = new Message__c(CRM_Thread__c = thread.Id,
                    CRM_Message_Text__c = 'Dette er en testmelding :)',
                    CRM_Read_Datetime__c = Datetime.now(),
                    CRM_Sent_Date__c = Datetime.now().addDays(-1));

insert message;

Journal_Entry__c jEntry = new Journal_Entry__c(
          CRM_Thread__c = thread.Id,
          Journal_Entry_Status__c = 'Completed',
          CRM_Journal_Date__c = Datetime.now(),
          CRM_Created_By_Ident__c = 'Z999999'
);
insert jEntry;
