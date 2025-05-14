@isTest
public class CRM_HenvThreadCloseRestService_Test {
    @TestSetup
    static void makeData() {
        CRM_HENV_TestDataFactory.createRecord(new Thread__c());
    }

    @isTest
    static void testThreadClose() {
        Thread__c thread = [SELECT Id, CRM_API_Reference__c FROM Thread__c LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/meldingskjede/lukk';
        req.addParameter('kjedeId', thread.CRM_API_Reference__c);
        req.httpMethod = 'POST';
        req.headers.put('X-Correlation-ID', '123TEST');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvThreadCloseRestService.closeThread();
        Test.stopTest();

        thread = [SELECT Id, CRM_isActive__c, CRM_Last_Edited_By__c FROM Thread__c WHERE ID = :thread.Id];
        System.assertEquals(200, RestContext.response.statusCode);
        System.assertEquals(thread.CRM_Last_Edited_By__c, 'Z999999');
    }

    @isTest
    static void testDmlException() {
        Thread__c thread = [SELECT Id, CRM_API_Reference__c FROM Thread__c LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/meldingskjede/lukk';
        req.addParameter('kjedeId', thread.CRM_API_Reference__c);
        req.httpMethod = 'POST';
        req.headers.put('X-Correlation-ID', '123TEST');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvThreadCloseRestService.simulateException(new DmlException('Something failed'));
        CRM_HenvThreadCloseRestService.closeThread();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
    }

    @isTest
    static void testGenericExceoption() {
        Thread__c thread = [SELECT Id, CRM_API_Reference__c FROM Thread__c LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/meldingskjede/lukk';
        req.addParameter('kjedeId', thread.CRM_API_Reference__c);
        req.httpMethod = 'POST';
        req.headers.put('X-Correlation-ID', '123TEST');
        req.headers.put('X-ACTING-NAV-IDENT', 'Z999999');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvThreadCloseRestService.simulateException(new StringException('Something failed'));
        CRM_HenvThreadCloseRestService.closeThread();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
    }
}