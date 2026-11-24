@IsTest
private class CRM_QuickTextMergeResolver_Test {
    @IsTest
    static void resolvesAccountWithoutParsingReplacementValues() {
        Account account = new Account(Name = 'Ada <Example> ${literal}');
        insert account;
        List<QuickText> templates = new List<QuickText>{
            new QuickText(Message = 'Hello ${Account.Name}. ${Account.Name}'),
            new QuickText(Message = '${Account.Phone}'),
            new QuickText(Message = 'Unchanged'),
            new QuickText(Message = '${Account.Name')
        };
        Test.startTest();
        CRM_QuickTextMergeResolver resolver = new CRM_QuickTextMergeResolver(new List<Id>{ account.Id });
        List<QuickText> result = resolver.resolve(templates);
        Test.stopTest();
        System.assertEquals(3, result.size());
        System.assertEquals('Hello ' + account.Name + '. ' + account.Name, result[0].Message);
        System.assertEquals('Unchanged', result[1].Message);
        System.assertEquals('${Account.Name', result[2].Message);
        System.assertEquals('Hello ${Account.Name}. ${Account.Name}', templates[0].Message);
    }

    @IsTest
    static void excludesUnavailableContext() {
        List<QuickText> templates = new List<QuickText>{
            new QuickText(Message = '${Account.Name}'),
            new QuickText(Message = '${User.Name}'),
            new QuickText(Message = 'Ordinary text')
        };
        List<QuickText> result = new CRM_QuickTextMergeResolver(null).resolve(templates);
        System.assertEquals(1, result.size());
        System.assertEquals('Ordinary text', result[0].Message);
    }

    @IsTest
    static void rejectsAmbiguousTypesButDeduplicatesIdenticalIds() {
        Id firstAccount = '001000000000001';
        Id secondAccount = '001000000000002';
        Test.startTest();
        Map<String, Id> ambiguous = CRM_QuickTextMergeResolver.buildContext(
            new List<Id>{ firstAccount, secondAccount }
        );
        Map<String, Id> repeated = CRM_QuickTextMergeResolver.buildContext(new List<Id>{ firstAccount, firstAccount });
        Test.stopTest();
        System.assertEquals(false, ambiguous.containsKey('Account'));
        System.assertEquals(UserInfo.getUserId(), ambiguous.get('User'));
        System.assertEquals(firstAccount, repeated.get('Account'));
    }

    @IsTest
    static void currentUserCannotBeOverridden() {
        Map<String, Id> context = CRM_QuickTextMergeResolver.buildContext(
            new List<Id>{ '005000000000001', '005000000000002', UserInfo.getUserId() }
        );
        System.assertEquals(1, context.size());
        System.assertEquals(UserInfo.getUserId(), context.get('User'));
    }

    @IsTest
    static void rejectsMoreThanThreeInputIds() {
        try {
            CRM_QuickTextMergeResolver.buildContext(
                new List<Id>{ UserInfo.getUserId(), UserInfo.getUserId(), UserInfo.getUserId(), UserInfo.getUserId() }
            );
            System.assert(false, 'Expected input limit validation.');
        } catch (AuraHandledException expected) {
            System.assertNotEquals(null, expected);
        }
    }

    @IsTest
    static void rejectsNullId() {
        try {
            CRM_QuickTextMergeResolver.buildContext(new List<Id>{ null });
            System.assert(false, 'Expected null ID validation.');
        } catch (AuraHandledException expected) {
            System.assertNotEquals(null, expected);
        }
    }

    @IsTest
    static void resolvesStringsAndMessages() {
        Account account = new Account(Name = 'Ada');
        insert account;
        Id templateId = '0F9000000000001';
        CRM_HenvendelseQuicktextController.QuickTextMessage message = new CRM_HenvendelseQuicktextController.QuickTextMessage(
            templateId,
            'Greeting',
            'Hello ${Account.Name}'
        );
        CRM_HenvendelseQuicktextController.QuickTextMessage unavailable = new CRM_HenvendelseQuicktextController.QuickTextMessage(
            null,
            'Unavailable',
            '${Account.Phone}'
        );
        Test.startTest();
        CRM_QuickTextMergeResolver resolver = new CRM_QuickTextMergeResolver(new List<Id>{ account.Id });
        String single = resolver.resolve('Hello ${Account.Name}');
        List<String> strings = resolver.resolve(
            new List<String>{ '${Account.Phone}', '${Account.Name}', 'Ordinary', '${Account.Name}' }
        );
        CRM_HenvendelseQuicktextController.QuickTextMessage resolved = resolver.resolve(message);
        List<CRM_HenvendelseQuicktextController.QuickTextMessage> messages = resolver.resolve(
            new List<CRM_HenvendelseQuicktextController.QuickTextMessage>{ unavailable, message, message }
        );
        Test.stopTest();
        System.assertEquals('Hello Ada', single);
        System.assertEquals(new List<String>{ 'Ada', 'Ordinary', 'Ada' }, strings);
        System.assertEquals(2, messages.size());
        System.assertEquals(templateId, resolved.RecordId);
        System.assertEquals('Greeting', resolved.Name);
        System.assertEquals('Hello Ada', resolved.Message);
        System.assertEquals('Hello Ada', resolved.Summary);
        System.assertEquals(resolved.Message, messages[0].Message);
        System.assertEquals('Hello ${Account.Name}', message.Message);
        System.assertEquals('Hello ${Account.Name}', message.Summary);
    }

    @IsTest
    static void singleResolvePropagatesMissingValue() {
        CRM_QuickTextMergeResolver resolver = new CRM_QuickTextMergeResolver(null);
        try {
            resolver.resolve('${Account.Name}');
            System.assert(false, 'Expected missing value exception.');
        } catch (StringException expected) {
            System.assert(expected.getMessage().contains('Account.Name'));
        }
        System.assertEquals(0, resolver.resolve(new List<String>()).size());
        System.assertEquals(0, resolver.resolve(new List<QuickText>()).size());
        System.assertEquals(
            0,
            resolver.resolve(new List<CRM_HenvendelseQuicktextController.QuickTextMessage>()).size()
        );
    }
}
