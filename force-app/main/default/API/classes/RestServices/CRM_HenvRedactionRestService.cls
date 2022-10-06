@RestResource(urlmapping='/henvendelse/sladding/*')
global without sharing class CRM_HenvRedactionRestService extends CRM_HenvendelseApiUtils {
    private static String correlationId;
    private static LoggerUtility logger = new LoggerUtility('Henvendelse API');

    /**
     * Marks a thread or conversation note for redaction based on kjedeId and redaction cause as input
     * @author Stian Ruud Schikora | 10-04-2022
     **/
    @HttpPost
    global static void markForRedaction() {
        String navIdent = getActingNavIdent();
        correlationId = getXCorrelation();
        logger.apiTransaction(correlationId, RestContext.request, CRM_ApplicationDomain.Domain.NKS);
        try {
            RestRequest request = RestContext.request;
            SladdingRequest slRequest = (SladdingRequest) JSON.deserialize(
                request.requestBody.toString(),
                SladdingRequest.class
            );

            Id objectId = getObjectId(slRequest.kjedeId);
            String objectName = objectId != null ? objectId.getSobjectType().getDescribe().getName() : null;

            if (objectName == 'Thread__c' || objectName == 'Conversation_Note__c') {
                SObject objToUpdate = objectId.getSobjectType().newSObject(objectId);
                objToUpdate.put('STO_Sensitive_Information__c', true);
                objToUpdate.put('Cause__c', slRequest.aarsak);
                objToUpdate.put('CRM_Last_Edited_By__c', navIdent);

                update objToUpdate;
                setResponse(200);
            } else {
                errorResponse(400, 'Invalid reference value for kjedeId: ' + slRequest.kjedeId);
                logger.publish();
                return;
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
        }
    }

    /**
     * Returns the available redaction causes for the given kjedeId
     * @author Stian Ruud Schikora | 10-04-2022
     **/
    @HttpGet
    global static void getRedactionCauses() {
        correlationId = getXCorrelation();
        logger.apiTransaction(correlationId, RestContext.request, CRM_ApplicationDomain.Domain.NKS);
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
                logger.publish();
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
    }
}