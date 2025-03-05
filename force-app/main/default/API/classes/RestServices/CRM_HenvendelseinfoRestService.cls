/**
 * @description       :
 * @author            : mamikals
 * @group             :
 * @last modified on  : 21-03-2023
 * @last modified by  : mamikals
 **/
@RestResource(urlmapping='/henvendelseinfo/henvendelse/*')
global without sharing class CRM_HenvendelseinfoRestService extends CRM_HenvendelseApiUtils {
    private static LoggerUtility logger = new LoggerUtility('Henvendelse API');
    @HttpGet
    global static void getHenvendelse() {
        if (!validate()) {
            return;
        }

        String correlationId = getXCorrelation();
 
        try {
            String apiReference = getLastPathParameter();
            Id objectId = getObjectId(apiReference);
            String objectName = objectId != null ? objectId.getSobjectType().getDescribe().getName() : null;

            switch on objectName {
                when 'Thread__c' {
                    Thread__c thread = new CRM_ThreadSelector().selectByApiReference(apiReference);
                    setResponse(
                        200,
                        JSON.serializePretty(new CRM_Henvendelse(thread, thread.Messages__r, thread.Journal_Entries__r))
                    );
                }
                when 'Conversation_Note__c' {
                    List<Conversation_Note__c> noteList = new CRM_ConversationNoteSelector()
                        .selectByBehandlingskjedeId(apiReference);
                    setResponse(200, JSON.serializePretty(new CRM_Henvendelse(noteList)));
                }
                when else {
                    errorResponse(400, 'Invalid reference value for henv/thread ID: ' + apiReference);
                }
            }
        } catch (Exception ex) {
            errorResponse(500, 'Exception: ' + ex.getMessage());
            logger.error(
                'Exception: ' +
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
}
