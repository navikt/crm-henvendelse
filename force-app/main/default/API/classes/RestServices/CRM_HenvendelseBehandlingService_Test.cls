@isTest
public class CRM_HenvendelseBehandlingService_Test {
    private static final String THREAD_PREFIX = Thread__c.getSObjectType().getDescribe().getKeyPrefix();
    private static final String CONV_NOTE_PREFIX = Conversation_Note__c.getSObjectType().getDescribe().getKeyPrefix();

    @TestSetup
    static void makeData() {
        CRM_HENV_TestDataFactory.createRecord(
            new Common_Code__c(Name = 'Arbeid', CRM_Code__c = 'ARBD', CRM_Code_Set__c = 'Temagrupper')
        );
    }
    @isTest
    static void testSetDisposalDateThread() {
        CRM_HENV_TestDataFactory.createRecord(new Thread__c(CRM_Office_Restriction__c = true));

        Thread__c thread = [SELECT Id, CRM_API_Reference__c FROM Thread__c LIMIT 1];

        CRM_Henvendelse henv = new CRM_Henvendelse();
        henv.kasseringsDato = String.valueOfGmt(Datetime.now());

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() +
            '/services/apexrest/henvendelse/behandling/' +
            thread.CRM_API_Reference__c;
        req.httpMethod = 'PUT';
        req.headers.put('X-Correlation-ID', '123TEST');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = blob.valueOf(JSON.serialize(henv));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseBehandlingRestService.updateHenvendelse();
        Test.stopTest();

        Thread__c updatedThread = [
            SELECT Id, CRM_Disposal_Datetime__c, LastModifiedDate, CRM_Office_Restriction__c
            FROM Thread__c
            WHERE Id = :thread.Id
        ];

        System.assertEquals(true, updatedThread.CRM_Office_Restriction__c); //Verify that office restriction has not been overwritten to default false
        System.assertEquals(Date.today(), updatedThread.CRM_Disposal_Datetime__c.date());
    }

    @isTest
    static void testChangeThemeGroupThread() {
        CRM_HENV_TestDataFactory.createRecord(new Thread__c());
        Thread__c thread = [SELECT Id, CRM_API_Reference__c FROM Thread__c LIMIT 1];

        CRM_Henvendelse henv = new CRM_Henvendelse();
        henv.gjeldendeTemagruppe = 'ARBD';

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() +
            '/services/apexrest/henvendelse/behandling/' +
            thread.CRM_API_Reference__c;
        req.httpMethod = 'PUT';
        req.headers.put('X-Correlation-ID', '123TEST');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = blob.valueOf(JSON.serialize(henv));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseBehandlingRestService.updateHenvendelse();
        Test.stopTest();

        System.assertEquals(
            'Z999999',
            [SELECT Id, CRM_Last_Edited_By__c FROM Thread__c WHERE Id = :thread.Id]
            ?.CRM_Last_Edited_By__c
        );
    }

    @isTest
    static void testInvalidThemeGroupChange() {
        CRM_HENV_TestDataFactory.createRecord(new Thread__c());
        Thread__c thread = [SELECT Id, CRM_API_Reference__c FROM Thread__c LIMIT 1];

        CRM_Henvendelse henv = new CRM_Henvendelse();
        henv.gjeldendeTemagruppe = 'INVALID';

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() +
            '/services/apexrest/henvendelse/behandling/' +
            thread.CRM_API_Reference__c;
        req.httpMethod = 'PUT';
        req.headers.put('X-Correlation-ID', '123TEST');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = blob.valueOf(JSON.serialize(henv));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseBehandlingRestService.updateHenvendelse();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testDmlException() {
        CRM_HENV_TestDataFactory.createRecord(new Thread__c());
        Thread__c thread = [SELECT Id, CRM_API_Reference__c FROM Thread__c LIMIT 1];

        CRM_Henvendelse henv = new CRM_Henvendelse();
        henv.gjeldendeTemagruppe = 'ARBD';

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() +
            '/services/apexrest/henvendelse/behandling/' +
            thread.CRM_API_Reference__c;
        req.httpMethod = 'PUT';
        req.headers.put('X-Correlation-ID', '123TEST');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = blob.valueOf(JSON.serialize(henv));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseBehandlingRestService.simulateException(new DmlException('Something failed'));
        CRM_HenvendelseBehandlingRestService.updateHenvendelse();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
    }

    @isTest
    static void testGenericException() {
        CRM_HENV_TestDataFactory.createRecord(new Thread__c());
        Thread__c thread = [SELECT Id, CRM_API_Reference__c FROM Thread__c LIMIT 1];

        CRM_Henvendelse henv = new CRM_Henvendelse();
        henv.gjeldendeTemagruppe = 'ARBD';

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() +
            '/services/apexrest/henvendelse/behandling/' +
            thread.CRM_API_Reference__c;
        req.httpMethod = 'PUT';
        req.headers.put('X-Correlation-ID', '123TEST');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = blob.valueOf(JSON.serialize(henv));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseBehandlingRestService.simulateException(new CalloutException('Something failed'));
        CRM_HenvendelseBehandlingRestService.updateHenvendelse();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
    }

    @isTest
    static void testInvalidId() {
        Thread__c thread = (Thread__c) CRM_HENV_TestDataFactory.createRecord(new Thread__c());

        CRM_Henvendelse henv = new CRM_Henvendelse();
        henv.gjeldendeTemagruppe = 'ARBD';

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() +
            '/services/apexrest/henvendelse/behandling/' +
            'INVALIDID';
        req.httpMethod = 'PUT';
        req.headers.put('X-Correlation-ID', '123TEST');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = blob.valueOf(JSON.serialize(henv));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseBehandlingRestService.updateHenvendelse();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testSetDisposalDateConvNote() {
        CRM_HENV_TestDataFactory.createRecord(new Conversation_Note__c());

        Conversation_Note__c convNote = [SELECT Id, CRM_API_Reference__c FROM Conversation_Note__c LIMIT 1];
        CRM_Henvendelse henv = new CRM_Henvendelse();
        henv.kasseringsDato = String.valueOfGmt(Datetime.now());

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() +
            '/services/apexrest/henvendelse/behandling/' +
            convNote.CRM_API_Reference__c;
        req.httpMethod = 'PUT';
        req.headers.put('X-Correlation-ID', '123TEST');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = blob.valueOf(JSON.serialize(henv));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseBehandlingRestService.updateHenvendelse();
        Test.stopTest();

        System.assertEquals(
            Date.today(),
            [SELECT Id, CRM_Disposal_Datetime__c FROM Conversation_Note__c WHERE Id = :convNote.Id]
                ?.CRM_Disposal_Datetime__c.date()
        );
    }
}
