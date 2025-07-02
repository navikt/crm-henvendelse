@isTest
public class CRM_HenvendelseinfoRestService_Test {
    private static final String THREAD_PREFIX = Thread__c.getSObjectType().getDescribe().getKeyPrefix();
    private static final String CONV_NOTE_PREFIX = Conversation_Note__c.getSObjectType().getDescribe().getKeyPrefix();

    @TestSetup
    static void makeData() {
        Person__c dummyPerson = (Person__c) CRM_HENV_TestDataFactory.createRecord(
            new Person__c(Name = '12345678910', INT_ActorId__c = '123456789101213')
        );

        Contact personCon = [SELECT Id, AccountId FROM Contact WHERE Account.CRM_Person__c = :dummyPerson.Id LIMIT 1];

        Conversation_Note__c convNote = (Conversation_Note__c) CRM_HENV_TestDataFactory.createRecord(
            new Conversation_Note__c(
                CRM_Account__c = personCon.AccountId,
                CRM_Henvendelse_BehandlingskjedeId__c = CONV_NOTE_PREFIX + '1234TEST'
            )
        );
        //Adding a follow up note to the test data
        CRM_HENV_TestDataFactory.createRecord(
            new Conversation_Note__c(
                CRM_Account__c = personCon.AccountId,
                CRM_Henvendelse_BehandlingskjedeId__c = CONV_NOTE_PREFIX + '1234TEST'
            )
        );
        Thread__c thread = (Thread__c) CRM_HENV_TestDataFactory.createRecord(
            new Thread__c(CRM_Contact__c = personCon.Id, CRM_Account__c = personCon.AccountId)
        );

        CRM_HENV_TestDataFactory.createRecord(
            new Message__c(CRM_Thread__c = thread.Id, CRM_Message_Text__c = 'DUMMY TEXT')
        );

        List<Journal_Entry__c> jeList = new List<Journal_Entry__c>();
        jeList.add(new Journal_Entry__c(CRM_Conversation_Note__c = convNote.Id));
        jeList.add(new Journal_Entry__c(CRM_Thread__c = thread.Id));
        CRM_HENV_TestDataFactory.createRecordList(jeList);
    }

    @isTest
    static void testGetConversationNote() {
        Conversation_Note__c convNote = [
            SELECT Id, CRM_Henvendelse_BehandlingskjedeId__c
            FROM Conversation_Note__c
            LIMIT 1
        ];

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() +
            '/services/apexrest/henvendelseinfo/henvendelse/' +
            convNote.CRM_Henvendelse_BehandlingskjedeId__c;
        req.headers.put('X-Correlation-ID', '123TEST');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseinfoRestService.getHenvendelse();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testGetThread() {
        Thread__c thread = [SELECT Id, CRM_API_Reference__c FROM Thread__c LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() +
            '/services/apexrest/henvendelseinfo/henvendelse/' +
            thread.CRM_API_Reference__c;
        req.headers.put('X-Correlation-ID', '123TEST');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseinfoRestService.getHenvendelse();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testInvalidObjextId() {
        String accountRef = [SELECT Id FROM Account LIMIT 1].Id;

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() +
            '/services/apexrest/henvendelseinfo/henvendelse/' +
            accountRef;
        req.headers.put('X-Correlation-ID', '123TEST');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseinfoRestService.getHenvendelse();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testInvalidId() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() +
            '/services/apexrest/henvendelseinfo/henvendelse/' +
            'INVALID';
        req.headers.put('X-Correlation-ID', '123TEST');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseinfoRestService.getHenvendelse();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testException() {
        Thread__c thread = [SELECT Id, CRM_API_Reference__c FROM Thread__c LIMIT 1];

        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() +
            '/services/apexrest/henvendelseinfo/henvendelse/' +
            thread.CRM_API_Reference__c;
        req.headers.put('X-Correlation-ID', '123TEST');
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseinfoRestService.simulateException(new QueryException('TEST'));
        CRM_HenvendelseinfoRestService.getHenvendelse();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
    }
}
