public without sharing class CRM_ConvNoteJournalRetryBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
    private LoggerUtility logger = new LoggerUtility('Conversation Note Journal Retry');
    private Boolean error = false;

    @InvocableMethod(
        label='Initiate Conversation Note Journal Retry Batch'
        description='Starts a process for posting journal entries to JOARK'
        category='Journal'
    )
    public static void initJournalBatcher() {
        Database.executeBatch(new CRM_ConvNoteJournalRetryBatch(), 40);
    }

    //################################################//
    //############ SELECTOR CLASS ####################//
    //################################################//

    private class JournalEntrySelector extends CRM_ApiSelector {
        public JournalEntrySelector() {
            super(false, false, false);
        }

        public List<Schema.SObjectField> getSObjectFieldList() {
            return new List<Schema.SObjectField>{
                Journal_Entry__c.Id,
                Journal_Entry__c.CRM_Conversation_Note__c,
                Journal_Entry__c.CRM_Created_By_Ident__c,
                Journal_Entry__c.CRM_Created_By_NAV_Unit__c,
                Journal_Entry__c.NAV_Case_Reference__c,
                Journal_Entry__c.CRM_Theme_Code__c,
                Journal_Entry__c.CRM_Subtheme_Code__c,
                Journal_Entry__c.Subtheme__c,
                Journal_Entry__c.Theme__c,
                Journal_Entry__c.CRM_NAV_Case_Legacy_System__c,
                Journal_Entry__c.CRM_Journal_Post_Type__c,
                Journal_Entry__c.Journal_Entry_Status__c,
                Journal_Entry__c.Journal_Entry_ID__c
            };
        }

        public Schema.SObjectType getSObjectType() {
            return Journal_Entry__c.sObjectType;
        }

        private String getJournalConditions() {
            return 'CRM_Conversation_Note__c != null AND Journal_Entry_Status__c = \'Failed\'';
        }

        public String getJournalEntriesToJournal() {
            fflib_QueryFactory query = newQueryFactory();
            query.setCondition(getJournalConditions());

            return query.toSOQL();
        }
    }

    //################################################//
    //###### BATCH IMPLEMENTATION CLASS ##############//
    //################################################//

    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(new JournalEntrySelector().getJournalEntriesToJournal());
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Conversation_Note__c> convNotesToUpdate = new List<Conversation_Note__c>();
        List<Journal_Entry__c> jEntriesToUpdate = new List<Journal_Entry__c>();
        Set<Id> processedConvNoteIds = new Set<Id>();

        for (Journal_Entry__c jEntry : (List<Journal_Entry__c>) scope) {
            jEntry.NAV_Case_Reference__c = jEntry.NAV_Case_Reference__c; //Self initialization for flow null handling
            jEntry.CRM_NAV_Case_Legacy_System__c = jEntry.CRM_NAV_Case_Legacy_System__c; //Self initialization for flow null handling
            Map<String, Object> flowInputs = new Map<String, Object>{
                'Journal_Entry_SF' => jEntry,
                'PERFORM_DML' => false
            };

            Flow.Interview journalFlow = Flow.Interview.createInterview('Journal_Conversation_Note_Retry', flowInputs);
            journalFlow.start();
            jEntriesToUpdate.add((Journal_Entry__c) journalFlow.getVariableValue('Journal_Entry_SF'));
            if (processedConvNoteIds.contains(jEntry.CRM_Conversation_Note__c))
                continue; //Already added to list for update
            convNotesToUpdate.add((Conversation_Note__c) journalFlow.getVariableValue('Conversation_Note_Record'));
            processedConvNoteIds.add(jEntry.CRM_Conversation_Note__c);
        }

        List<Database.SaveResult> jEntryUpdRes = Database.update(jEntriesToUpdate, false);
        List<Database.SaveResult> convNoteUpdRes = Database.update(convNotesToUpdate, false);

        verifyUpdateResults(jEntryUpdRes);
        verifyUpdateResults(convNoteUpdRes);
        logger.publish();
    }

    private void verifyUpdateResults(List<Database.SaveResult> updResults) {
        for (Database.SaveResult updRes : updResults) {
            if (updRes.isSuccess()) {
                //Successfull update
            } else {
                String errorMsg = 'Failed to update record with id: ' + updRes.getId() + '\n';
                for (Database.Error err : updRes.getErrors()) {
                    errorMsg += err.getMessage() + '\n';
                }
                this.error = true;
                logger.error(errorMsg, null, CRM_ApplicationDomain.Domain.NKS);
            }
        }
    }

    //If error occurred a critical log entry is logged that will publish automatically to slack
    public void finish(Database.BatchableContext BC) {
        if (this.error) {
            logger.critical('One of more records failed to update', null, CRM_ApplicationDomain.Domain.NKS); //Log a critical entry that should be published to slack for follow up;
            logger.publish();
        }
    }
}
