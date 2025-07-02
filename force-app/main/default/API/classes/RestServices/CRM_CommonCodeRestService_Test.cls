@isTest
public class CRM_CommonCodeRestService_Test {
    @TestSetup
    static void makeData() {
        CRM_HENV_TestDataFactory.createRecord(
            new Common_Code__c(CRM_Code__c = 'ARBD', CRM_Code_Set__c = 'Temagrupper', Name = 'Arbeid')
        );
    }

    @isTest
    static void testGetThemeGroups() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/kodeverk/temagrupper';
        req.httpMethod = 'GET';
        req.headers.put('X-Correlation-ID', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_CommonCodeRestService.getThemeGroups();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testException() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelse/kodeverk/temagrupper';
        req.httpMethod = 'GET';
        req.headers.put('X-Correlation-ID', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_CommonCodeRestService.simulateException(new QueryException('TEST'));
        CRM_CommonCodeRestService.getThemeGroups();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
    }
}
