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

    @IsTest
    static void emptyContextFiltersMergeTemplatesAndPreservesOrdinaryText() {
        QuickText mergeTemplate = new QuickText(
            Name = 'Context merge',
            Message = '${Account.Name}',
            nksType__c = 'Abbreviation',
            nksAbbreviationKey__c = 'merge'
        );
        QuickText ordinary = new QuickText(
            Name = 'Context ordinary',
            Message = 'Ordinary text',
            nksType__c = 'Abbreviation',
            nksAbbreviationKey__c = 'ordinary'
        );
        insert new List<QuickText>{ mergeTemplate, ordinary };
        Test.startTest();
        List<CRM_HenvendelseQuicktextController.QuickTextMessage> legacySearch = CRM_HenvendelseQuicktextController.searchRecords(
            'Context'
        );
        List<CRM_HenvendelseQuicktextController.QuickTextMessage> emptySearch = CRM_HenvendelseQuicktextController.searchContextRecords(
            'Context',
            new List<Id>()
        );
        List<CRM_HenvendelseQuicktextController.QuickTextMessage> nullSearch = CRM_HenvendelseQuicktextController.searchContextRecords(
            'Context',
            null
        );
        List<QuickText> legacyAbbreviations = CRM_HenvendelseQuicktextController.getQuicktexts();
        List<QuickText> emptyAbbreviations = CRM_HenvendelseQuicktextController.getContextQuicktexts(new List<Id>());
        List<QuickText> nullAbbreviations = CRM_HenvendelseQuicktextController.getContextQuicktexts(null);
        Test.stopTest();
        System.assertEquals(1, emptySearch.size());
        System.assertEquals(ordinary.Id, emptySearch[0].RecordId);
        System.assertEquals('Ordinary text', emptySearch[0].Message);
        System.assertEquals('Ordinary text', emptySearch[0].Summary);
        System.assertEquals(JSON.serialize(emptySearch), JSON.serialize(nullSearch));
        System.assertEquals(1, emptyAbbreviations.size());
        System.assertEquals(ordinary.Id, emptyAbbreviations[0].Id);
        System.assertEquals('Ordinary text', emptyAbbreviations[0].Message);
        System.assertEquals(JSON.serialize(emptyAbbreviations), JSON.serialize(nullAbbreviations));
        System.assertEquals(2, legacySearch.size());
        System.assertEquals(2, legacyAbbreviations.size());
        System.assertEquals('${Account.Name}', [SELECT Message FROM QuickText WHERE Id = :mergeTemplate.Id].Message);
    }
}
