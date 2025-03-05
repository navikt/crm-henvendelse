@RestResource(urlmapping='/henvendelse/sladding/*')
global without sharing class CRM_HenvRedactionRestService extends CRM_HenvendelseApiUtils {
    private static String correlationId;
    private static LoggerUtility logger = new LoggerUtility('Henvendelse API');

    /**
     * V1: Marks a thread or conversation note for redaction based on kjedeId and redaction cause as input
     * V2: Marks one or more messages or conversation notes for redaction.
     * @author Stian Ruud Schikora | 10-04-2022
     **/
    @HttpPost
    global static void markForRedaction() {
        String navIdent = getActingNavIdent();
        correlationId = getXCorrelation();

        try {
            RestRequest request = RestContext.request;
            SladdingRequest slRequest = (SladdingRequest) JSON.deserialize(
                request.requestBody.toString(),
                SladdingRequest.class
            );

            Id kjedeObjectId = getObjectId(slRequest.kjedeId);
            String kjedeObjectName = kjedeObjectId != null
                ? kjedeObjectId.getSobjectType().getDescribe().getName()
                : null;

            if (slRequest.meldingsIder != null && slRequest.meldingsIder.size() > 0) {
                //V2
                if (kjedeObjectName == 'Thread__c') {
                    List<Message__c> msgsToRedact = new CRM_MessageSelector()
                        .selectByApiReference(slRequest.meldingsIder);
                    //Validate that all messages are on same thread
                    if (!validateMessages(msgsToRedact)) {
                        errorResponse(400, 'All messages must have the same kjedeId');
                        return;
                    }
                    for (Message__c msg : msgsToRedact) {
                        msg.CRM_Sensitive_Information__c = true;
                    }
                    Thread__c threadToUpdate = new Thread__c(Id = msgsToRedact[0].CRM_Thread__c);
                    threadToUpdate.Cause__c = slRequest.aarsak;
                    threadToUpdate.STO_Sensitive_Information__c = true;
                    threadToUpdate.CRM_Last_Edited_By__c = navIdent;
                    update msgsToRedact;
                    update threadToUpdate;
                    setResponse(204);
                } else if (kjedeObjectName == 'Conversation_Note__c') {
                    List<Conversation_Note__c> convsToRedact = new CRM_ConversationNoteSelector()
                        .selectByApiReferences(slRequest.meldingsIder);

                    for (Conversation_Note__c convNote : convsToRedact) {
                        convNote.STO_Sensitive_Information__c = true;
                        convNote.Cause__c = slRequest.aarsak;
                        convNote.CRM_Last_Edited_By__c = navIdent;
                    }

                    update convsToRedact;
                    setResponse(204);
                }
            } else {
                //V1
                if (kjedeObjectName == 'Thread__c' || kjedeObjectName == 'Conversation_Note__c') {
                    SObject objToUpdate = kjedeObjectId.getSobjectType().newSObject(kjedeObjectId);
                    objToUpdate.put('STO_Sensitive_Information__c', true);
                    objToUpdate.put('Cause__c', slRequest.aarsak);
                    objToUpdate.put('CRM_Last_Edited_By__c', navIdent);

                    update objToUpdate;
                    setResponse(204);
                } else {
                    errorResponse(400, 'Invalid reference value for kjedeId: ' + slRequest.kjedeId);
                    return;
                }
            }
        } catch (DmlException dmlEx) {
            errorResponse(500, dmlEx.getMessage());
            logger.error('DML EXCEPTION: ' + dmlEx.getMessage(), null, CRM_ApplicationDomain.Domain.NKS, correlationId);
        } catch (Exception ex) {
            errorResponse(500, 'Failed to update: ' + ex.getMessage());
            logger.error(
                'Failed to update: ' +
                ex.getMessage() +
                '\n' +
                ex.getStackTraceString(),
                null,
                CRM_ApplicationDomain.Domain.NKS,
                correlationId
            );
        } finally {
            logger.publish();
        }
    }

    /**
     * Validates that all messages in list belongs to the same thread
     * @author Stian Ruud Schikora | 10-11-2022
     * @param msgList
     * @return boolean
     **/
    private static boolean validateMessages(List<Message__c> msgList) {
        Boolean valid = false;
        String threadId = msgList.size() > 0 ? msgList[0].CRM_Thread__c : null;
        if (threadId == null)
            return false;

        for (Message__c msg : msgList) {
            valid = msg.CRM_Thread__c == threadId;
        }

        return valid;
    }

    /**
     * Returns the available redaction causes for the given kjedeId
     * @author Stian Ruud Schikora | 10-04-2022
     **/
    @HttpGet
    global static void getRedactionCauses() {
        correlationId = getXCorrelation();
        String kjedeId = getLastPathParameter();

        Id objectId = getObjectId(kjedeId);
        String objectName = objectId != null ? objectId.getSobjectType().getDescribe().getName() : null;

        switch on objectName {
            when 'Thread__c' {
                List<Schema.PicklistEntry> causes = Thread__c.Cause__c.getDescribe().getPicklistValues();
                setResponse(200, JSON.serializePretty(simplifyCauses(causes)));
            }
            when 'Conversation_Note__c' {
                List<Schema.PicklistEntry> causes = Conversation_Note__c.Cause__c.getDescribe().getPicklistValues();
                setResponse(200, JSON.serializePretty(simplifyCauses(causes)));
            }
            when else {
                errorResponse(400, 'Invalid reference value for kjedeId: ' + kjedeId);
                return;
            }
        }
    }

    private static List<String> simplifyCauses(List<Schema.PickListEntry> causes) {
        List<String> causeList = new List<String>();
        for (Schema.PickListEntry cause : causes) {
            causeList.add(cause.getLabel());
        }

        return causeList;
    }

    public class SladdingRequest {
        public String aarsak;
        public String kjedeId;
        public List<String> meldingsIder;
    }
}
