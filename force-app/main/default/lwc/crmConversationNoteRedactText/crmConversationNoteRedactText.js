import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
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
    wiredConversationNoteResult;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [NAME_FIELD, TEXT_FIELD, IS_REDACTED_FIELD, IS_REDACTED_BY_FIELD]
    })
    wiredConversationNote(result) {
        this.wiredConversationNoteResult = result;
    }

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
                return refreshApex(this.wiredConversationNoteResult);
            })
            .then(() => {
                this.handleSuccess();
            })
            .catch(() => {
                this.handleError();
            });
    }

    revertRedacting() {
        const redactText = this.template.querySelector('c-crm-redact-text');
        if (redactText) {
            redactText.reset();
        }
    }

    toggleRedacting() {
        this.isRedacting = !this.isRedacting;
    }

    handleRedactEvent(event) {
        event.preventDefault();
        this.redactedText = event.detail;
    }

    get text() {
        return getFieldValue(this.wiredConversationNoteResult.data, TEXT_FIELD);
    }

    get isRedacting() {
        return this._isRedacting;
    }

    set isRedacting(value) {
        if (value === false) {
            this.revertRedacting();
        }
        this._isRedacting = value;
    }

    get canSaveDisabled() {
        const redactText = this.template.querySelector('c-crm-redact-text');
        return redactText ? !redactText.hasChanges : false;
    }

    get userId() {
        return getFieldValue(this.wiredConversationNoteResult.data, IS_REDACTED_BY_FIELD);
    }

    get navIdent() {
        return getFieldValue(this.wiredUser.data, NAV_IDENT_FIELD);
    }

    get navUnit() {
        return getFieldValue(this.wiredUser.data, NAV_UNIT_FIELD);
    }

    get isRedacted() {
        return getFieldValue(this.wiredConversationNoteResult.data, IS_REDACTED_FIELD);
    }

    get redactionInfo() {
        const navIdent = this.navIdent;
        const navUnit = this.navUnit;
        if (navIdent && navUnit) {
            return `${navIdent} (Nav-enhet ${navUnit})`;
        }
        if (navIdent) {
            return navIdent;
        }
        if (navUnit) {
            return `(Nav-enhet ${navUnit})`;
        }
        return '';
    }
}
