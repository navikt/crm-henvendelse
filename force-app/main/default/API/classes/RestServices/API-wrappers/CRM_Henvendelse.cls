global class CRM_Henvendelse extends CRM_HenvendelseApiUtils implements Comparable {
    global String fnr;
    global String aktorId;
    global String kasseringsDato;
    global String avsluttetDato;
    global String opprettetDato;
    global Boolean kontorsperre;
    global Boolean sladding;
    global Boolean feilsendt;
    global String kjedeId;
    global String opprinneligGT;
    global String opprinneligEnhet;
    global String gjeldendeTemagruppe;
    global String gjeldendeTema;
    global String henvendelseType;
    global List<CRM_JournalfortInformasjon> journalposter;
    global List<CRM_Melding> meldinger;
    global List<CRM_Markering> markeringer;
    global String tilknyttetEnhet;
    global String henvendelseId; //Legacy ID for verification purposes, not included in swagger documentation

    global CRM_Henvendelse() {
    }

    global CRM_Henvendelse(List<Conversation_Note__c> noteList) {
        if (noteList == null || noteList.size() == 0)
            return;
        if (noteList.size() > 1) {
            for (Conversation_Note__c convNote : noteList) {
                if (this.kjedeId == null) {
                    //First conversation note defines the henvendelse
                    convertConvNote(convNote, convNote.Journal_Entries__r);
                } else {
                    //Add subsequent conversation note as message wrappers
                    this.meldinger.add(new CRM_Melding(convNote));
                    for (Journal_Entry__c jEntry : convNote.Journal_Entries__r) {
                        if (this.journalposter == null)
                            this.journalposter = new List<CRM_JournalfortInformasjon>();
                        this.journalposter.add(new CRM_JournalfortInformasjon(jEntry));
                    }
                }
            }
        } else {
            convertConvNote(noteList[0], noteList[0].Journal_Entries__r);
        }
    }

    private void convertConvNote(Conversation_Note__c convNote, List<Journal_Entry__c> jeList) {
        this.fnr = convNote.CRM_Account__r.CRM_Person__r.Name;
        this.henvendelseId = convNote.CRM_HenvendelseId__c;
        this.aktorId = convNote.CRM_Account__r.CRM_Person__r.INT_ActorId__c;
        this.gjeldendeTemagruppe = convNote.CRM_Theme_Group_Code__c;
        this.gjeldendeTema = convNote.CRM_Theme_Code__c;
        this.opprinneligGT = convNote.CRM_Original_Person_GT__c;
        this.opprinneligEnhet = convNote.CRM_Original_Person_NAV_Unit__c;
        this.opprettetDato = formatDateTime(convNote.CRM_Date_Time_Registered__c);
        this.avsluttetDato = this.opprettetDato;
        this.kjedeId = convNote.CRM_Henvendelse_BehandlingskjedeId__c;
        this.henvendelseType = HENVENDELSE_TYPE.SAMTALEREFERAT.name();
        this.sladding = convNote.STO_Sensitive_Information__c;

        this.meldinger = new List<CRM_Melding>();
        this.meldinger.add(new CRM_Melding(convNote));

        if (jeList != null && jeList.size() > 0) {
            List<CRM_JournalfortInformasjon> journalPosts = new List<CRM_JournalfortInformasjon>();
            for (Journal_Entry__c jEntry : jeList) {
                journalPosts.add(new CRM_JournalfortInformasjon(jEntry));
            }
            this.journalposter = journalPosts;
        }

        if (convNote.CRM_Office_Restriction__c == true) {
            CRM_Markering_Kontorsperre officeRest = new CRM_Markering_Kontorsperre();
            this.kontorsperre = true;
            officeRest.markertAv = convNote.CRM_Office_Restriction_Activated_By__c;
            officeRest.markertDato = formatDateTime(convNote.CRM_Office_Restriction_Date__c);
            officeRest.kontorsperreGT = String.isNotBlank(this.opprinneligGT) ? this.opprinneligGT : null;
            officeRest.kontorsperreEnhet = String.isNotBlank(this.opprinneligEnhet) ? this.opprinneligEnhet : null;
            addMarkering(officeRest);
        }
        if (convNote.CRM_Incorrectly_Sent__c == true) {
            CRM_Markering incSent = new CRM_Markering();
            this.feilsendt = true;
            incSent.markeringstype = CRM_Markering.MARKING_TYPES.FEILSENDT.name();
            incSent.markertAv = convNote.CRM_Incorrectly_Sent_Activated_By__c;
            incSent.markertDato = formatDateTime(convNote.CRM_Incorrectly_Sent_Date__c);
            addMarkering(incSent);
        }
    }

    private void addMarkering(CRM_Markering markering) {
        if (this.markeringer == null) {
            this.markeringer = new List<CRM_Markering>();
        }

        this.markeringer.add(markering);
    }

    /**
     * @description: Converting Conversation_Note__c and journal entries into wrappers
     * @author Stian Ruud Schikora | 07-23-2021
     * @param convNote
     * @param jeList
     **/
    global CRM_Henvendelse(Conversation_Note__c convNote, List<Journal_Entry__c> jeList) {
        convertConvNote(convNote, jeList);
    }

    /**
     * @description: Converting a Thread__c and its list of messages and journal entries into wrappers
     * @author Stian Ruud Schikora | 07-23-2021
     * @param thread
     * @param messages
     * @param jeList
     **/
    global CRM_Henvendelse(Thread__c thread, List<Message__c> messages, List<Journal_Entry__c> jeList) {
        this.kjedeId = thread.CRM_API_Reference__c;
        this.henvendelseId = thread.CRM_HenvendelseId__c;
        this.fnr = thread.CRM_External_Person_Ident_Formula__c;
        this.aktorId = thread.CRM_External_ActorId_Formula__c;
        this.opprinneligGT = thread.CRM_Original_Person_GT__c;
        this.opprinneligEnhet = thread.CRM_Original_Person_NAV_Unit__c;
        this.kasseringsDato = formatDateTime(thread.CRM_Disposal_Datetime__c);
        this.opprettetDato = formatDateTime(thread.CRM_Date_Time_Registered__c);
        this.avsluttetDato = formatDateTime(thread.CRM_Closed_Date__c);
        this.meldinger = new List<CRM_Melding>();
        this.henvendelseType = (thread.CRM_Type__c == 'CHAT')
            ? HENVENDELSE_TYPE.CHAT.name()
            : HENVENDELSE_TYPE.MELDINGSKJEDE.name();
        this.gjeldendeTemagruppe = thread.CRM_Theme_Group_Code__c;
        this.gjeldendeTema = thread.CRM_Theme_Code__c;
        this.sladding = thread.STO_Sensitive_Information__c;

        for (Message__c message : messages) {
            this.meldinger.add(new CRM_Melding(message));
        }

        if (jeList != null && jeList.size() > 0) {
            List<CRM_JournalfortInformasjon> journalPosts = new List<CRM_JournalfortInformasjon>();
            for (Journal_Entry__c jEntry : jeList) {
                journalPosts.add(new CRM_JournalfortInformasjon(jEntry));
            }
            this.journalposter = journalPosts;
        }

        if (thread.CRM_Office_Restriction__c == true) {
            CRM_Markering_Kontorsperre officeRest = new CRM_Markering_Kontorsperre();
            this.kontorsperre = true;
            officeRest.markertAv = thread.CRM_Office_Restriction_Activated_By__c;
            officeRest.markertDato = formatDateTime(thread.CRM_Office_Restriction_Date__c);
            officeRest.kontorsperreGT = String.isNotBlank(this.opprinneligGT) ? this.opprinneligGT : null;
            officeRest.kontorsperreEnhet = String.isNotBlank(this.opprinneligEnhet) ? this.opprinneligEnhet : null;
            addMarkering(officeRest);
        }
        if (thread.CRM_Incorrectly_Sent__c == true) {
            CRM_Markering incSent = new CRM_Markering();
            this.feilsendt = true;
            incSent.markeringstype = CRM_Markering.MARKING_TYPES.FEILSENDT.name();
            incSent.markertAv = thread.CRM_Incorrectly_Sent_Activated_By__c;
            incSent.markertDato = formatDateTime(thread.CRM_Incorrectly_Sent_Date__c);
            addMarkering(incSent);
        }
    }

    /**
     * @description: Sort functionality which sorts entries by opprettetDato, newest first
     * @author Stian Ruud Schikora | 07-23-2021
     * @param compareTo
     * @return Integer
     **/
    global Integer compareTo(Object compareTo) {
        CRM_Henvendelse compHenv = (CRM_Henvendelse) compareTo;

        Integer retVal = 0;

        if (
            Datetime.valueOf(this.opprettetDato.replace('T', ' ')) >
            Datetime.valueOf(compHenv.opprettetDato.replace('T', ' '))
        ) {
            retVal = -1;
        } else if (
            Datetime.valueOf(this.opprettetDato.replace('T', ' ')) >
            Datetime.valueOf(compHenv.opprettetDato.replace('T', ' '))
        ) {
            retVal = 1;
        }

        return retVal;
    }
}
