import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import redactConversationNote from '@salesforce/apex/CRM_HenvendelseRedactHelper.redactConversationNote';

import NAME_FIELD from '@salesforce/schema/Conversation_Note__c.Name';
import TEXT_FIELD from '@salesforce/schema/Conversation_Note__c.CRM_Conversation_Note__c';
import IS_REDACTED_FIELD from '@salesforce/schema/Conversation_Note__c.CRM_Is_Redacted__c';
import IS_REDACTED_BY_FIELD from '@salesforce/schema/Conversation_Note__c.CRM_Is_Redacted_By__c';
import NAV_IDENT_FIELD from '@salesforce/schema/User.CRM_NAV_Ident__c';
import NAV_UNIT_FIELD from '@salesforce/schema/User.Department';

export default class CrmConversationNoteRedactText extends LightningElement {
    @api recordId;

    redactedText;
    trueValue;
    _isRedacting = false;
    showSpinner = false;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [NAME_FIELD, TEXT_FIELD, IS_REDACTED_FIELD, IS_REDACTED_BY_FIELD]
    })
    wiredConversationNote;

    @wire(getRecord, {
        recordId: '$userId',
        fields: [NAV_IDENT_FIELD, NAV_UNIT_FIELD]
    })
    wiredUser;

    handleSuccess() {
        this.showSpinner = false;
        this.isRedacting = false;
    }

    handleError() {
        this.showSpinner = false;
        this.isRedacting = false;
    }

    handleSubmit(event) {
        event.preventDefault();
        this.showSpinner = true;
        redactConversationNote({ redactedText: this.redactedText, recordId: this.recordId })
            .then(() => {
                this.handleSuccess();
            })
            .catch((error) => {
                this.handleError();
            });
    }

    revertRedacting() {
        this.template.querySelector('c-crm-redact-text').reset();
    }

    toggleRedacting() {
        this.isRedacting = !this.isRedacting;
    }

    handleRedactEvent(event) {
        event.preventDefault();
        this.redactedText = event.detail;
    }

    get text() {
        return getFieldValue(this.wiredConversationNote.data, TEXT_FIELD);
    }

    get isRedacting() {
        return this._isRedacting;
    }

    set isRedacting(value) {
        if (false === value) {
            this.revertRedacting();
        }
        this._isRedacting = value;
    }

    get canSaveDisabled() {
        return this.template.querySelector('c-crm-redact-text')
            ? !this.template.querySelector('c-crm-redact-text').hasChanges
            : false;
    }

    get userId() {
        return getFieldValue(this.wiredConversationNote.data, IS_REDACTED_BY_FIELD);
    }

    get navIdent() {
        return getFieldValue(this.wiredUser.data, NAV_IDENT_FIELD);
    }

    get navUnit() {
        return getFieldValue(this.wiredUser.data, NAV_UNIT_FIELD);
    }
}
