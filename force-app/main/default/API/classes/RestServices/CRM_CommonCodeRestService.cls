@RestResource(urlmapping='/henvendelse/kodeverk/temagrupper')
global without sharing class CRM_CommonCodeRestService extends ApexRestService {
    private static LoggerUtility logger = new LoggerUtility('Henvendelse API');
    @HttpGet
    global static void getThemeGroups() {
        if (!validate()) {
            return;
        }

        String correlationId = getXCorrelation();

        try {
            List<Temagruppe> retGroups = new List<Temagruppe>();
            for (Common_Code__c comCode : [
                SELECT Name, CRM_Code__c
                FROM Common_Code__c
                WHERE CRM_Code_Set__c = 'Temagrupper'
            ]) {
                retGroups.add(new Temagruppe(comCode));
            }
            setResponse(200, JSON.serializePretty(retGroups));
        } catch (Exception ex) {
            errorResponse(500, ex.getMessage());
            logger.error(ex.getMessage(), null, CRM_ApplicationDomain.Domain.NKS, correlationId);
        } finally {
            logger.publish();
        }
    }

    global class Temagruppe {
        global String navn;
        global String kode;

        global Temagruppe(Common_Code__c comCode) {
            this.navn = comCode.Name;
            this.kode = comCode.CRM_Code__c;
        }
    }
}
