public without sharing virtual class CRM_HenvendelseApiUtils extends ApexRestService {
    public enum HENVENDELSE_TYPE {
        SAMTALEREFERAT,
        MELDINGSKJEDE,
        CHAT,
        MELDING
    }

    /**
     * @description: Helper method to return the correct HENVENDELSE_TYPE
     * @author Stian Ruud Schikora | 07-08-2021
     * @param typeName
     * @return HENVENDELSE_TYPE
     **/
    public static HENVENDELSE_TYPE getHenvendelseType(String typeName) {
        HENVENDELSE_TYPE returnType;
        for (HENVENDELSE_TYPE henvType : HENVENDELSE_TYPE.values()) {
            if (henvType.name().equalsIgnoreCase(typeName)) {
                returnType = henvType;
            }
        }
        return returnType;
    }

    /**
     * @description: Converts a CRM_Henvendelse to a valid Thread__c. Used for patch updates
     * @author Stian Ruud Schikora | 07-20-2021
     * @param henv
     * @return Thread__
     **/
    public static Thread__c convertToThread(CRM_Henvendelse henv) {
        Thread__c convertedThread = new Thread__c();
        if (String.isNotBlank(henv.kasseringsDato)) {
            convertedThread.CRM_Disposal_Datetime__c = Datetime.valueOfGmt(henv.kasseringsDato.replace('T', ' '));
        }
        if (henv.kontorsperre != null) {
            convertedThread.CRM_Office_Restriction__c = henv.kontorsperre;
        }
        if (henv.feilsendt != null) {
            convertedThread.CRM_Incorrectly_Sent__c = henv.feilsendt;
        }
        if (henv.sladding != null && henv.sladding == true) {
            convertedThread.STO_Sensitive_Information__c = henv.sladding;
        }
        if (String.isNotBlank(henv.gjeldendeTemagruppe)) {
            Id themeGroupId = getThemeGroup(henv.gjeldendeTemagruppe);

            if (themeGroupId == null) {
                throw new HenvendelseConversionException('Invalid code for theme group: ' + henv.gjeldendeTemagruppe);
            }
            convertedThread.CRM_Theme_Group__c = themeGroupId;
        }
        return convertedThread;
    }

    /**
     * @description: Converts a CRM_Henvendelse to a valid Conversation_Note__c. Used for patch updates
     * @author Stian Ruud Schikora | 07-20-2021
     * @param henv
     * @return Conversation_Note__c
     **/
    public static Conversation_Note__c convertToConvNote(CRM_Henvendelse henv) {
        Conversation_Note__c convNote = new Conversation_Note__c();

        if (String.isNotBlank(henv.kasseringsDato)) {
            convNote.CRM_Disposal_Datetime__c = Datetime.valueOfGmt(henv.kasseringsDato.replace('T', ' '));
        }
        if (henv.kontorsperre != null) {
            //Update to set the correct sensoring fields
            convNote.CRM_Office_Restriction__c = henv.kontorsperre;
        }
        if (henv.feilsendt != null) {
            convNote.CRM_Incorrectly_Sent__c = henv.feilsendt;
        }
        if (henv.sladding != null && henv.sladding == true) {
            convNote.STO_Sensitive_Information__c = henv.sladding;
        }
        if (String.isNotBlank(henv.gjeldendeTemagruppe)) {
            Id themeGroupId = getThemeGroup(henv.gjeldendeTemagruppe);

            if (themeGroupId == null) {
                throw new HenvendelseConversionException('Invalid code for theme group: ' + henv.gjeldendeTemagruppe);
            }
            convNote.CRM_Theme_Group__c = themeGroupId;
        }
        return convNote;
    }

    public static Id getThemeGroup(String code) {
        return [SELECT Id FROM Common_Code__c WHERE CRM_Code_Set__c = 'Temagrupper' AND CRM_Code__c = :code]?.Id;
    }

    public static Id getTheme(String code) {
        return [SELECT Id FROM Common_Code__c WHERE CRM_Code_Set__c = 'Tema' AND CRM_Code__c = :code]?.Id;
    }

    /**
     * @description: Formats a datetime to a valid ISO string
     * @author Stian Ruud Schikora | 07-20-2021
     * @param timestamp
     * @return String
     **/
    public String gmtFormatDateTime(DateTime timestamp) {
        return timestamp != null ? timestamp.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX') : null;
    }

    /**
     * @description: Formats a datetime to a valid ISO string
     * @author Stian Ruud Schikora | 07-20-2021
     * @param timestamp
     * @return String
     **/
    public String formatDateTime(DateTime timestamp) {
        return timestamp != null ? timestamp.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX') : null;
    }

    /**
     * @description: For system integration the NAV ident of the user performing the action should be included in a request header
     * @author Stian Ruud Schikora | 07-07-2021
     * @return String
     **/
    public static String getActingNavIdent() {
        return getRequestHeader('X-ACTING-NAV-IDENT');
    }

    /**
     * @description apiReference is unique accross the Thread and Conversation Note table. SOSL search to find the record Id with the matching apiReference
     * @author Stian Ruud Schikora | 10-21-2021
     * @param apiReference
     * @return String
     **/
    public static Id getObjectId(String apiReference) {
        Id objectId;
        //Changed due to delay in SOSL indexing. Perform query to the separate tables instead
        List<Conversation_Note__c> convList = [
            SELECT Id
            FROM Conversation_Note__c
            WHERE CRM_Henvendelse_BehandlingskjedeId__c = :apiReference
            ORDER BY Id
            LIMIT 1
        ];
        List<Thread__c> threadList = [
            SELECT Id
            FROM Thread__c
            WHERE CRM_API_Reference__c = :apiReference
            ORDER BY Id
            LIMIT 1
        ];

        if (convList.size() > 0) {
            objectId = convList[0].Id;
        } else if (threadList.size() > 0) {
            objectId = threadList[0].Id;
        }

        return objectId;
    }

    public class HenvendelseConversionException extends exception {
    }
}
