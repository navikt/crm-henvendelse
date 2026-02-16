public inherited sharing class CRM_ConversationNoteSelector extends CRM_ApiSelector {
    private final List<String> QUERY_FIELDS = new List<String>{
        'Id',
        'Name',
        'CRM_HenvendelseId__c',
        'CRM_Henvendelse_BehandlingskjedeId__c',
        'CRM_Account__r.CRM_Person__r.INT_ActorId__c',
        'CRM_Account__r.CRM_Person__r.Name',
        'CRM_Theme_Group_Code__c',
        'CRM_Theme_Code__c',
        'CRM_Read_Date__c',
        'CRM_Date_Time_Registered__c',
        'CRM_Conversation_Note__c',
        'CRM_Created_By_Ident__c',
        'CRM_Incorrectly_Sent_Activated_By__c',
        'CRM_Incorrectly_Sent_Date__c',
        'CRM_Incorrectly_Sent__c',
        'CRM_Disposal_Datetime__c',
        'CRM_Communication_Channel__c',
        'CRM_Created_By_NAV_Unit__c',
        'STO_Sensitive_Information__c',
        'CRM_API_Reference__c'
    };

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{ Conversation_Note__c.Id };
    }

    public Schema.SObjectType getSObjectType() {
        return Conversation_Note__c.sObjectType;
    }

    public Conversation_Note__c selectById(Id convId) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectFields(QUERY_FIELDS).setCondition('Id=: convId');
        return (Conversation_Note__c) Database.query(query.toSOQL());
    }

    public Conversation_Note__c selectByApiReference(String apiReference) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectFields(QUERY_FIELDS).setCondition('CRM_API_Reference__c=: apiReference');
        return (Conversation_Note__c) Database.query(query.toSOQL());
    }

    public List<Conversation_Note__c> selectByApiReferences(List<String> apiReferences) {
        fflib_QueryFactory query = newQueryFactory();
        query.selectFields(QUERY_FIELDS).setCondition('CRM_API_Reference__c IN: apiReferences');
        return (List<Conversation_Note__c>) Database.query(query.toSOQL());
    }

    public List<Conversation_Note__c> selectByActorId(Set<String> actorIds, Integer queryLimit) {
        fflib_QueryFactory query = newQueryFactory();
        query
            .selectFields(QUERY_FIELDS)
            .setCondition(
                'CRM_Account__r.CRM_Person__r.INT_ActorId__c in :actorIds AND CRM_Henvendelse_BehandlingskjedeId__c != null AND CRM_Created_By_Ident__c != null'
            )
            .setOrdering('CRM_Date_Time_Registered__c', fflib_QueryFactory.SortOrder.DESCENDING);
        if (queryLimit != null && queryLimit > 0) {
            query.setLimit(queryLimit);
        }
        //Adds the Journal entry selector query as a relationship query to the Conversation Note query
        new CRM_JournalEntrySelector().addQueryFactorySubselect(query, 'Journal_Entries__r');
        return (List<Conversation_Note__c>) Database.query(query.toSOQL());
    }

    public Integer countDistinctByActorId(Set<String> actorIds) {
        return [
            SELECT COUNT_DISTINCT(CRM_Henvendelse_BehandlingskjedeId__c)
            FROM Conversation_Note__c
            WHERE
                CRM_Account__r.CRM_Person__r.INT_ActorId__c IN :actorIds
                AND CRM_Henvendelse_BehandlingskjedeId__c != NULL
                AND CRM_Created_By_Ident__c != NULL
        ];
    }

    public List<Conversation_Note__c> selectByBehandlingskjedeId(String behandlingskjedeId) {
        fflib_QueryFactory query = newQueryFactory();
        query
            .selectFields(QUERY_FIELDS)
            .setCondition('CRM_Henvendelse_BehandlingskjedeId__c =: behandlingskjedeId')
            .setOrdering('CRM_Date_Time_Registered__c', fflib_QueryFactory.SortOrder.DESCENDING);
        //Adds the Journal entry selector query as a relationship query to the Conversation Note query
        new CRM_JournalEntrySelector().addQueryFactorySubselect(query, 'Journal_Entries__r');
        return (List<Conversation_Note__c>) Database.query(query.toSOQL());
    }
}
