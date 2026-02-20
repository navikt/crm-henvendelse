/**
 * @description       :
 * @author            : eirikfladby
 * @group             :
 * @last modified on  : 28-01-2026
 * @last modified by  : eirikfladby
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

        if (String.isBlank(actorId)) {
            errorResponse(400, 'Missing required query input: aktorid');
            logger.publish();
            return;
        }

        try {
            String pageParam = getRequestParam('page');
            String pageSizeParam = getRequestParam('pageSize');

            Integer pageNumber = pageParam != null ? Integer.valueOf(pageParam) : 1;
            Integer pageSize = pageSizeParam != null ? Integer.valueOf(pageSizeParam) : 50;

            // Validate pagination parameters
            if (pageNumber < 1) {
                errorResponse(400, 'Page number must be greater than 0');
                return;
            }
            if (pageSize < 1 || pageSize > 200) {
                errorResponse(400, 'Page size must be between 1 and 200');
                return;
            }

            // Calculate how many records we need to query from each SObject type
            // We query (pageNumber * pageSize) + 1 to detect if more records exist
            Integer queryLimit = (pageNumber * pageSize) + 1;

            Integer convCount = new CRM_ConversationNoteSelector().countDistinctByActorId(new Set<String>{ actorId });
            Integer threadCount = new CRM_ThreadSelector().countByActorId(new Set<String>{ actorId });
            Integer totalRecords = convCount + threadCount;
            Integer totalPages = totalRecords == 0 ? 0 : Integer.valueOf(Math.ceil((Decimal) totalRecords / pageSize));

            List<CRM_Henvendelse> fullList = new List<CRM_Henvendelse>();
            List<Conversation_Note__c> convList = new CRM_ConversationNoteSelector()
                .selectByActorId(new Set<String>{ actorId }, queryLimit);
            fullList.addAll(convertToHenvendelseList(convList));

            List<Thread__c> threadList = new CRM_ThreadSelector()
                .selectByActorId(new Set<String>{ actorId }, queryLimit);
            fullList.addAll(convertToHenvendelseList(threadList));
            fullList.sort();

            // Slice to get only the requested page
            Integer startIndex = (pageNumber - 1) * pageSize;
            Integer endIndex = Math.min(startIndex + pageSize, fullList.size());

            List<CRM_Henvendelse> returnList = new List<CRM_Henvendelse>();
            if (startIndex < fullList.size()) {
                for (Integer i = startIndex; i < endIndex; i++) {
                    returnList.add(fullList[i]);
                }
            }

            // If we have more records in fullList than we're returning, more pages exist
            Boolean hasNextPage = endIndex < fullList.size();

            CRM_PaginatedHenvendelseResponse paginatedResponse = new CRM_PaginatedHenvendelseResponse();
            paginatedResponse.data = returnList;
            paginatedResponse.currentPage = pageNumber;
            paginatedResponse.pageSize = pageSize;
            paginatedResponse.totalPages = totalPages;
            paginatedResponse.hasNextPage = hasNextPage;

            setResponse(200, JSON.serialize(paginatedResponse));
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
                'Exception: ' + ex.getMessage() + '\n' + ex.getStackTraceString(),
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
