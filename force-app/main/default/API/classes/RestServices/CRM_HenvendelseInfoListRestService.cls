/**
 * @description       :
 * @author            : mamikals
 * @group             :
 * @last modified on  : 27-03-2023
 * @last modified by  : mamikals
 **/
@RestResource(urlmapping='/henvendelseinfo/henvendelseliste/*')
global without sharing class CRM_HenvendelseInfoListRestService extends ApexRestService {
    private static LoggerUtility logger = new LoggerUtility('Henvendelse API');
    @HttpGet
    global static void getHenvendelseList() {
        Datetime startTime = system.now();
        String actorId = getRequestParam('aktorid');

        if (!validate()) {
            return;
        }

        String correlationId = getXCorrelation();
        logger.apiTransaction(correlationId, RestContext.request, CRM_ApplicationDomain.Domain.NKS);

        if (String.isBlank(actorId)) {
            errorResponse(400, 'Missing required query input: aktorid');
            logger.publish();
            return;
        }

        try {
            List<CRM_Henvendelse> returnList = new List<CRM_Henvendelse>();
            List<Conversation_Note__c> convList = new CRM_ConversationNoteSelector()
                .selectByActorId(new Set<String>{ actorId });
            returnList.addAll(convertToHenvendelseList(convList));

            List<Thread__c> threadList = new CRM_ThreadSelector().selectByActorId(new Set<String>{ actorId });
            returnList.addAll(convertToHenvendelseList(threadList));
            returnList.sort();
            Long timeTaken = System.now().getTime() - startTime.getTime();
            setResponse(200, JSON.serializePretty(returnList));
            logger.peek().Log_Messages__c = 'Get henvendelselist used ' + timeTaken + 'ms';
        } catch (QueryException queryEx) {
            errorResponse(500, 'Query exception: ' + queryEx.getMessage());
            logger.error(
                'Query exception: ' + queryEx.getMessage(),
                null,
                CRM_ApplicationDomain.Domain.NKS,
                correlationId
            );
        } catch (fflib_SecurityUtils.FlsException flsEx) {
            errorResponse(403, 'Insufficient access: ' + flsEx.getMessage());
            logger.error(
                'Insufficient access: ' + flsEx.getMessage(),
                null,
                CRM_ApplicationDomain.Domain.NKS,
                correlationId
            );
        } catch (Exception ex) {
            System.debug(ex.getStackTraceString());
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

    //###########################################################//
    //###############     HELPER METHODS       ##################//
    //###########################################################//

    private static List<CRM_Henvendelse> convertToHenvendelseList(List<Conversation_Note__c> convList) {
        List<CRM_Henvendelse> retList = new List<CRM_Henvendelse>();
        Map<String, List<Conversation_Note__c>> convNoteMap = new Map<String, List<Conversation_Note__c>>(); //Mapping behandlingskjedeId to a list of conversation notes
        for (Conversation_Note__c convNote : convList) {
            String behandlingskjedeId = convNote.CRM_Henvendelse_BehandlingskjedeId__c;
            if (convNoteMap.containsKey(behandlingskjedeId)) {
                List<Conversation_Note__c> tempNotes = convNoteMap.get(behandlingskjedeId);
                tempNotes.add(convNote);
                convNoteMap.put(behandlingskjedeId, tempNotes);
            } else {
                convNoteMap.put(behandlingskjedeId, new List<Conversation_Note__c>{ convNote });
            }
        }
        for (List<Conversation_Note__c> noteList : convNoteMap.values()) {
            retList.add(new CRM_Henvendelse(noteList));
        }

        return retList;
    }

    private static List<CRM_Henvendelse> convertToHenvendelseList(List<Thread__c> threadList) {
        List<CRM_Henvendelse> retList = new List<CRM_Henvendelse>();
        for (Thread__c thread : threadList) {
            retList.add(new CRM_Henvendelse(thread, thread.Messages__r, thread.Journal_Entries__r));
        }

        return retList;
    }
}
