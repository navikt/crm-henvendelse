@isTest
public class CRM_HenvendelseJournalRestService_Test {
    @TestSetup
    static void makeData() {
        CRM_HENV_TestDataFactory.createRecord(new Common_Code__c(CRM_Code_Set__c = 'Tema', CRM_Code__c = 'DAG'));
        CRM_HENV_TestDataFactory.createRecord(new Conversation_Note__c(CRM_Conversation_Note__c = 'DUMMY TEXT'));
        Thread__c thread = (Thread__c) CRM_HENV_TestDataFactory.createRecord(new Thread__c());
        CRM_HENV_TestDataFactory.createRecord(new Message__c(CRM_Thread__c = thread.Id));
    }

    @isTest
    static void testConvNoteJournal() {
        Conversation_Note__c convNote = [SELECT Id, CRM_API_Reference__c FROM Conversation_Note__c LIMIT 1];
        ApiMock.setTestMock('POST_CREATE_JOURNAL', 200, 'OK');

        CRM_HenvendelseJournalRestService.HenvendelseJournalRequest journalReq = new CRM_HenvendelseJournalRestService.HenvendelseJournalRequest();
        journalReq.journalforendeEnhet = '4100';
        journalReq.fagsakId = '123CASE';
        journalReq.fagsaksystem = 'K9';
        journalReq.temakode = 'DAG;';
        journalReq.kjedeId = convNote.CRM_API_Reference__c;

        RestRequest restReq = new RestRequest();
        restReq.headers.put('X-Correlation-ID', '123RANDOM');
        restReq.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        restReq.requestBody = Blob.valueOf(JSON.serialize(journalReq));

        RestContext.request = restReq;
        RestContext.response = new RestResponse();

        List<Id> fixedSearchResults = new List<Id>();
        fixedSearchResults.add(convNote.Id);
        //Setting the SOSL fixed search results
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
        CRM_HenvendelseJournalRestService.createJournalPost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        Conversation_Note__c updatedConvNote = [
            SELECT Id, CRM_Journal_Status__c
            FROM Conversation_Note__c
            WHERE Id = :convNote.Id
        ];
        System.assert(updatedConvNote.CRM_Journal_Status__c.equalsIgnoreCase('Journal Completed'));
    }

    @isTest
    static void testThreadJournal() {
        Thread__c thread = [SELECT Id, CRM_API_Reference__c FROM Thread__c LIMIT 1];
        ApiMock.setTestMock('POST_CREATE_JOURNAL', 200, 'OK');

        CRM_HenvendelseJournalRestService.HenvendelseJournalRequest journalReq = new CRM_HenvendelseJournalRestService.HenvendelseJournalRequest();
        journalReq.journalforendeEnhet = '4100';
        journalReq.fagsakId = '123CASE';
        journalReq.fagsaksystem = 'ARENA';
        journalReq.temakode = 'DAG;';
        journalReq.kjedeId = thread.CRM_API_Reference__c;

        RestRequest restReq = new RestRequest();
        restReq.headers.put('X-Correlation-ID', '123RANDOM');
        restReq.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        restReq.requestBody = Blob.valueOf(JSON.serialize(journalReq));

        RestContext.request = restReq;
        RestContext.response = new RestResponse();

        Test.startTest();
        CRM_HenvendelseJournalRestService.createJournalPost();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertNotEquals(0, [SELECT COUNT() FROM Journal_Entry__c WHERE CRM_Thread__c = :thread.Id]);
    }

    @isTest
    static void testInvalidObjectIdInput() {
        ApiMock.setTestMock('POST_CREATE_JOURNAL', 200, 'OK');

        CRM_HenvendelseJournalRestService.HenvendelseJournalRequest journalReq = new CRM_HenvendelseJournalRestService.HenvendelseJournalRequest();
        journalReq.journalforendeEnhet = '4100';
        journalReq.fagsakId = '123CASE';
        journalReq.temakode = 'DAG;';
        journalReq.kjedeId = (String) CRM_HENV_TestDataFactory.createRecord(new Case()).get('Id');

        RestRequest restReq = new RestRequest();
        restReq.headers.put('X-Correlation-ID', '123RANDOM');
        restReq.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        restReq.requestBody = Blob.valueOf(JSON.serialize(journalReq));

        RestContext.request = restReq;
        RestContext.response = new RestResponse();

        Test.startTest();
        CRM_HenvendelseJournalRestService.createJournalPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testInvalidId() {
        ApiMock.setTestMock('POST_CREATE_JOURNAL', 200, 'OK');

        CRM_HenvendelseJournalRestService.HenvendelseJournalRequest journalReq = new CRM_HenvendelseJournalRestService.HenvendelseJournalRequest();
        journalReq.journalforendeEnhet = '4100';
        journalReq.fagsakId = '123CASE';
        journalReq.temakode = 'DAG;';
        journalReq.kjedeId = '123INVALIDID';

        RestRequest restReq = new RestRequest();
        restReq.headers.put('X-Correlation-ID', '123RANDOM');
        restReq.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        restReq.requestBody = Blob.valueOf(JSON.serialize(journalReq));

        RestContext.request = restReq;
        RestContext.response = new RestResponse();

        Test.startTest();
        CRM_HenvendelseJournalRestService.createJournalPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testMissingXcorrelation() {
        ApiMock.setTestMock('POST_CREATE_JOURNAL', 200, 'OK');

        CRM_HenvendelseJournalRestService.HenvendelseJournalRequest journalReq = new CRM_HenvendelseJournalRestService.HenvendelseJournalRequest();
        journalReq.journalforendeEnhet = '4100';
        journalReq.fagsakId = '123CASE';
        journalReq.temakode = 'DAG;';
        journalReq.kjedeId = '123INVALIDID';

        RestRequest restReq = new RestRequest();
        restReq.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        restReq.requestBody = Blob.valueOf(JSON.serialize(journalReq));

        RestContext.request = restReq;
        RestContext.response = new RestResponse();

        Test.startTest();
        CRM_HenvendelseJournalRestService.createJournalPost();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }
}
