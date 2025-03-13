global class CRM_MessageFrom {
    global enum IDENT_TYPES {
        NAVIDENT,
        AKTORID
    }

    global String identType;
    global String ident;
    global String navEnhet;

    global CRM_MessageFrom() {
    }

    global CRM_MessageFrom(Message__c message) {
        this.identType = message.CRM_External_Message__c == true
            ? CRM_MessageFrom.IDENT_TYPES.AKTORID.name()
            : CRM_MessageFrom.IDENT_TYPES.NAVIDENT.name();
        this.ident = message.CRM_From_Ident_Formula__c;
        this.navEnhet = message.CRM_From_NAV_Unit__c;
    }
}
