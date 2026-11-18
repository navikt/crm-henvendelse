public with sharing class CRM_QuickTextMergeResolver {
    private static final Integer MAX_CONTEXT_IDS = 3;

    private final Map<String, Object> values;

    public CRM_QuickTextMergeResolver(List<Id> contextRecordIds) {
        values = loadValues(buildContext(contextRecordIds));
    }

    public String resolve(String text) {
        return text.template(values);
    }

    public QuickText resolve(QuickText text) {
        QuickText result = text.clone(true, false, false, false);
        result.Message = resolve(text.Message);
        return result;
    }

    public CRM_HenvendelseQuicktextController.QuickTextMessage resolve(
        CRM_HenvendelseQuicktextController.QuickTextMessage text
    ) {
        return new CRM_HenvendelseQuicktextController.QuickTextMessage(text.RecordId, text.Name, resolve(text.Message));
    }

    public List<String> resolve(List<String> templates) {
        List<String> resolved = new List<String>();
        for (Integer index = 0; index < templates.size(); index++) {
            try {
                resolved.add(resolve(templates[index]));
            } catch (StringException error) {
                logExclusion('string index ' + index);
            }
        }
        return resolved;
    }

    public List<QuickText> resolve(List<QuickText> templates) {
        List<QuickText> resolved = new List<QuickText>();
        for (QuickText text : templates) {
            try {
                resolved.add(resolve(text));
            } catch (StringException error) {
                logExclusion('QuickText ID ' + text.Id);
            }
        }
        return resolved;
    }

    public List<CRM_HenvendelseQuicktextController.QuickTextMessage> resolve(
        List<CRM_HenvendelseQuicktextController.QuickTextMessage> templates
    ) {
        List<CRM_HenvendelseQuicktextController.QuickTextMessage> resolved = new List<CRM_HenvendelseQuicktextController.QuickTextMessage>();
        for (CRM_HenvendelseQuicktextController.QuickTextMessage text : templates) {
            try {
                resolved.add(resolve(text));
            } catch (StringException error) {
                logExclusion('QuickTextMessage ID ' + text.RecordId);
            }
        }
        return resolved;
    }

    private static void logExclusion(String reference) {
        System.debug(LoggingLevel.WARN, 'Quick Text excluded: missing merge value. Template: ' + reference);
    }

    @TestVisible
    private static Map<String, Id> buildContext(List<Id> contextRecordIds) {
        if (contextRecordIds != null && contextRecordIds.size() > MAX_CONTEXT_IDS) {
            throw new AuraHandledException('Quick Text supports at most 3 context IDs.');
        }
        Map<String, Id> context = new Map<String, Id>();
        Set<String> ambiguous = new Set<String>();
        if (contextRecordIds != null) {
            for (Id recordId : new Set<Id>(contextRecordIds)) {
                if (recordId == null) {
                    throw new AuraHandledException('Quick Text context cannot contain a null ID.');
                }
                String objectName = recordId.getSObjectType().getDescribe().getName();
                if (objectName == 'User') {
                    continue;
                }
                if (context.containsKey(objectName)) {
                    ambiguous.add(objectName);
                } else {
                    context.put(objectName, recordId);
                }
            }
        }
        if (!ambiguous.isEmpty()) {
            List<String> objectNames = new List<String>(ambiguous);
            objectNames.sort();
            LoggerUtility logger = new LoggerUtility('Quick Text');
            logger.error(
                'Ambiguous Quick Text context for object types: ' + String.join(objectNames, ', '),
                null,
                CRM_ApplicationDomain.Domain.NKS
            );
            logger.publish();
            for (String objectName : ambiguous) {
                context.remove(objectName);
            }
        }
        context.put('User', UserInfo.getUserId());
        return context;
    }

    private static Map<String, Object> loadValues(Map<String, Id> context) {
        Map<String, Object> values = new Map<String, Object>();
        Map<String, Set<String>> allowed = CRM_QuickTextMergeConfig.allowedFields();
        Map<String, Schema.SObjectType> objectTypes = Schema.getGlobalDescribe();
        for (String objectName : context.keySet()) {
            if (!allowed.containsKey(objectName)) {
                continue;
            }
            Schema.SObjectType objectType = objectTypes.get(objectName);
            if (objectType == null) {
                throw new AuraHandledException('Invalid object in Quick Text merge configuration: ' + objectName);
            }
            Schema.DescribeSObjectResult objectInfo = objectType.getDescribe();
            if (!objectInfo.isAccessible() || !objectInfo.isQueryable()) {
                continue;
            }
            Map<String, Schema.SObjectField> objectFields = objectInfo.fields.getMap();
            List<String> fields = new List<String>();
            for (String fieldName : allowed.get(objectName)) {
                Schema.SObjectField field = objectFields.get(fieldName);
                if (field == null || field.getDescribe().getType() != Schema.DisplayType.String) {
                    throw new AuraHandledException(
                        'Invalid or unsupported field in Quick Text merge configuration: ' +
                            objectName +
                            '.' +
                            fieldName
                    );
                }
                if (field.getDescribe().isAccessible()) {
                    fields.add(field.getDescribe().getName());
                }
            }
            if (fields.isEmpty()) {
                continue;
            }
            fields.sort();
            List<SObject> records = Database.queryWithBinds(
                'SELECT ' + String.join(fields, ',') + ' FROM ' + objectInfo.getName() + ' WHERE Id = :recordId',
                new Map<String, Object>{ 'recordId' => context.get(objectName) },
                AccessLevel.USER_MODE
            );
            if (!records.isEmpty()) {
                for (String fieldName : fields) {
                    Object value = records[0].get(fieldName);
                    if (value != null && String.isNotBlank(String.valueOf(value))) {
                        values.put(objectName + '.' + fieldName, value);
                    }
                }
            }
        }
        return values;
    }
}
