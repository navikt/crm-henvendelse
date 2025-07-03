@isTest
public class CRM_HenvRedactionRestService_Test {
    @TestSetup
    static void makeData() {
        CRM_HENV_TestDataFactory.createRecord(new Conversation_Note__c());
        CRM_HENV_TestDataFactory.createRecord(new Message__c());
    }

    @isTest
    static void testGetCauses() {
        String apiReference = [SELECT Id, CRM_API_Reference__c FROM Conversation_Note__c LIMIT 1]?.CRM_API_Reference__c;

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() +
            '/services/apexrest/henvendelse/sladding/aarsaker/' +
            apiReference;
        req.httpMethod = 'GET';
        req.headers.put('X-Correlation-ID', '123TEST');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvRedactionRestService.getRedactionCauses();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testGetCausesError() {
        String apiReference = [SELECT Id, CRM_API_Reference__c FROM Conversation_Note__c LIMIT 1]?.CRM_API_Reference__c;

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() +
            '/services/apexrest/henvendelse/sladding/aarsaker/' +
            'somethingRandom';
        req.httpMethod = 'GET';
        req.headers.put('X-Correlation-ID', '123TEST');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvRedactionRestService.getRedactionCauses();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testMarkForRedaction() {
        String apiReference = [SELECT Id, CRM_API_Reference__c FROM Conversation_Note__c LIMIT 1]?.CRM_API_Reference__c;

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        CRM_HenvRedactionRestService.SladdingRequest slRequest = new CRM_HenvRedactionRestService.SladdingRequest();
        slRequest.aarsak = 'Sendt feil bruker';
        slRequest.kjedeId = apiReference;

        req.requestURI = Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/sladding';
        req.httpMethod = 'POST';
        req.headers.put('X-Correlation-ID', '123TEST');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = blob.valueOf(JSON.serialize(slRequest));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvRedactionRestService.markForRedaction();
        Test.stopTest();

        System.assertEquals(204, RestContext.response.statusCode);
    }

    @isTest
    static void testMarkMessageForRedaction() {
        Message__c msg = [SELECT Id, CRM_API_Reference__c, CRM_Thread__r.CRM_API_Reference__c FROM Message__c LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        CRM_HenvRedactionRestService.SladdingRequest slRequest = new CRM_HenvRedactionRestService.SladdingRequest();
        slRequest.aarsak = 'Sendt feil bruker';
        slRequest.kjedeId = msg.CRM_Thread__r.CRM_API_Reference__c;
        slRequest.meldingsIder = new List<String>{ msg.CRM_API_Reference__c };

        req.requestURI = Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/sladding';
        req.httpMethod = 'POST';
        req.headers.put('X-Correlation-ID', '123TEST');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = blob.valueOf(JSON.serialize(slRequest));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvRedactionRestService.markForRedaction();
        Test.stopTest();

        System.assertEquals(204, RestContext.response.statusCode);
        System.assertEquals(1, [SELECT COUNT() FROM Message__c WHERE CRM_Sensitive_Information__c = TRUE]);
    }

    @isTest
    static void testMarkConvNoteForRedaction() {
        Conversation_Note__c masterNote = [
            SELECT Id, CRM_API_Reference__c, CRM_Henvendelse_BehandlingskjedeId__c
            FROM Conversation_Note__c
            LIMIT 1
        ];
        Conversation_Note__c childNote = (Conversation_Note__c) CRM_HENV_TestDataFactory.createRecord(
            new Conversation_Note__c(CRM_Henvendelse_BehandlingskjedeId__c = masterNote.CRM_API_Reference__c)
        );

        childNote = [
            SELECT Id, CRM_API_Reference__c, CRM_Henvendelse_BehandlingskjedeId__c
            FROM Conversation_Note__c
            WHERE Id = :childNote.Id
        ];

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        CRM_HenvRedactionRestService.SladdingRequest slRequest = new CRM_HenvRedactionRestService.SladdingRequest();
        slRequest.aarsak = 'Sendt feil bruker';
        slRequest.kjedeId = childNote.CRM_Henvendelse_BehandlingskjedeId__c;
        slRequest.meldingsIder = new List<String>{ childNote.CRM_API_Reference__c };

        req.requestURI = Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/sladding';
        req.httpMethod = 'POST';
        req.headers.put('X-Correlation-ID', '123TEST');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = blob.valueOf(JSON.serialize(slRequest));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvRedactionRestService.markForRedaction();
        Test.stopTest();

        System.assertEquals(204, RestContext.response.statusCode);
        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Conversation_Note__c
                WHERE
                    CRM_Henvendelse_BehandlingskjedeId__c = :childNote.CRM_Henvendelse_BehandlingskjedeId__c
                    AND STO_Sensitive_Information__c = TRUE
            ]
        );
    }

    @isTest
    static void testMarkRedactionDmlError() {
        String apiReference = [SELECT Id, CRM_API_Reference__c FROM Conversation_Note__c LIMIT 1]?.CRM_API_Reference__c;

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        CRM_HenvRedactionRestService.SladdingRequest slRequest = new CRM_HenvRedactionRestService.SladdingRequest();
        slRequest.aarsak = 'Sendt feil bruker';
        slRequest.kjedeId = apiReference;

        req.requestURI = Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/sladding';
        req.httpMethod = 'POST';
        req.headers.put('X-Correlation-ID', '123TEST');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = blob.valueOf(JSON.serialize(slRequest));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvRedactionRestService.simulateException(new DmlException('Error'));
        CRM_HenvRedactionRestService.markForRedaction();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
    }

    @isTest
    static void testMarkRedactionGenericError() {
        String apiReference = [SELECT Id, CRM_API_Reference__c FROM Conversation_Note__c LIMIT 1]?.CRM_API_Reference__c;

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        CRM_HenvRedactionRestService.SladdingRequest slRequest = new CRM_HenvRedactionRestService.SladdingRequest();
        slRequest.aarsak = 'Sendt feil bruker';
        slRequest.kjedeId = apiReference;

        req.requestURI = Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/sladding';
        req.httpMethod = 'POST';
        req.headers.put('X-Correlation-ID', '123TEST');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        req.requestBody = blob.valueOf(JSON.serialize(slRequest));
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvRedactionRestService.simulateException(new JSONException('Error'));
        CRM_HenvRedactionRestService.markForRedaction();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
    }
}
