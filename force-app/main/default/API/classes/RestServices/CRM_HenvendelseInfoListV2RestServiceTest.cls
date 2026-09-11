@isTest
public class CRM_HenvendelseInfoListV2RestServiceTest {
    private static final String CONV_NOTE_PREFIX = Conversation_Note__c.getSObjectType().getDescribe().getKeyPrefix();
    private static final String SHARED_CHAIN_ID = CONV_NOTE_PREFIX + '123TESTV2';

    @TestSetup
    static void makeData() {
        Person__c dummyPerson = (Person__c) CRM_HENV_TestDataFactory.createRecord(
            new Person__c(Name = '12345678910', INT_ActorId__c = '123456789101213')
        );

        Contact personCon = [SELECT Id, AccountId FROM Contact WHERE Account.CRM_Person__c = :dummyPerson.Id LIMIT 1];

        // Both conversation notes share the same BehandlingskjedeId, so v1 would merge them
        // into a single henvendelse. V2 must keep them as two separate henvendelser.
        Conversation_Note__c convNoteA = (Conversation_Note__c) CRM_HENV_TestDataFactory.createRecord(
            new Conversation_Note__c(
                CRM_Account__c = personCon.AccountId,
                CRM_Henvendelse_BehandlingskjedeId__c = SHARED_CHAIN_ID
            )
        );
        Conversation_Note__c convNoteB = (Conversation_Note__c) CRM_HENV_TestDataFactory.createRecord(
            new Conversation_Note__c(
                CRM_Account__c = personCon.AccountId,
                CRM_Henvendelse_BehandlingskjedeId__c = SHARED_CHAIN_ID
            )
        );
        Thread__c thread = (Thread__c) CRM_HENV_TestDataFactory.createRecord(
            new Thread__c(
                CRM_Thread_Type__c = 'STO',
                CRM_Type__c = 'STO',
                CRM_Contact__c = personCon.Id,
                CRM_Account__c = personCon.AccountId
            )
        );
        CRM_HENV_TestDataFactory.createRecord(
            new Message__c(CRM_Thread__c = thread.Id, CRM_Message_Text__c = 'DUMMY TEXT')
        );

        List<Journal_Entry__c> jeList = new List<Journal_Entry__c>();
        jeList.add(new Journal_Entry__c(CRM_Conversation_Note__c = convNoteA.Id));
        jeList.add(new Journal_Entry__c(CRM_Conversation_Note__c = convNoteB.Id));
        jeList.add(new Journal_Entry__c(CRM_Thread__c = thread.Id));
        CRM_HENV_TestDataFactory.createRecordList(jeList);
    }

    @isTest
    static void testGetHenvendelseListReturnsUngroupedConversationNotes() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/henvendelseinfo/henvendelseliste/v2';
        req.httpMethod = 'GET';
        req.params.put('aktorid', '123456789101213');
        req.headers.put('x-correlation-id', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseInfoListV2RestService.getHenvendelseList();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);

        CRM_PaginatedHenvendelseResponse paginatedResp = (CRM_PaginatedHenvendelseResponse) JSON.deserialize(
            RestContext.response.responseBody.toString(),
            CRM_PaginatedHenvendelseResponse.class
        );
        System.assertNotEquals(null, paginatedResp, 'Response should be paginated');
        System.assertEquals(1, paginatedResp.currentPage, 'Default page should be 1');
        System.assertEquals(50, paginatedResp.pageSize, 'Default page size should be 50');
        System.assertEquals(1, paginatedResp.totalPages, 'Total pages should be 1');
        System.assertEquals(
            3,
            paginatedResp.data.size(),
            'Should return 3 separate henvendelser: 2 conversation notes (same chain id, not merged) + 1 thread'
        );

        Integer sharedChainIdCount = 0;
        for (CRM_Henvendelse henv : paginatedResp.data) {
            if (henv.kjedeId == SHARED_CHAIN_ID) {
                sharedChainIdCount++;
                System.assertEquals(
                    1,
                    henv.meldinger.size(),
                    'Each ungrouped conversation note should carry only its own message'
                );
            }
        }
        System.assertEquals(
            2,
            sharedChainIdCount,
            'Both conversation notes sharing a chain id should appear as separate henvendelser'
        );
    }

    @isTest
    static void testGetHenvendelseListQueryException() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/henvendelseinfo/henvendelseliste/v2';
        req.httpMethod = 'GET';
        req.params.put('aktorid', '123456789101213');
        req.headers.put('x-correlation-id', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        //Simulating exception from selector call
        CRM_ApiSelector.simulateException(new QueryException('DUMMY ERROR'));
        CRM_HenvendelseInfoListV2RestService.getHenvendelseList();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
    }

    @isTest
    static void testGetHenvendelseListException() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/henvendelseinfo/henvendelseliste/v2';
        req.httpMethod = 'GET';
        req.params.put('aktorid', '123456789101213');
        req.headers.put('x-correlation-id', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        //Simulating exception from selector call
        CRM_ApiSelector.simulateException(new JSONException('DUMMY ERROR'));
        CRM_HenvendelseInfoListV2RestService.getHenvendelseList();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
    }

    @isTest
    static void testGetHenvendelseListFlsException() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/henvendelseinfo/henvendelseliste/v2';
        req.httpMethod = 'GET';
        req.params.put('aktorid', '123456789101213');
        req.headers.put('x-correlation-id', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        //Simulating exception from selector call
        CRM_ApiSelector.simulateException(new fflib_SecurityUtils.FlsException('DUMMY ERROR'));
        CRM_HenvendelseInfoListV2RestService.getHenvendelseList();
        Test.stopTest();

        System.assertEquals(403, RestContext.response.statusCode);
    }

    @isTest
    static void testMissingActorIdInput() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/henvendelseinfo/henvendelseliste/v2';
        req.httpMethod = 'GET';
        req.headers.put('x-correlation-id', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseInfoListV2RestService.getHenvendelseList();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testPaginationFirstPage() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/henvendelseinfo/henvendelseliste/v2';
        req.httpMethod = 'GET';
        req.params.put('aktorid', '123456789101213');
        req.params.put('page', '1');
        req.params.put('pageSize', '2');
        req.headers.put('x-correlation-id', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseInfoListV2RestService.getHenvendelseList();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);

        CRM_PaginatedHenvendelseResponse paginatedResp = (CRM_PaginatedHenvendelseResponse) JSON.deserialize(
            RestContext.response.responseBody.toString(),
            CRM_PaginatedHenvendelseResponse.class
        );

        System.assertEquals(1, paginatedResp.currentPage, 'Current page should be 1');
        System.assertEquals(2, paginatedResp.pageSize, 'Page size should be 2');
        System.assertEquals(2, paginatedResp.data.size(), 'Should return 2 records');
        System.assertEquals(2, paginatedResp.totalPages, 'Total pages should be 2 (3 records / pageSize 2)');
        System.assertEquals(true, paginatedResp.hasNextPage, 'Should have next page');
    }

    @isTest
    static void testPaginationSecondPage() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/henvendelseinfo/henvendelseliste/v2';
        req.httpMethod = 'GET';
        req.params.put('aktorid', '123456789101213');
        req.params.put('page', '2');
        req.params.put('pageSize', '2');
        req.headers.put('x-correlation-id', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseInfoListV2RestService.getHenvendelseList();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);

        CRM_PaginatedHenvendelseResponse paginatedResp = (CRM_PaginatedHenvendelseResponse) JSON.deserialize(
            RestContext.response.responseBody.toString(),
            CRM_PaginatedHenvendelseResponse.class
        );

        System.assertEquals(2, paginatedResp.currentPage, 'Current page should be 2');
        System.assertEquals(2, paginatedResp.pageSize, 'Page size should be 2');
        System.assertEquals(1, paginatedResp.data.size(), 'Should return the remaining 1 record');
        System.assertEquals(2, paginatedResp.totalPages, 'Total pages should be 2');
        System.assertEquals(false, paginatedResp.hasNextPage, 'Should not have next page');
    }

    @isTest
    static void testPaginationDefaultPageNumber() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/henvendelseinfo/henvendelseliste/v2';
        req.httpMethod = 'GET';
        req.params.put('aktorid', '123456789101213');
        req.params.put('pageSize', '10');
        req.headers.put('x-correlation-id', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseInfoListV2RestService.getHenvendelseList();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);

        CRM_PaginatedHenvendelseResponse paginatedResp = (CRM_PaginatedHenvendelseResponse) JSON.deserialize(
            RestContext.response.responseBody.toString(),
            CRM_PaginatedHenvendelseResponse.class
        );

        System.assertEquals(1, paginatedResp.currentPage, 'Default page should be 1');
        System.assertEquals(10, paginatedResp.pageSize, 'Page size should be 10');
        System.assertEquals(1, paginatedResp.totalPages, 'Total pages should be 1');
    }

    @isTest
    static void testPaginationDefaultPageSize() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/henvendelseinfo/henvendelseliste/v2';
        req.httpMethod = 'GET';
        req.params.put('aktorid', '123456789101213');
        req.params.put('page', '1');
        req.headers.put('x-correlation-id', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseInfoListV2RestService.getHenvendelseList();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);

        CRM_PaginatedHenvendelseResponse paginatedResp = (CRM_PaginatedHenvendelseResponse) JSON.deserialize(
            RestContext.response.responseBody.toString(),
            CRM_PaginatedHenvendelseResponse.class
        );

        System.assertEquals(1, paginatedResp.currentPage, 'Page should be 1');
        System.assertEquals(50, paginatedResp.pageSize, 'Default page size should be 50');
        System.assertEquals(1, paginatedResp.totalPages, 'Total pages should be 1');
    }

    @isTest
    static void testPaginationInvalidPageNumber() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/henvendelseinfo/henvendelseliste/v2';
        req.httpMethod = 'GET';
        req.params.put('aktorid', '123456789101213');
        req.params.put('page', '0');
        req.params.put('pageSize', '10');
        req.headers.put('x-correlation-id', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseInfoListV2RestService.getHenvendelseList();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Page number must be greater than 0'));
    }

    @isTest
    static void testPaginationInvalidPageSizeTooSmall() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/henvendelseinfo/henvendelseliste/v2';
        req.httpMethod = 'GET';
        req.params.put('aktorid', '123456789101213');
        req.params.put('page', '1');
        req.params.put('pageSize', '0');
        req.headers.put('x-correlation-id', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseInfoListV2RestService.getHenvendelseList();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Page size must be between 1 and 200'));
    }

    @isTest
    static void testPaginationInvalidPageSizeTooLarge() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/henvendelseinfo/henvendelseliste/v2';
        req.httpMethod = 'GET';
        req.params.put('aktorid', '123456789101213');
        req.params.put('page', '1');
        req.params.put('pageSize', '201');
        req.headers.put('x-correlation-id', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseInfoListV2RestService.getHenvendelseList();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
        System.assert(RestContext.response.responseBody.toString().contains('Page size must be between 1 and 200'));
    }

    @isTest
    static void testPaginationEmptyPage() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getOrgDomainUrl().toExternalForm() + '/services/apexrest/henvendelseinfo/henvendelseliste/v2';
        req.httpMethod = 'GET';
        req.params.put('aktorid', '123456789101213');
        req.params.put('page', '10');
        req.params.put('pageSize', '10');
        req.headers.put('x-correlation-id', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseInfoListV2RestService.getHenvendelseList();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);

        CRM_PaginatedHenvendelseResponse paginatedResp = (CRM_PaginatedHenvendelseResponse) JSON.deserialize(
            RestContext.response.responseBody.toString(),
            CRM_PaginatedHenvendelseResponse.class
        );

        System.assertEquals(0, paginatedResp.data.size(), 'Should return empty list');
        System.assertEquals(1, paginatedResp.totalPages, 'Total pages should still reflect available data');
        System.assertEquals(false, paginatedResp.hasNextPage, 'Should not have next page');
    }
}
