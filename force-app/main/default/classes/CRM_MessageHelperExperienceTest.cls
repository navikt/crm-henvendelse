@isTest
public with sharing class CRM_MessageHelperExperienceTest {
    @TestSetup
    static void makeData() {
        Account acc = new Account(Name = 'Test account2');
        insert acc;

        Thread__c t = new Thread__c(
            CRM_Related_Object__c = acc.Id,
            Name = 'Test Thread With Messages',
            CRM_isActive__c = true
        );
        Thread__c t2 = new Thread__c(CRM_Related_Object__c = acc.Id, CRM_isActive__c = true);
        Thread__c t3 = new Thread__c(CRM_Related_Object__c = acc.Id, CRM_isActive__c = true);
        insert new List<Thread__c>{ t, t2, t3 };

        t = [SELECT Id FROM Thread__c WHERE Name = 'Test Thread With Messages' LIMIT 1];

        List<Message__c> messages = new List<Message__c>();
        Id testContactId = CRM_HENV_TestDataFactory.createRecord('Contact', null);

        // External Message 1
        messages.add(
            new Message__c(
                CRM_Thread__c = t.Id,
                CRM_Message_Text__c = 'Hello from external 1',
                CRM_From_Contact__c = testContactId,
                CRM_External_Message__c = true,
                CRM_Sent_date__c = DateTime.now().addMinutes(-40)
            )
        );

        // External Message 2 (same sender group)
        messages.add(
            new Message__c(
                CRM_Thread__c = t.Id,
                CRM_Message_Text__c = 'Hello again from external',
                CRM_From_Contact__c = testContactId,
                CRM_External_Message__c = true,
                CRM_Sent_date__c = DateTime.now().addMinutes(-35)
            )
        );

        // Internal Message (should start new group)
        messages.add(
            new Message__c(
                CRM_Thread__c = t.Id,
                CRM_Message_Text__c = 'Reply from internal user',
                CRM_External_Message__c = false,
                CRM_Sent_date__c = DateTime.now().addMinutes(-30)
            )
        );

        // Event block (should create event block)
        messages.add(
            new Message__c(
                CRM_Thread__c = t.Id,
                CRM_Message_Text__c = 'Event occurred',
                CRM_Type__c = 'Event',
                CRM_External_Message__c = false,
                CRM_Sent_date__c = DateTime.now().addMinutes(-25)
            )
        );

        // Null message (should be skipped)
        messages.add(
            new Message__c(
                CRM_Thread__c = t.Id,
                CRM_Message_Text__c = null,
                CRM_Sent_date__c = DateTime.now().addMinutes(-20)
            )
        );

        // External Message (new group again)
        messages.add(
            new Message__c(
                CRM_Thread__c = t.Id,
                CRM_Message_Text__c = 'External follow-up',
                CRM_From_Contact__c = testContactId,
                CRM_External_Message__c = true,
                CRM_Sent_date__c = DateTime.now().addMinutes(-10)
            )
        );

        insert messages;
    }

    @isTest
    static void getMessagesFromThreadTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CreatedDate DESC];
        Test.startTest();
        List<Message__c> msgList = CRM_MessageHelperExperience.getMessagesFromThread(tList.get(0).Id);
        Test.stopTest();
        Assert.areEqual(5, msgList.size(), 'Should return 5 non-null messages.');
    }

    @isTest
    static void markAsReadTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CreatedDate DESC];
        Test.startTest();
        CRM_MessageHelperExperience.markAsRead(tList.get(0).Id);
        Test.stopTest();
        List<Message__c> msgList = [SELECT CRM_Read__c FROM Message__c WHERE CRM_Thread__c = :tList.get(0).Id];
        Assert.areEqual(true, msgList.get(0).CRM_Read__c, 'First message should be marked as read.');
    }

    @isTest
    static void createMessageTest() {
        List<Thread__c> tList = [SELECT Id FROM Thread__c ORDER BY CreatedDate DESC];
        Test.startTest();
        Boolean result = CRM_MessageHelperExperience.createMessage(tList.get(0).Id, 'Some text value', null);
        Test.stopTest();
        Assert.isTrue(result, 'Should return true for active thread');
        List<Message__c> msgList = [
            SELECT Id, CRM_Message_Text__c
            FROM Message__c
            WHERE CRM_Thread__c = :tList.get(0).Id
        ];
        Boolean found = false;
        for (Message__c m : msgList) {
            if (m.CRM_Message_Text__c == 'Some text value') {
                found = true;
                break;
            }
        }
        Assert.isTrue(found, 'Created message should exist.');
    }

    @isTest
    static void testGetGroupedMessagesFromThread() {
        Id threadId = [SELECT Id FROM Thread__c WHERE Name = 'Test Thread With Messages' LIMIT 1]?.Id;
        Test.startTest();
        List<CRM_MessageHelperExperience.MessageGroupWrapper> grouped = CRM_MessageHelperExperience.getGroupedMessagesFromThread(
            threadId
        );
        Test.stopTest();

        Assert.areEqual(4, grouped.size(), 'Expected 4 blocks: external, internal, event, external');

        // Block 1: external group (2 messages)
        Assert.areEqual('group', grouped[0].type, 'First block should be a group');
        Assert.areEqual(true, grouped[0].groupIsExternal, 'First group should be external');
        Assert.areEqual(2, grouped[0].groupMessages.size(), 'First group should have 2 messages');
        Assert.areEqual(true, grouped[0].groupMessages[0].showHeader, 'First message should show header');
        Assert.areEqual(false, grouped[0].groupMessages[1].showHeader, 'Second message should not show header');

        // Block 2: internal group (1 message)
        Assert.areEqual('group', grouped[1].type, 'Second block should be a group');
        Assert.areEqual(false, grouped[1].groupIsExternal, 'Second group should be internal');
        Assert.areEqual(1, grouped[1].groupMessages.size(), 'Second group should have 1 message');
        Assert.areEqual(true, grouped[1].groupMessages[0].showHeader, 'Only message should show header');

        // Block 3: event block
        Assert.areEqual('event', grouped[2].type, 'Third block should be an event');
        Assert.areEqual(false, grouped[2].eventIsExternal, 'Event block should be internal');
        Assert.areEqual(
            'Event occurred',
            grouped[2].eventMessage.CRM_Message_Text__c,
            'Event message text should match'
        );
        Assert.areEqual(false, grouped[2].eventIsExternal, 'Event block should be internal');

        // Block 4: external group (1 message)
        Assert.areEqual('group', grouped[3].type, 'Fourth block should be a group');
        Assert.areEqual(true, grouped[3].groupIsExternal, 'Fourth group should be external');
        Assert.areEqual(1, grouped[3].groupMessages.size(), 'Fourth group should have 1 message');
        Assert.areEqual(true, grouped[3].groupMessages[0].showHeader, 'Only message should show header');
    }
}
