@isTest
public with sharing class CRM_MessageHelperExperienceTest {
    @TestSetup
    static void makeData() {
        Account acc = new Account();
        acc.Name = 'Test account2';
        insert acc;

        Thread__c t = new Thread__c();
        t.CRM_Related_Object__c = acc.Id;

        Thread__c t2 = new Thread__c();
        t2.CRM_Related_Object__c = acc.Id;

        Thread__c t3 = new Thread__c();
        t3.CRM_Related_Object__c = acc.Id;

        CRM_HENV_TestDataFactory.createRecordList(new List<Thread__c>{ t, t2, t3 });

        Message__c m = new Message__c();
        m.CRM_Thread__c = t.Id;
        m.CRM_Message_Text__c = 'Lorem Ipsum Dolor Si Amet';
        insert m;
    }

    @isTest
    static void getMessagesFromThreadTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        List<Message__c> msgList = CRM_MessageHelperExperience.getMessagesFromThread(tList.get(0).Id);
        Test.stopTest();
        System.assertEquals(1, msgList.size());
    }

    @isTest
    static void markasreadTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        CRM_MessageHelperExperience.markAsRead(tList.get(0).Id);
        Test.stopTest();
        List<Message__c> msgList = [SELECT CRM_Read__c FROM Message__c WHERE CRM_Thread__c = :tList.get(0).Id];
        System.assertEquals(true, msgList.get(0).CRM_Read__c);
    }

    @isTest
    static void createMessageTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        CRM_MessageHelperExperience.createMessage(tList.get(0).Id, 'Some text value', null);
        Test.stopTest();
        List<Message__c> msgList = [SELECT CRM_Read__c FROM Message__c WHERE CRM_Thread__c = :tList.get(0).Id];
        System.assertEquals(msgList.isEmpty(), false);
    }
}
