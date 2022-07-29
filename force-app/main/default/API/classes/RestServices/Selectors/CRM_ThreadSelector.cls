public with sharing class CRM_ThreadSelector extends CRM_ApiSelector {
    public CRM_ThreadSelector() {
        super(false);
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Thread__c.CRM_isActive__c,
            Thread__c.CRM_Date_Time_Registered__c,
            Thread__c.CRM_Office_Restriction__c,
            Thread__c.Id,
            Thread__c.CRM_HenvendelseId__c,
            Thread__c.Name,
            Thread__c.CRM_Related_Object__c,
            Thread__c.OwnerId,
            Thread__c.CRM_Office_Restriction_Activated_By__c,
            Thread__c.CRM_Office_Restriction_Date__c,
            Thread__c.CRM_Incorrectly_Sent_Activated_By__c,
            Thread__c.CRM_Incorrectly_Sent_Date__c,
            Thread__c.CRM_Incorrectly_Sent__c,
            Thread__c.CRM_Disposal_Datetime__c,
            Thread__c.CRM_Created_By_Ident__c,
            Thread__c.CRM_Closed_Date__c,
            Thread__c.CRM_Type__c,
            Thread__c.CRM_Theme_Group_Code__c,
            Thread__c.CRM_Theme_Code__c,
            Thread__c.CRM_External_ActorId_Formula__c,
            Thread__c.CRM_External_Person_Ident_Formula__c,
            Thread__c.CRM_Original_Person_GT__c,
            Thread__c.CRM_Original_Person_NAV_Unit__c,
            Thread__c.CRM_API_Reference__c,
            Thread__c.STO_Sensitive_Information__c
        };
    }

    public Schema.SObjectType getSObjectType() {
        return Thread__c.sObjectType;
    }

    public Thread__c selectById(Id id) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id =: id').setLimit(1);
        //Adds the Journal entry selector query as a relationship query to the Thread query
        new CRM_JournalEntrySelector().addQueryFactorySubselect(query, 'Journal_Entries__r');
        //Adds the Journal entry selector query as a relationship query to the Thread query
        addMessageSubquery(query);
        return (Thread__c) Database.query(query.toSOQL());
    }

    public Thread__c selectByApiReference(String apiRef) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('CRM_API_Reference__c =: apiRef').setLimit(1);
        //Adds the Journal entry selector query as a relationship query to the Thread query
        new CRM_JournalEntrySelector().addQueryFactorySubselect(query, 'Journal_Entries__r');
        //Adds the Journal entry selector query as a relationship query to the Thread query
        addMessageSubquery(query);
        return (Thread__c) Database.query(query.toSOQL());
    }

    public List<Thread__c> selectByIds(Set<Id> idSet) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id in :idSet');
        return (List<Thread__c>) Database.query(query.toSOQL());
    }

    public List<Thread__c> selectByActorId(Set<String> actorIds) {
        List<String> threadTypes = new List<String>{ 'STO', 'STB', 'CHAT' };
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition(
            '(CRM_Account__r.CRM_Person__r.INT_ActorId__c in :actorIds AND CRM_Type__c in :threadTypes)'
        );
        //Adds the Journal entry selector query as a relationship query to the Thread query
        new CRM_JournalEntrySelector().addQueryFactorySubselect(query, 'Journal_Entries__r');
        //Adds the Journal entry selector query as a relationship query to the Thread query
        addMessageSubquery(query);
        return (List<Thread__c>) Database.query(query.toSOQL());
    }

    /**
     * @description: Adds a filtered subselect for messages related to the thread
     * @author Stian Ruud Schikora | 01-31-2022
     * @param query
     **/
    private void addMessageSubquery(fflib_QueryFactory query) {
        CRM_MessageSelector msgSelector = new CRM_MessageSelector();
        query.subselectQuery('Messages__r')
            .selectFields(msgSelector.getSObjectFieldList())
            .setCondition(msgSelector.getApiConditions())
            .setOrdering('CRM_Sent_Date__c', fflib_QueryFactory.SortOrder.ASCENDING);
    }
}
