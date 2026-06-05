@isTest
public class CRM_ThreadSelector_Test {
    @TestSetup
    static void makeData() {
        Person__c dummyPerson = (Person__c) CRM_HENV_TestDataFactory.createRecord(
            new Person__c(Name = '12345678910', INT_ActorId__c = '123456789101213')
        );

        Contact personCon = [SELECT Id, AccountId FROM Contact WHERE Account.CRM_Person__c = :dummyPerson.Id LIMIT 1];

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
    }

    @isTest
    static void testSelector() {
        Test.startTest();
        List<Thread__c> threads = new CRM_ThreadSelector().selectByActorId(new Set<String>{ '123456789101213' }, null);
        Test.stopTest();

        System.assert(!threads.isEmpty());
        Thread__c selectedThread = new CRM_ThreadSelector().selectById(threads[0].Id);
        System.assertNotEquals(null, selectedThread);
        threads = new CRM_ThreadSelector().selectByIds(new Set<Id>{ threads[0].Id });
        System.assert(!threads.isEmpty());
    }
}
