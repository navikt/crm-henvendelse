@isTest
public class CRM_ConversationNoteSelector_Test {
    @TestSetup
    static void makeData() {
        Person__c person = (Person__c) CRM_HENV_TestDataFactory.createRecord(
            new Person__c(Name = '12345678910', INT_ActorId__c = '123456789121314')
        );
        Account acc = (Account) CRM_HENV_TestDataFactory.createRecord(new Account(CRM_Person__c = person.Id));
        CRM_HENV_TestDataFactory.createRecord(
            new Conversation_Note__c(CRM_Account__c = acc.Id, CRM_Henvendelse_BehandlingsId__c = '123TEST')
        );
    }

    @isTest
    static void testSelector() {
        Test.startTest();
        List<Conversation_Note__c> convList = new CRM_ConversationNoteSelector()
            .selectByActorId(new Set<String>{ '123456789121314' }, null);
        Test.stopTest();

        System.assert(!convList.isEmpty());

        Conversation_Note__c convNote = new CRM_ConversationNoteSelector().selectById(convList[0].Id);

        System.assertNotEquals(null, convNote);
    }
}
