public with sharing class CRM_ConvNoteJournalHelper {
    private static LoggerUtility logger = new LoggerUtility('Journal');

    @InvocableMethod(
        label='Conversation Note Async Journal'
        description='Calls conversation note journal flow in a asynchronous context'
        category='Journal'
    )
    public static void handleRequest(List<JournalRequest> requests) {
        for (JournalRequest jRequest : requests) {
            doJournal(JSON.serialize(jRequest));
        }
    }

    @future(callout=true)
    private static void doJournal(String journalRequest) {
        Map<String, Object> flowInputs = (Map<String, Object>) JSON.deserializeUntyped(journalRequest);

        Flow.Interview journalFlow = Flow.Interview.createInterview('CRM_Journal_Conversation_Note', flowInputs);
        try {
            journalFlow.start();
        } catch (Exception ex) {
            logger.error(
                'Journal flow failed for conversation note with ID: ' +
                    flowInputs.get('recordId') +
                    '\n' +
                    ex.getMessage(),
                null,
                CRM_ApplicationDomain.Domain.NKS
            );
        } finally {
            logger.publish();
        }
    }

    public class JournalRequest {
        @invocableVariable
        public String recordId;
        @invocableVariable
        public String Journal_Case_ID;
        @invocableVariable
        public String Journal_Case_Legacy_System;
        @invocableVariable
        public String Journal_Theme_Code;
        @invocableVariable
        public String Journal_Subtheme_Code;
        @invocableVariable
        public String Journal_Entry_Unit;
        @invocableVariable
        public String Journal_Entry_NAV_Ident;
        private Boolean PERFORM_DML = true; //Always allowing flow to handle the DML
    }
}
