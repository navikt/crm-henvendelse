@isTest
public class CRM_HenvendelseInfoListRestService_Test {
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
                CRM_Henvendelse_BehandlingskjedeId__c = CONV_NOTE_PREFIX + '123TEST'
            )
        );
        CRM_HENV_TestDataFactory.createRecord(
            new Conversation_Note__c(
                CRM_Account__c = personCon.AccountId,
                CRM_Henvendelse_BehandlingskjedeId__c = CONV_NOTE_PREFIX + '123TEST'
            )
        );
        Thread__c thread = (Thread__c) CRM_HENV_TestDataFactory.createRecord(
            new Thread__c(
                CRM_Thread_Type__c = 'STO',
                CRM_Contact__c = personCon.Id,
                CRM_Account__c = personCon.AccountId
            )
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
    static void testGetHenvendelseList() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelseinfo/henvendelseliste';
        req.httpMethod = 'GET';
        req.params.put('aktorid', '123456789101213');
        req.headers.put('X-Correlation-ID', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseInfoListRestService.getHenvendelseList();
        Test.stopTest();

        System.assertEquals(200, RestContext.response.statusCode);
    }

    @isTest
    static void testGetHenvedelseListQueryException() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelseinfo/henvendelseliste';
        req.httpMethod = 'GET';
        req.params.put('aktorid', '123456789101213');
        req.headers.put('X-Correlation-ID', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        //Simulating exception from selector call
        CRM_ApiSelector.simulateException(new QueryException('DUMMY ERROR'));
        CRM_HenvendelseInfoListRestService.getHenvendelseList();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
    }

    @isTest
    static void testGetHenvedelseListException() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelseinfo/henvendelseliste';
        req.httpMethod = 'GET';
        req.params.put('aktorid', '123456789101213');
        req.headers.put('X-Correlation-ID', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        //Simulating exception from selector call
        CRM_ApiSelector.simulateException(new JSONException('DUMMY ERROR'));
        CRM_HenvendelseInfoListRestService.getHenvendelseList();
        Test.stopTest();

        System.assertEquals(500, RestContext.response.statusCode);
    }

    @isTest
    static void testMissingActorIdInput() {
        RestRequest req = new RestRequest();
        RestResponse resp = new RestResponse();

        req.requestURI =
            Url.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/henvendelseinfo/henvendelseliste';
        req.httpMethod = 'GET';
        req.headers.put('X-Correlation-ID', '123TEST');
        RestContext.request = req;
        RestContext.response = resp;

        Test.startTest();
        CRM_HenvendelseInfoListRestService.getHenvendelseList();
        Test.stopTest();

        System.assertEquals(400, RestContext.response.statusCode);
    }
}
