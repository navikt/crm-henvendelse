@isTest
public class CRM_HenvendelseNyRestService_Test extends CRM_HenvendelseApiUtils {
    private static final String THREAD_PREFIX = Thread__c.getSObjectType().getDescribe().getKeyPrefix();
    private static final String CONV_NOTE_PREFIX = Conversation_Note__c.getSObjectType().getDescribe().getKeyPrefix();

    @TestSetup
    static void makeData() {
        CRM_HENV_TestDataFactory.createRecord(new Person__c(INT_ActorId__c = '123456789101112'));
        CRM_HENV_TestDataFactory.createRecord(new Thread__c());
        CRM_HENV_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code__c = 'ARBD', CRM_Code_Set__c = 'Temagrupper')
        );
    }

    @isTest
    static void testNewConversationNote() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        CRM_HenvendelseNyRestService.NewConversationNoteRequest convNoteReq = new CRM_HenvendelseNyRestService.NewConversationNoteRequest();
        convNoteReq.aktorId = '123456789101112';
        convNoteReq.enhet = '4100';
        convNoteReq.kanal = 'TELEFON';
        convNoteReq.temagruppe = 'ARBD';
        convNoteReq.fritekst = 'REFERAT';

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/ny/samtalereferat';
        req.httpMethod = 'POST';
        req.headers.put('X-Correlation-ID', '123RANDOM');
        req.requestBody = Blob.valueOf(JSON.serialize(convNoteReq));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseNyRestService.createHenvendelse();
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Conversation_Note__c]);
    }

    @isTest
    static void testNewFollowUpConversationNote() {
        Person__c person = [SELECT Id, CRM_Account__c FROM Person__c LIMIT 1];
        String behandlingskjedeId = CONV_NOTE_PREFIX + '123TEST';
        Conversation_Note__c firstNote = (Conversation_Note__c) CRM_HENV_TestDataFactory.createRecord(
            new Conversation_Note__c(
                CRM_Account__c = person.CRM_Account__c,
                CRM_Henvendelse_BehandlingskjedeId__c = behandlingskjedeId
            )
        );
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        CRM_HenvendelseNyRestService.NewConversationNoteRequest convNoteReq = new CRM_HenvendelseNyRestService.NewConversationNoteRequest();
        convNoteReq.aktorId = '123456789101112';
        convNoteReq.enhet = '4100';
        convNoteReq.kanal = 'TELEFON';
        convNoteReq.temagruppe = 'ARBD';
        convNoteReq.fritekst = 'REFERAT NUMBER 2';

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/ny/samtalereferat';
        req.addParameter('kjedeId', behandlingskjedeId);
        req.httpMethod = 'POST';
        req.headers.put('X-Correlation-ID', '123RANDOM');
        req.requestBody = Blob.valueOf(JSON.serialize(convNoteReq));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseNyRestService.createHenvendelse();
        Test.stopTest();

        System.assertEquals(
            2,
            [SELECT COUNT() FROM Conversation_Note__c WHERE CRM_Henvendelse_BehandlingskjedeId__c = :behandlingskjedeId]
        );
    }

    @isTest
    static void testNewConversationNoteInvalidBody() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        String requestBody = '[]';

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/ny/samtalereferat';
        req.httpMethod = 'POST';
        req.headers.put('X-Correlation-ID', '123RANDOM');
        req.requestBody = Blob.valueOf(requestBody);
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseNyRestService.createHenvendelse();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assertEquals(0, [SELECT COUNT() FROM Conversation_Note__c]);
    }

    @isTest
    static void testNewNonExistingActorConvNote() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        CRM_HenvendelseNyRestService.NewConversationNoteRequest convNoteReq = new CRM_HenvendelseNyRestService.NewConversationNoteRequest();
        convNoteReq.aktorId = '1234567890000';
        convNoteReq.enhet = '4100';
        convNoteReq.kanal = 'TELEFON';
        convNoteReq.temagruppe = 'ARBD';
        convNoteReq.fritekst = 'REFERAT';

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/ny/samtalereferat';
        req.httpMethod = 'POST';
        req.headers.put('X-Correlation-ID', '123RANDOM');
        req.requestBody = Blob.valueOf(JSON.serialize(convNoteReq));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseNyRestService.createHenvendelse();
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
        System.assertEquals(0, [SELECT COUNT() FROM Conversation_Note__c]);
    }

    @isTest
    static void testNewConversationNoteDmlException() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        CRM_HenvendelseNyRestService.NewConversationNoteRequest convNoteReq = new CRM_HenvendelseNyRestService.NewConversationNoteRequest();
        convNoteReq.aktorId = '123456789101112';
        convNoteReq.enhet = '4100';
        convNoteReq.kanal = 'TELEFON';
        convNoteReq.temagruppe = 'ARBD';
        convNoteReq.fritekst = 'REFERAT';

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/ny/samtalereferat';
        req.httpMethod = 'POST';
        req.headers.put('X-Correlation-ID', '123RANDOM');
        req.requestBody = Blob.valueOf(JSON.serialize(convNoteReq));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseNyRestService.simulateException(new DmlException('TESTING'));
        CRM_HenvendelseNyRestService.createHenvendelse();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
    }

    @isTest
    static void testInvalidType() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        CRM_HenvendelseNyRestService.NewConversationNoteRequest convNoteReq = new CRM_HenvendelseNyRestService.NewConversationNoteRequest();

        req.requestURI = Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/ny/invalidtype';
        req.httpMethod = 'POST';
        req.headers.put('X-Correlation-ID', '123RANDOM');
        req.requestBody = Blob.valueOf(JSON.serialize(convNoteReq));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseNyRestService.createHenvendelse();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testMissingCorrelationHeader() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        CRM_HenvendelseNyRestService.NewConversationNoteRequest convNoteReq = new CRM_HenvendelseNyRestService.NewConversationNoteRequest();

        req.requestURI = Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/ny/invalidtype';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(convNoteReq));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseNyRestService.createHenvendelse();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testNewMessageOnExistingThread() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        Thread__c thread = [SELECT Id, CRM_API_Reference__c FROM Thread__c LIMIT 1];

        CRM_HenvendelseNyRestService.NewMessageRequest messageReq = new CRM_HenvendelseNyRestService.NewMessageRequest();
        messageReq.aktorId = '123456789101112';
        messageReq.enhet = '4100';
        messageReq.fritekst = 'MELDING';
        messageReq.temagruppe = 'ARBD';
        messageReq.tildelMeg = true;

        req.requestURI = Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/ny/melding';
        req.httpMethod = 'POST';
        req.addParameter('kjedeId', thread.CRM_API_Reference__c);
        req.headers.put('X-Correlation-ID', '123RANDOM');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = Blob.valueOf(JSON.serialize(messageReq));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseNyRestService.createHenvendelse();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(1, [SELECT COUNT() FROM Thread__c]);
        System.assertEquals('Z999999', [SELECT Id, CRM_From_Ident__c FROM Message__c LIMIT 1]?.CRM_From_Ident__c);
        System.assertEquals(
            'Z999999',
            [SELECT Id, CRM_Assignee__c FROM Thread__c WHERE CRM_Assignee_NAV_Unit__c = '4100' LIMIT 1]
            ?.CRM_Assignee__c
        );
    }

    @isTest
    static void testNewMessageNoThread() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        Thread__c thread = [SELECT Id FROM Thread__c LIMIT 1];

        CRM_HenvendelseNyRestService.NewMessageRequest messageReq = new CRM_HenvendelseNyRestService.NewMessageRequest();
        messageReq.aktorId = '123456789101112';
        messageReq.enhet = '4100';
        messageReq.fritekst = 'MELDING';
        messageReq.temagruppe = 'ARBD';

        req.requestURI = Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/ny/melding';
        req.httpMethod = 'POST';
        req.headers.put('X-Correlation-ID', '123RANDOM');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = Blob.valueOf(JSON.serialize(messageReq));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseNyRestService.createHenvendelse();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals('Z999999', [SELECT Id, CRM_From_Ident__c FROM Message__c LIMIT 1]?.CRM_From_Ident__c);
        System.assertEquals(1, [SELECT COUNT() FROM Thread__c WHERE CRM_Type__c = 'STB']);
    }

    @isTest
    static void testNewThreadInvalidThemeGroup() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        Thread__c thread = [SELECT Id FROM Thread__c LIMIT 1];

        CRM_HenvendelseNyRestService.NewMessageRequest messageReq = new CRM_HenvendelseNyRestService.NewMessageRequest();
        messageReq.aktorId = '123456789101112';
        messageReq.enhet = '4100';
        messageReq.fritekst = 'MELDING';
        messageReq.temagruppe = 'INVALID';

        req.requestURI = Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/ny/melding';
        req.httpMethod = 'POST';
        req.headers.put('X-Correlation-ID', '123RANDOM');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = Blob.valueOf(JSON.serialize(messageReq));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseNyRestService.createHenvendelse();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testNewThreadInvalidTheme() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        Thread__c thread = [SELECT Id FROM Thread__c LIMIT 1];

        CRM_HenvendelseNyRestService.NewMessageRequest messageReq = new CRM_HenvendelseNyRestService.NewMessageRequest();
        messageReq.aktorId = '123456789101112';
        messageReq.enhet = '4100';
        messageReq.fritekst = 'MELDING';
        messageReq.temagruppe = 'ARBD';
        messageReq.tema = 'INVALID';

        req.requestURI = Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/ny/melding';
        req.httpMethod = 'POST';
        req.headers.put('X-Correlation-ID', '123RANDOM');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = Blob.valueOf(JSON.serialize(messageReq));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseNyRestService.createHenvendelse();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testNewMessageOnClosedThread() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        Thread__c thread = [SELECT Id, CRM_API_Reference__c, CRM_isActive__c FROM Thread__c LIMIT 1];
        thread.CRM_isActive__c = false;
        update thread;

        CRM_HenvendelseNyRestService.NewMessageRequest messageReq = new CRM_HenvendelseNyRestService.NewMessageRequest();
        messageReq.aktorId = '123456789101112';
        messageReq.enhet = '4100';
        messageReq.fritekst = 'MELDING';
        messageReq.temagruppe = 'ARBD';

        req.requestURI = Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/ny/melding';
        req.httpMethod = 'POST';
        req.addParameter('kjedeId', thread.CRM_API_Reference__c);
        req.headers.put('X-Correlation-ID', '123RANDOM');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = Blob.valueOf(JSON.serialize(messageReq));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseNyRestService.createHenvendelse();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testNewMessageOnNonExistingThread() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        Thread__c thread = [SELECT Id, CRM_API_Reference__c, CRM_isActive__c FROM Thread__c LIMIT 1];
        String fakeThreadId = thread.CRM_API_Reference__c;
        delete thread;

        CRM_HenvendelseNyRestService.NewMessageRequest messageReq = new CRM_HenvendelseNyRestService.NewMessageRequest();
        messageReq.aktorId = '123456789101112';
        messageReq.enhet = '4100';
        messageReq.fritekst = 'MELDING';
        messageReq.temagruppe = 'ARBD';

        req.requestURI = Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/ny/melding';
        req.httpMethod = 'POST';
        req.addParameter('kjedeId', fakeThreadId);
        req.headers.put('X-Correlation-ID', '123RANDOM');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = Blob.valueOf(JSON.serialize(messageReq));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseNyRestService.createHenvendelse();
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
    }

    @isTest
    static void testInvalidNewMessageBody() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI = Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/ny/melding';
        req.httpMethod = 'POST';
        req.addParameter('kjedeId', 'fakeThreadId');
        req.headers.put('X-Correlation-ID', '123RANDOM');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = Blob.valueOf(JSON.serialize('[]'));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseNyRestService.createHenvendelse();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testNewMessageOnNonExistingActor() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        Thread__c thread = [SELECT Id, CRM_API_Reference__c, CRM_isActive__c FROM Thread__c LIMIT 1];

        CRM_HenvendelseNyRestService.NewMessageRequest messageReq = new CRM_HenvendelseNyRestService.NewMessageRequest();
        messageReq.aktorId = '12345678910000';
        messageReq.enhet = '4100';
        messageReq.fritekst = 'MELDING';
        messageReq.temagruppe = 'ARBD';

        req.requestURI = Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/ny/melding';
        req.httpMethod = 'POST';
        req.addParameter('kjedeId', thread.CRM_API_Reference__c);
        req.headers.put('X-Correlation-ID', '123RANDOM');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = Blob.valueOf(JSON.serialize(messageReq));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseNyRestService.createHenvendelse();
        Test.stopTest();

        System.assertEquals(404, RestContext.response.statusCode);
    }

    @isTest
    static void testNewMessageDmlException() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        Thread__c thread = [SELECT Id, CRM_API_Reference__c, CRM_isActive__c FROM Thread__c LIMIT 1];

        CRM_HenvendelseNyRestService.NewMessageRequest messageReq = new CRM_HenvendelseNyRestService.NewMessageRequest();
        messageReq.aktorId = '123456789101112';
        messageReq.enhet = '4100';
        messageReq.fritekst = 'MELDING';
        messageReq.temagruppe = 'ARBD';

        req.requestURI = Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/ny/melding';
        req.httpMethod = 'POST';
        req.addParameter('kjedeId', thread.CRM_API_Reference__c);
        req.headers.put('X-Correlation-ID', '123RANDOM');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = Blob.valueOf(JSON.serialize(messageReq));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseNyRestService.simulateException(new DmlException('TEST'));
        CRM_HenvendelseNyRestService.createHenvendelse();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
    }
}
