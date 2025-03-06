@RestResource(urlmapping='/henvendelse/journal/*')
global without sharing class CRM_HenvendelseJournalRestService extends CRM_HenvendelseApiUtils {
    private static LoggerUtility logger = new LoggerUtility('Henvendelse API');
    @HttpPost
    global static void createJournalPost() {
        HenvendelseJournalRequest request = (HenvendelseJournalRequest) JSON.deserialize(
            RestContext.request.requestBody.toString(),
            HenvendelseJournalRequest.class
        ); //Explicit deseriialization
        //Super validation handles setting the response so return if this fails
        if (!validate())
            return;

        String correlationId = getXCorrelation();

        //Perform validation of the request
        if (!validateRequest(request)) {
            return;
        }

        try {
            String apiReference = request.kjedeId;
            Id objectId = getObjectId(apiReference);
            String objectName = objectId != null ? objectId.getSobjectType().getDescribe().getName() : null;

            switch on objectName {
                when 'Conversation_Note__c' {
                    doConversationNoteJournal(apiReference, request);
                    List<Conversation_Note__c> notesFromDatabase = new CRM_ConversationNoteSelector()
                        .selectByBehandlingskjedeId(apiReference);
                    setResponse(200, JSON.serializePretty(new CRM_Henvendelse(notesFromDatabase)));
                }
                when 'Thread__c' {
                    doThreadJournal(objectId, request);
                    Thread__c updatedThread = new CRM_ThreadSelector().selectByApiReference(apiReference);
                    setResponse(
                        200,
                        JSON.serializePretty(
                            new CRM_Henvendelse(
                                updatedThread,
                                updatedThread.Messages__r,
                                updatedThread.Journal_Entries__r
                            )
                        )
                    );
                }
                when else {
                    errorResponse(400, 'No journal flow defined for ID: ' + apiReference);
                    logger.error(
                        'No journal flow defined for ID: ' + apiReference,
                        null,
                        CRM_ApplicationDomain.Domain.NKS,
                        correlationId
                    );
                    logger.publish();
                }
            }
            return;
        } catch (Exception ex) {
            errorResponse(500, ex.getMessage());
            logger.error(
                ex.getMessage() + '\n' + ex.getStackTraceString(),
                null,
                CRM_ApplicationDomain.Domain.NKS,
                correlationId
            );
        } finally {
            logger.publish();
        }
    }

    /**
     * Performs validation on the henvendelse journal request
     * @author Stian Ruud Schikora | 04-06-2022
     * @param request
     * @return Boolean
     **/
    private static Boolean validateRequest(HenvendelseJournalRequest request) {
        Boolean valid = true;

        if (
            String.isNotBlank(request.fagsakId) && String.isBlank(request.fagsaksystem) ||
            String.isNotBlank(request.fagsaksystem) && String.isBlank(request.fagsakId)
        ) {
            valid = false;
            errorResponse(400, 'Ved journalføring av fagsak må både fagsakId og fagsaksystem være definert');
        }

        return valid;
    }

    /**
     * @description: gets all the conversation note on the same behandlingskjedeId and calls journal flow for each record
     * Flow handles if some entries already have been journaled.
     * @author Stian Ruud Schikora | 10-21-2021
     * @param apiReference
     * @param request
     **/
    private static void doConversationNoteJournal(String apiReference, HenvendelseJournalRequest request) {
        List<Conversation_Note__c> notesToUpdate = new List<Conversation_Note__c>();
        List<Journal_Entry__c> jEntriesToCreate = new List<Journal_Entry__c>();
        List<Conversation_Note__c> noteList = new CRM_ConversationNoteSelector()
            .selectByBehandlingskjedeId(apiReference);

        for (Conversation_Note__c convNote : noteList) {
            Map<String, Object> flowInputs = new Map<String, Object>{
                'recordId' => convNote.Id,
                'Journal_Case_ID' => request.fagsakId,
                'Journal_Case_Legacy_System' => request.fagsaksystem,
                'Journal_Theme_Code' => request.temakode,
                'Journal_Entry_Unit' => request.journalforendeEnhet,
                'Journal_Entry_NAV_Ident' => getActingNavIdent(),
                'PERFORM_DML' => false
            };
            Flow.Interview convNoteJournalFlow = initiateJournalFlow(
                'CRM_Journal_Conversation_Note',
                JSON.serialize(flowInputs)
            );

            Conversation_Note__c journaledNote = (Conversation_Note__c) convNoteJournalFlow.getVariableValue(
                'JOURNALED_CONV_NOTE'
            );
            Journal_Entry__c newEntry = (Journal_Entry__c) convNoteJournalFlow.getVariableValue('Journal_Entry_SF');
            if (journaledNote != null)
                notesToUpdate.add(journaledNote);
            if (newEntry != null)
                jEntriesToCreate.add(newEntry);
        }

        update notesToUpdate;
        insert jEntriesToCreate;
    }

    /**
     * @description: Calls the thread journal flow for a specified thread ID
     * @author Stian Ruud Schikora | 10-21-2021
     * @param threadId
     * @param request
     **/
    private static void doThreadJournal(String threadId, HenvendelseJournalRequest request) {
        Map<String, Object> flowInputs = new Map<String, Object>{
            'recordId' => threadId,
            'Journal_Case_ID' => request.fagsakId,
            'Journal_Case_Legacy_System' => request.fagsaksystem,
            'Journal_Theme_Code' => request.temakode,
            'Journal_Entry_Unit' => request.journalforendeEnhet,
            'Journal_Entry_NAV_Ident' => getActingNavIdent()
        };

        initiateJournalFlow('CRM_Thread_Create_Journal_Entry', JSON.serialize(flowInputs));
    }

    private static Flow.Interview initiateJournalFlow(String flowName, String inputParams) {
        Map<String, Object> flowInputs = (Map<String, Object>) JSON.deserializeUntyped(inputParams);

        Flow.Interview journalFlow = Flow.Interview.createInterview(flowName, flowInputs);
        journalFlow.start();
        return journalFlow;
    }

    global class HenvendelseJournalRequest {
        global String journalforendeEnhet;
        global String fagsakId;
        global String kjedeId;
        global String temakode;
        global String fagsaksystem;
    }
}
