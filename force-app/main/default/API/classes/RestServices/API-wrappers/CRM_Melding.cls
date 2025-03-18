global class CRM_Melding extends CRM_HenvendelseApiUtils {
    global enum Communication_Channel {
        TELEFON,
        OPPMOTE,
        DIGITAL
    }

    global CRM_MessageFrom fra;
    global String fritekst;
    global String sendtDato;
    global String lestDato;
    global String kanal;
    global String meldingsId;
    global Boolean sladding;
    global String henvendelseId; //Legacy ID for verification purposes

    global CRM_Melding(Message__c message) {
        this.fritekst = message.CRM_Message_Text__c;
        this.sendtDato = formatDateTime(message.CRM_Sent_Date__c);
        this.lestDato = formatDateTime(message.CRM_Read_Datetime__c);
        this.kanal = Communication_Channel.DIGITAL.name();
        this.meldingsId = message.CRM_API_Reference__c;
        this.sladding = message.CRM_Sensitive_Information__c;

        if (message.CRM_Type__c == 'Info') {
            this.fra = new CRM_MessageFrom();
            this.fra.identType = 'SYSTEM';
        } else {
            this.fra = new CRM_MessageFrom(message);
        }
    }

    global CRM_Melding(Conversation_Note__c convNote) {
        this.fritekst = convNote.CRM_Conversation_Note__c;
        this.lestDato = formatDateTime(convNote.CRM_Read_Date__c);
        this.sendtDato = formatDateTime(convNote.CRM_Date_Time_Registered__c);
        this.meldingsId = convNote.CRM_API_Reference__c;
        this.sladding = convNote.STO_Sensitive_Information__c;
        if (String.isNotBlank(convNote.CRM_Communication_Channel__c)) {
            this.kanal = convNote.CRM_Communication_Channel__c.equalsIgnoreCase('Phone')
                ? Communication_Channel.TELEFON.name()
                : Communication_Channel.OPPMOTE.name();
        }
        this.fra = new CRM_MessageFrom();
        //Conversation notes are always created by NAV employees
        this.fra.identType = CRM_MessageFrom.IDENT_TYPES.NAVIDENT.name();
        this.fra.ident = convNote.CRM_Created_By_Ident__c;
        this.fra.navEnhet = convNote.CRM_Created_By_NAV_Unit__c;
    }
}
