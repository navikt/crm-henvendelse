@RestResource(urlmapping='/henvendelse/ny/*')
global without sharing class CRM_HenvendelseNyRestService extends CRM_HenvendelseApiUtils {
    private static final String SAMTALEREFERAT_TYPE = HENVENDELSE_TYPE.SAMTALEREFERAT.name();
    private static final String MELDING_TYPE = HENVENDELSE_TYPE.MELDING.name();
    private static String correlationId;
    private static LoggerUtility logger = new LoggerUtility('Henvendelse API');

    @HttpPost
    global static void createHenvendelse() {
        //Super validation handles setting the response so return if this fails
        if (!validate())
            return;

        correlationId = getXCorrelation();

        RestRequest request = RestContext.request;

        try {
            HENVENDELSE_TYPE henvType = getHenvendelseType(getLastPathParameter());
            String kjedeId = getRequestParam('kjedeId');

            switch on henvType {
                when SAMTALEREFERAT {
                    handleNewConversationNote(request.requestBody.toString(), kjedeId);
                }
                when MELDING {
                    handleNewMessage(request.requestBody.toString(), kjedeId);
                }
                when else {
                    errorResponse(
                        400,
                        'Invalid henvendelse type: ' +
                            henvType +
                            '\n Approved types are: ' +
                            JSON.serializePretty(HENVENDELSE_TYPE.values())
                    );
                }
            }
        } catch (ValidationException valEx) {
            //Validation exception is thrown internally
            errorResponse(400, valEx.getMessage());
        } catch (NotFoundException nfEx) {
            // Exception is thrown internally
            errorResponse(404, nfEx.getMessage());
        } catch (InvalidBodyException bodyEx) {
            // Exception is thrown internally
            errorResponse(400, bodyEx.getMessage());
        } catch (Exception ex) {
            errorResponse(500, 'Unknown error: ' + ex.getMessage());
            logger.error(
                'Unknown error: ' + ex.getMessage() + '\n' + ex.getStackTraceString(),
                null,
                CRM_ApplicationDomain.Domain.NKS,
                correlationId
            );
        } finally {
            logger.publish();
        }
    }

    private static void handleNewConversationNote(String req, String kjedeId) {
        //Throws various exceptions if validation fails and handled at top level
        Conversation_Note__c newNote = validateNewConversationNote(req, kjedeId);

        try {
            insert newNote;
            List<Conversation_Note__c> notesFromDatabase = new List<Conversation_Note__c>();
            if (String.isNotBlank(kjedeId))
                notesFromDatabase = new CRM_ConversationNoteSelector().selectByBehandlingskjedeId(kjedeId);
            else
                notesFromDatabase.add(new CRM_ConversationNoteSelector().selectById(newNote.Id));
            setResponse(200, JSON.serializePretty(new CRM_Henvendelse(notesFromDatabase)));
        } catch (DmlException dmlEx) {
            errorResponse(500, 'Insertion failed: ' + dmlEx.getMessage());
            logger.error(
                'Insertion failed: ' + dmlEx.getMessage(),
                null,
                CRM_ApplicationDomain.Domain.NKS,
                correlationId
            );
        }
    }

    /**
     * @description: JSON deserializationof incoming message request, returns null if the body is invalid
     * @author Stian Ruud Schikora | 01-17-2022
     * @param jsonReq
     * @return NewMessageRequest
     **/
    private static NewMessageRequest deserializeMessageRequest(String jsonReq) {
        try {
            return (NewMessageRequest) JSON.deserializeStrict(jsonReq, NewMessageRequest.class);
        } catch (JSONException jsonEx) {
            throw new InvalidBodyException('Invalid request body: ' + jsonEx.getMessage());
        }
    }

    private static void handleNewMessage(String req, String threadId) {
        NewMessageRequest messageReq = deserializeMessageRequest(req);
        Message__c newMessage = validateNewMessage(messageReq, threadId);
        if (newMessage == null)
            return; //Failed validation

        try {
            //If tildelMeg is set to true the Assignee of the thread is set to the ident sending the message, else only the NAV unit is assigned
            String threadAssignee = messageReq.tildelMeg == true ? newMessage.CRM_From_Ident__c : null;
            if (String.isBlank(newMessage.CRM_Thread__c)) {
                //New thread is returned in the CRM_Thread__r relation and needs to be inserted
                Thread__c newThread = newMessage.CRM_Thread__r;
                newThread.CRM_Assignee__c = threadAssignee;
                newThread.CRM_Assignee_NAV_Unit__c = newMessage.CRM_From_NAV_Unit__c;
                newThread.recordTypeId = getNKSThreadRecordtype();
                insert newThread;
                newMessage.CRM_Thread__c = newThread.Id;
            } else {
                //Updates the thread assignee
                updateThreadAssignee(threadAssignee, newMessage.CRM_From_NAV_Unit__c, newMessage.CRM_Thread__c);
            }
            insert newMessage;
            Thread__c updatedThread = new CRM_ThreadSelector().selectById(newMessage.CRM_Thread__c);
            setResponse(
                200,
                JSON.serializePretty(
                    new CRM_Henvendelse(updatedThread, updatedThread.Messages__r, updatedThread.Journal_Entries__r)
                )
            );
        } catch (DmlException dmlEx) {
            errorResponse(500, 'Insertion failed: ' + dmlEx.getMessage());
            logger.error(
                'Insertion failed: ' + dmlEx.getMessage(),
                null,
                CRM_ApplicationDomain.Domain.NKS,
                correlationId
            );
        }
    }

    //###########################################################//
    //###############     HELPER METHODS       ##################//
    //###########################################################//

    /**
     * @description: Gets the CRM_Account__c from the Person record with the matching actorId, null if not found
     * @author Stian Ruud Schikora | 07-08-2021
     * @param actorId
     * @return String
     **/
    private static String getAccountId(String actorId) {
        return [SELECT CRM_Account__c FROM Person__c WHERE INT_ActorId__c = :actorId]?.CRM_Account__c;
    }

    private static String getNKSThreadRecordtype() {
        List<RecordType> recordType = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Thread__c' AND Name = 'NKS Thread'
            LIMIT 1
        ];
        return recordType.isEmpty() ? null : recordType[0].Id;
    }

    /**
     * @description: Validates an incoming request for insertion of a new conversation note. If the request validates
     * a valid Conversation_Note__c record is returned, else null
     * @author Stian Ruud Schikora | 07-08-2021
     * @param req
     * @return Conversation_Note__c
     **/
    private static Conversation_Note__c validateNewConversationNote(String req, String kjedeId) {
        NewConversationNoteRequest convRequest;
        Conversation_Note__c newNote = new Conversation_Note__c();
        String themeGroupId, themeId;

        try {
            convRequest = (NewConversationNoteRequest) JSON.deserializeStrict(req, NewConversationNoteRequest.class);
        } catch (JSONException jsonEx) {
            throw new InvalidBodyException('Invalid request body: ' + jsonEx.getMessage());
        }

        themeGroupId = validateThemeGroup(convRequest.temagruppe);
        themeId = validateTheme(convRequest.tema);

        if (String.isNotBlank(kjedeId)) {
            //Validate if the conversation note chain exists
            List<Conversation_Note__c> convNoteChain = new CRM_ConversationNoteSelector()
                .selectByBehandlingskjedeId(kjedeId);
            if (convNoteChain.size() == 0) {
                throw new NotFoundException('Conversation note chain does not exists: ' + kjedeId);
            } else {
                newNote.CRM_Henvendelse_BehandlingskjedeId__c = kjedeId;
            }
        }

        String accountId = getAccountId(convRequest.aktorId);
        if (String.isBlank(accountId)) {
            throw new NotFoundException('No person with actor ID: ' + convRequest.aktorId);
        }

        //Method from CRM_HenvendelseApiUtils
        String actingNavIdent = getActingNavIdent();
        newNote.CRM_Account__c = accountId;
        newNote.CRM_Conversation_Note__c = convRequest.fritekst;
        newNote.CRM_Created_By_Ident__c = actingNavIdent;
        newNote.CRM_Created_By_NAV_Unit__c = convRequest.enhet;
        newNote.CRM_Theme_Group__c = themeGroupId;
        newNote.CRM_Theme__c = themeId;
        newNote.CRM_Communication_Channel__c = convRequest.kanal == CRM_Melding.Communication_Channel.OPPMOTE.name()
            ? 'Meeting'
            : 'Phone';
        return newNote;
    }

    /**
     * @description: Validates an incoming request for insertion of a new message. If the request validates
     * a valid Message__c record is returned, else null. If the message request creates a new thread, the new record is returned in the Message__c.CRM_Thread__r relation
     * @author Stian Ruud Schikora | 07-08-2021
     * @param req
     * @param apiRef [Unique reference defined in CRM_API_Reference__c]
     * @return Message__c
     **/
    private static Message__c validateNewMessage(NewMessageRequest messageRequest, String apiRef) {
        Message__c newMessage = new Message__c();
        String actingNavIdent = getActingNavIdent();

        String accountId = getAccountId(messageRequest.aktorId);
        if (String.isBlank(accountId)) {
            throw new NotFoundException('No person with actor ID: ' + messageRequest.aktorId);
        }

        if (String.isNotBlank(apiRef)) {
            //Validate if the thread is open and existing
            try {
                Thread__c thread = new CRM_ThreadSelector().selectByApiReference(apiRef);
                if (thread.CRM_isActive__c == false) {
                    throw new ValidationException('Cannot insert new message on closed thread');
                } else {
                    newMessage.CRM_Thread__c = thread.Id;
                }
            } catch (QueryException queryEx) {
                //The thread does not exist
                throw new NotFoundException('Message thread does not exist: ' + queryEx.getMessage());
            }
        } else {
            try {
                String themeGroupId, themeId;
                themeGroupId = validateThemeGroup(messageRequest.temagruppe);
                themeId = validateTheme(messageRequest.tema);

                newMessage.CRM_Thread__r = new Thread__c(
                    Name = 'Skriv til bruker',
                    CRM_Account__c = accountId,
                    CRM_Created_By_Ident__c = actingNavIdent,
                    CRM_Created_By_NAV_Unit__c = messageRequest.enhet,
                    CRM_Theme_Group__c = themeGroupId,
                    CRM_Theme__c = themeId,
                    CRM_Thread_Type__c = 'STB'
                );
            } catch (DmlException dmlEx) {
                errorResponse(500, 'Unexpected error: ' + dmlEx.getMessage());
                logger.error(
                    'Unexpected error: ' + dmlEx.getMessage(),
                    null,
                    CRM_ApplicationDomain.Domain.NKS,
                    correlationId
                );
                return null;
            }
        }

        newMessage.CRM_Message_Text__c = messageRequest.fritekst;
        newMessage.CRM_From_NAV_Unit__c = messageRequest.enhet;
        newMessage.CRM_From_Ident__c = actingNavIdent;

        return newMessage;
    }

    @future
    private static void updateThreadAssignee(String assignee, String assigneeUnit, String threadId) {
        update new Thread__c(Id = threadId, CRM_Assignee__c = assignee, CRM_Assignee_NAV_Unit__c = assigneeUnit);
    }

    /**
     * @description: Validate an input theme group code. This is required and must validate in common code
     * @author Stian Ruud Schikora | 11-23-2021
     * @param themeGroupCode
     * @return String
     **/
    private static String validateThemeGroup(String themeGroupCode) {
        String themeGroupId;
        if (String.isBlank(themeGroupCode)) {
            throw new ValidationException('Missing required parameter: temagruppe');
        } else {
            themeGroupId = getThemeGroup(themeGroupCode);
            if (String.isBlank(themeGroupId)) {
                throw new ValidationException('Invalid code for theme group: ' + themeGroupCode);
            }
        }
        return themeGroupId;
    }

    /**
     * @description: Validates an input theme code. Theme is not required in request, so if blank it is valid, else it must validate in common code
     * @author Stian Ruud Schikora | 11-23-2021
     * @param themeCode
     * @return String
     **/
    private static String validateTheme(String themeCode) {
        String themeId;
        if (String.isNotBlank(themeCode)) {
            themeId = getTheme(themeCode);
            if (String.isBlank(themeId)) {
                throw new ValidationException('Invalid code for theme: ' + themeCode);
            }
        }
        return themeId;
    }

    private class ValidationException extends Exception {
    }
    private class NotFoundException extends Exception {
    }
    private class InvalidBodyException extends Exception {
    }

    global class NewMessageRequest {
        global String aktorId;
        global String temagruppe;
        global String tema;
        global String enhet;
        global String fritekst;
        global Boolean tildelMeg; //Setting this to true updates the assignee on the thread.
    }

    global class NewConversationNoteRequest {
        global String aktorId;
        global String temagruppe;
        global String tema;
        global String enhet;
        global String fritekst;
        global String kanal; //Separate between phone and physical meet
    }
}
