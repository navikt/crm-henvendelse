import { LightningElement, api, track } from 'lwc';

export default class CrmMessagingRedactMessage extends LightningElement {
    _message;
    messageId;
    messageText;
    redactedText;
    _isRedacting = false;
    trueValue = true;
    showSpinner = false;

    @track redactAll = false;

    handleSuccess() {
        this.showSpinner = false;
        this.isRedacting = false;
    }

    handleError() {
        this.showSpinner = false;
        this.isRedacting = false;
    }

    handleSubmit() {
        this.showSpinner = true;
    }

    toggleRedacting() {
        this.isRedacting = !this.isRedacting;
    }

    handleRedactEvent(event) {
        event.preventDefault();
        this.redactedText = event.detail;
    }

    RedactAllMessageText() {
        this.redactedText = '***';
        this.redactTextComponent.addRedactedValue(this.redactedText);

        this.redactAll = true;
        this.dispatchEvent(new CustomEvent('redactall', { detail: this.redactAll }));
    }

    @api
    get message() {
        return this._message;
    }

    set message(value) {
        this._message = value;
        this.messageText = this.message.CRM_Message_Text__c;
        this.redactedText = this.message.CRM_Message_Text__c;
        this.messageId = this.message.Id;
    }

    get isEvent() {
        return this.message.CRM_Type__c === 'Event';
    }

    get isInfo() {
        return this.message.CRM_Type__c === 'Info';
    }

    get isRedacting() {
        return this._isRedacting;
    }

    set isRedacting(value) {
        if (false === value) {
            this.redactTextComponent.reset();
        }
        this._isRedacting = value;
    }

    get isInbound() {
        return this.message.CRM_External_Message__c;
    }

    get liClasses() {
        const cssClass = this.message.CRM_External_Message__c
            ? 'slds-chat-listitem_inbound'
            : 'slds-chat-listitem_outbound';
        return `slds-chat-listitem ${cssClass}`;
    }

    get divClasses() {
        let cssClass = this.message.CRM_External_Message__c
            ? 'slds-chat-message__text_inbound'
            : 'slds-chat-message__text_outbound';
        cssClass += this.message.CRM_Sensitive_Information__c ? ' redaction-marked ' : '';
        return `slds-chat-message__text ${cssClass}`;
    }

    get redactTextComponent() {
        return this.template.querySelector('c-crm-redact-text');
    }

    get canSaveDisabled() {
        return this.redactTextComponent ? !this.redactTextComponent.hasChanges : false;
    }
}
