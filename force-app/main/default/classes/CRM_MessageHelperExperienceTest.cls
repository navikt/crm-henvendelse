@isTest
public with sharing class CRM_MessageHelperExperienceTest {
    @TestSetup
    static void makeData() {
        Account acc = new Account();
        acc.Name = 'Test account2';
        insert acc;

        Thread__c t = new Thread__c();
        t.CRM_Related_Object__c = acc.Id;
        t.Name = 'Test Thread With Messages';

        Thread__c t2 = new Thread__c();
        t2.CRM_Related_Object__c = acc.Id;

        Thread__c t3 = new Thread__c();
        t3.CRM_Related_Object__c = acc.Id;

        CRM_HENV_TestDataFactory.createRecordList(new List<Thread__c>{ t, t2, t3 });

        List<Message__c> messages = new List<Message__c>();
        Id testContactId = CRM_HENV_TestDataFactory.createRecord('Contact', null);

        // External Message 1
        messages.add(
            new Message__c(
                CRM_Thread__c = t.Id,
                CRM_Message_Text__c = 'Hello from external 1',
                CRM_From_Contact__c = testContactId,
                CRM_Sent_date__c = DateTime.now().addMinutes(-30)
            )
        );

        // External Message 2 (same sender group)
        messages.add(
            new Message__c(
                CRM_Thread__c = t.Id,
                CRM_Message_Text__c = 'Hello again from external',
                CRM_From_Contact__c = testContactId,
                CRM_Sent_date__c = DateTime.now().addMinutes(-25)
            )
        );

        // Internal Message (should start new group)
        messages.add(
            new Message__c(
                CRM_Thread__c = t.Id,
                CRM_Message_Text__c = 'Reply from internal user',
                CRM_Sent_date__c = DateTime.now().addMinutes(-20)
            )
        );

        // Null message (should be skipped)
        messages.add(
            new Message__c(
                CRM_Thread__c = t.Id,
                CRM_Message_Text__c = null,
                CRM_Sent_date__c = DateTime.now().addMinutes(-15)
            )
        );

        // External Message (new group again)
        messages.add(
            new Message__c(
                CRM_Thread__c = t.Id,
                CRM_Message_Text__c = 'External follow-up',
                CRM_From_Contact__c = testContactId,
                CRM_Sent_date__c = DateTime.now().addMinutes(-10)
            )
        );
        insert messages;
    }

    @isTest
    static void getMessagesFromThreadTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        List<Message__c> msgList = CRM_MessageHelperExperience.getMessagesFromThread(tList.get(0).Id);
        Test.stopTest();
        Assert.areEqual(4, msgList.size());
    }

    @isTest
    static void markasreadTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        CRM_MessageHelperExperience.markAsRead(tList.get(0).Id);
        Test.stopTest();
        List<Message__c> msgList = [SELECT CRM_Read__c FROM Message__c WHERE CRM_Thread__c = :tList.get(0).Id];
        Assert.areEqual(true, msgList.get(0).CRM_Read__c);
    }

    @isTest
    static void createMessageTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CRM_Number_of_External_Messages__c DESC];
        Test.startTest();
        CRM_MessageHelperExperience.createMessage(tList.get(0).Id, 'Some text value', null);
        Test.stopTest();
        List<Message__c> msgList = [SELECT CRM_Read__c FROM Message__c WHERE CRM_Thread__c = :tList.get(0).Id];
        Assert.areEqual(msgList.isEmpty(), false);
    }

    @isTest
    static void testGetGroupedMessagesFromThread() {
        Id threadId = [SELECT Id FROM Thread__c WHERE Name = 'Test Thread With Messages' LIMIT 1]?.Id;

        Test.startTest();
        List<CRM_MessageHelperExperience.MessageGroupWrapper> grouped = CRM_MessageHelperExperience.getGroupedMessagesFromThread(
            threadId
        );
        Test.stopTest();

        Assert.areEqual(3, grouped.size(), 'Expected 3 groups: external, internal, external');

        // Validate group 1
        Assert.areEqual('group', grouped[0].type, 'First block should be a group');
        Assert.areEqual(true, grouped[0].groupIsExternal, 'First group should be external');
        Assert.areEqual(2, grouped[0].groupMessages.size(), 'First group should have 2 messages');
        Assert.areEqual(true, grouped[0].groupMessages[0].showHeader, 'First message should show header');
        Assert.areEqual(false, grouped[0].groupMessages[1].showHeader, 'Second message should not show header');

        // Validate group 2
        Assert.areEqual('group', grouped[1].type, 'Second block should be a group');
        Assert.areEqual(false, grouped[1].groupIsExternal, 'Second group should be internal');
        Assert.areEqual(1, grouped[1].groupMessages.size(), 'Second group should have 1 message');
        Assert.areEqual(true, grouped[1].groupMessages[0].showHeader, 'Only message should show header');

        // Validate group 3
        Assert.areEqual('group', grouped[2].type, 'Third block should be a group');
        Assert.areEqual(true, grouped[2].groupIsExternal, 'Third group should be external');
        Assert.areEqual(1, grouped[2].groupMessages.size(), 'Third group should have 1 message');
        Assert.areEqual(true, grouped[2].groupMessages[0].showHeader, 'Only message should show header');
    }
}
