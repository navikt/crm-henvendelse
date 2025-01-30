import { LightningElement, wire, api } from 'lwc';
import getmessages from '@salesforce/apex/CRM_MessageHelperExperience.getMessagesFromThread';
import markAsRead from '@salesforce/apex/CRM_MessageHelperExperience.markAsRead';
import { refreshApex } from '@salesforce/apex';
import getContactId from '@salesforce/apex/CRM_MessageHelperExperience.getUserContactId';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import createmsg from '@salesforce/apex/CRM_MessageHelperExperience.createMessage';
import THREADNAME_FIELD from '@salesforce/schema/Thread__c.STO_ExternalName__c';
import THREADCLOSED_FIELD from '@salesforce/schema/Thread__c.CRM_Is_Closed__c';
import THREAD_TYPE_FIELD from '@salesforce/schema/Thread__c.CRM_Type__c';
import { loadStyle } from 'lightning/platformResourceLoader';
import navStyling from '@salesforce/resourceUrl/navStyling';
import index from '@salesforce/resourceUrl/index';
import { AnalyticsEvents, logButtonEvent } from 'c/amplitude';

const fields = [THREADNAME_FIELD, THREADCLOSED_FIELD, THREAD_TYPE_FIELD]; //Extract the name of the thread record

export default class CrmMessagingCommunityThreadViewer extends LightningElement {
    @api recordId;
    @api alerttext = 'Dialogen er lukket.';
    @api header;
    @api secondheader;
    @api alertopen;
    @api maxLength;
    @api overrideValidation = false;
    @api errorList = { title: '', errors: [] };
    @api logAmplitudeEvent = false;

    _mySendForSplitting;
    messages = [];
    buttonisdisabled = false;
    msgVal;
    userContactId;
    thread;

    connectedCallback() {
        markAsRead({ threadId: this.recordId });
        getContactId({})
            .then((contactId) => {
                this.userContactId = contactId;
            })
            .catch((error) => {
                //Apex error
            });
    }

    renderedCallback() {
        loadStyle(this, navStyling);
        loadStyle(this, index);
    }

    @wire(getRecord, { recordId: '$recordId', fields })
    wirethread(result) {
        this.thread = result;
    }

    @wire(getmessages, { threadId: '$recordId' }) //Calls apex and extracts messages related to this record
    wiremessages(result) {
        this._mySendForSplitting = result;
        if (result.error) {
            this.error = result.error;
        } else if (result.data) {
            this.messages = result.data;
            this.showspinner = false;
        }
    }

    get isSTO() {
        const value = getFieldValue(this.thread.data, THREAD_TYPE_FIELD);
        return value === 'STO' || value === 'STB';
    }

    get showopenwarning() {
        if (this.alertopen) {
            return !this.isSTO;
        }
        return false;
    }

    get name() {
        return getFieldValue(this.thread.data, THREADNAME_FIELD);
    }

    get isclosed() {
        return getFieldValue(this.thread.data, THREADCLOSED_FIELD);
    }

    get showClosedText() {
        return this.isclosed && !this.isSTO;
    }
    /**
     * Blanks out all text fields, and enables the submit-button again.
     * @Author lars Petter Johnsen
     */
    handlesuccess() {
        const inputFields = this.template.querySelectorAll('.msgText');
        if (inputFields) {
            inputFields.forEach((field) => {
                field.reset();
            });
        }
        const textBoks = this.template.querySelector('c-community-textarea');
        textBoks.clearText();
        this.buttonisdisabled = false;
        return refreshApex(this._mySendForSplitting);
    }

    handleMessageFailed() {
        this.buttonisdisabled = true;
        refreshApex(this._mySendForSplitting);
        // eslint-disable-next-line @lwc/lwc/no-api-reassignments
        this.errorList = {
            title: 'Denne samtalen har blitt avsluttet.',
            errors: [
                {
                    Id: 1,
                    EventItem: '',
                    Text: 'Vil du <a href="https://www.nav.no/person/kontakt-oss/nb/skriv-til-oss">sende en ny melding</a>, kan du gjøre det her. Husk å kopiere det du har skrevet.'
                }
            ]
        };
        let errorSummary = this.template.querySelector('.errorSummary');
        errorSummary.focusHeader();
    }

    /**
     * Creates a message through apex
     */
    @api
    createMessage(validation) {
        if (validation !== true) {
            this.buttonisdisabled = false;
            return;
        }
        createmsg({ threadId: this.recordId, messageText: this.msgVal, fromContactId: this.userContactId })
            .then((result) => {
                if (result === true) {
                    this.handlesuccess();
                } else {
                    this.handleMessageFailed();
                }
            })
            .catch((error) => console.log(error));
    }

    handleSendButtonClick() {
        this.buttonisdisabled = true;
        // Sending out event to parent to handle any needed validation
        if (this.overrideValidation === true) {
            const validationEvent = new CustomEvent('validationevent', {
                msg: this.msgVal,
                maxLength: this.maxLength
            });
            this.dispatchEvent(validationEvent);
        } else {
            // Using default validation
            this.createMessage(this.valid());
        }

        if (this.logAmplitudeEvent) {
            logButtonEvent(AnalyticsEvents.FORM_COMPLETED, 'Send', 'crmCommunityThreadViewer', this.name);
        }
    }

    valid() {
        // This function will never run of errorList is defined from parent with overrideValidation
        // eslint-disable-next-line @lwc/lwc/no-api-reassignments
        this.errorList = { title: '', errors: [] };
        if (!this.msgVal || this.msgVal.length == null) {
            this.errorList.errors.push({ Id: 1, EventItem: '.inputTextbox', Text: 'Tekstboksen kan ikke være tom.' });
        } else if (this.maxLength !== 0 && this.maxLength != null && this.msgVal.length > this.maxLength) {
            this.errorList.errors.push({
                Id: 2,
                EventItem: '.inputTextbox',
                Text: 'Det er for mange tegn i tekstboksen.'
            });
        } else {
            return true;
        }
        let errorSummary = this.template.querySelector('.errorSummary');
        errorSummary.focusHeader();
        return false;
    }

    handleTextChange(event) {
        this.msgVal = event.detail;
    }

    handleErrorClick(event) {
        let item = this.template.querySelector(event.detail);
        item.focus();
    }
}
