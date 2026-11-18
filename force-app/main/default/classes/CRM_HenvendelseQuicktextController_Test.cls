@isTest
public with sharing class CRM_HenvendelseQuicktextController_Test {
    @TestSetup
    static void makeData() {
        CRM_HENV_TestDataFactory.createQuickTexts(3);
    }
    @isTest
    static void searchRecordsTest() {
        Test.startTest();
        List<CRM_HenvendelseQuicktextController.QuickTextMessage> msgList = CRM_HenvendelseQuicktextController.searchRecords(
            'Melding'
        );
        Test.stopTest();
        System.assertEquals(msgList.isempty(), false);
    }
    @isTest
    static void getQuicktext_Test() {
        List<QuickText> qList = CRM_HenvendelseQuicktextController.getQuicktexts();
    }

    @IsTest
    static void contextualRetrievalUsesSharedResolver() {
        Account account = new Account(Name = 'Ada');
        insert account;
        QuickText greeting = new QuickText(
            Name = 'Merge greeting',
            Message = 'Hello ${Account.Name}',
            nksType__c = 'Abbreviation',
            nksAbbreviationKey__c = 'greet'
        );
        QuickText unavailable = new QuickText(
            Name = 'Merge unavailable',
            Message = '${Account.Phone}',
            nksType__c = 'Abbreviation',
            nksAbbreviationKey__c = 'missing'
        );
        insert new List<QuickText>{ greeting, unavailable };
        Test.startTest();
        List<CRM_HenvendelseQuicktextController.QuickTextMessage> searchResults = CRM_HenvendelseQuicktextController.searchContextRecords(
            'Merge',
            new List<Id>{ account.Id }
        );
        List<QuickText> abbreviations = CRM_HenvendelseQuicktextController.getContextQuicktexts(
            new List<Id>{ account.Id }
        );
        List<CRM_HenvendelseQuicktextController.QuickTextMessage> withoutContext = CRM_HenvendelseQuicktextController.searchContextRecords(
            'Merge',
            null
        );
        List<CRM_HenvendelseQuicktextController.QuickTextMessage> legacy = CRM_HenvendelseQuicktextController.searchRecords(
            'Merge'
        );
        Test.stopTest();
        System.assertEquals(1, searchResults.size());
        System.assertEquals(greeting.Id, searchResults[0].RecordId);
        System.assertEquals('Hello Ada', searchResults[0].Message);
        System.assertEquals('Hello Ada', searchResults[0].Summary);
        System.assertEquals(1, abbreviations.size());
        System.assertEquals(greeting.Id, abbreviations[0].Id);
        System.assertEquals('greet', abbreviations[0].nksAbbreviationKey__c);
        System.assertEquals(searchResults[0].Message, abbreviations[0].Message);
        System.assertEquals(0, withoutContext.size());
        System.assertEquals(2, legacy.size());
        System.assertEquals('Hello ${Account.Name}', [SELECT Message FROM QuickText WHERE Id = :greeting.Id].Message);
    }
}
