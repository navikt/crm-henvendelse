import { LightningElement, api, wire, track } from 'lwc';
import getmessages from '@salesforce/apex/CRM_MessageHelper.getMessagesFromThread';
import getJournalInfo from '@salesforce/apex/CRM_MessageHelper.getJournalEntries';
import { subscribe, unsubscribe } from 'lightning/empApi';

import userId from '@salesforce/user/Id';
import { updateRecord, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACTIVE_FIELD from '@salesforce/schema/Thread__c.CRM_isActive__c';
import THREAD_ID_FIELD from '@salesforce/schema/Thread__c.Id';
import CREATED_BY_FIELD from '@salesforce/schema/Thread__c.CreatedById';
import REGISTERED_DATE from '@salesforce/schema/Thread__c.CRM_Date_Time_Registered__c';
import FIRSTNAME_FIELD from '@salesforce/schema/Thread__c.CreatedBy.FirstName';
import LASTNAME_FIELD from '@salesforce/schema/Thread__c.CreatedBy.LastName';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class messagingThreadViewer extends LightningElement {
    createdbyid;
    usertype;
    otheruser;
    _mySendForSplitting;
    @api thread;
    threadheader;
    threadid;
    messages = [];
    showspinner = false;
    @api showClose;
    @api englishTextTemplate;
    @api resetTestTemplate;
    @track langBtnLock = false;
    langBtnAriaToggle = false;

    @api textTemplate; //Support for conditional text template as input
    //Constructor, called onload
    connectedCallback() {
        if (this.thread) {
            this.threadid = this.thread.Id;
        }
        this.handleSubscribe();
        this.scrolltobottom();
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }
    renderedCallback() {
        this.scrolltobottom();
    }

    //Handles subscription to streaming API for listening to changes to auth status
    handleSubscribe() {
        let _this = this;
        // Callback invoked whenever a new message event is received
        const messageCallback = function (response) {
            const messageThreadId = response.data.sobject.CRM_Thread__c;
            if (_this.threadid == messageThreadId) {
                //Refreshes the message in the component if the new message event is for the viewed thread
                _this.refreshMessages();
            }
        };

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe('/topic/Thread_New_Message', -1, messageCallback).then((response) => {
            // Response contains the subscription information on successful subscribe call
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription, (response) => {
            console.log('Unsubscribed: ', JSON.stringify(response));
            // Response is true for successful unsubscribe
        })
            .then((success) => {
                //Successfull unsubscribe
            })
            .catch((error) => {
                console.log('EMP unsubscribe failed: ' + JSON.stringify(error, null, 2));
            });
    }

    @wire(getJournalInfo, { threadId: '$threadid' })
    wiredJournalEntries;

    @wire(getRecord, {
        recordId: '$threadid',
        fields: [ACTIVE_FIELD, CREATED_BY_FIELD, FIRSTNAME_FIELD, LASTNAME_FIELD, REGISTERED_DATE]
    })
    wiredThread;

    @wire(getmessages, { threadId: '$threadid' }) //Calls apex and extracts messages related to this record
    wiremessages(result) {
        this._mySendForSplitting = result;
        if (result.error) {
            this.error = result.error;
        } else if (result.data) {
            this.messages = result.data;
            this.showspinner = false;
        }
    }
    //If empty, stop submitting.
    handlesubmit(event) {
        event.preventDefault();
        if (!this.quickTextCmp.isOpen()) {
            this.showspinner = true;
            const textInput = event.detail.fields;
            // If messagefield is empty, stop the submit
            textInput.CRM_Thread__c = this.thread.Id;
            textInput.CRM_From_User__c = userId;

            if (textInput.CRM_Message_Text__c == null || textInput.CRM_Message_Text__c === '') {
                const event1 = new ShowToastEvent({
                    title: 'Message Body missing',
                    message: 'Make sure that you fill in the message text',
                    variant: 'error'
                });
                this.dispatchEvent(event1);
                this.showspinner = false;
            } else {
                this.template.querySelector('lightning-record-edit-form').submit(textInput);
            }
        }
    }

    //Enriching the toolbar event with reference to the thread id
    //A custom toolbaraction event can be passed from the component in the toolbar slot that the thread viewer enrich with the thread id
    handleToolbarAction(event) {
        let threadId = this.threadid;
        let eventDetails = event.detail;
        eventDetails.threadId = threadId;
        event.threadId = threadId;
    }

    closeThread() {
        const fields = {};
        fields[THREAD_ID_FIELD.fieldApiName] = this.threadid;
        fields[ACTIVE_FIELD.fieldApiName] = false;

        const threadInput = { fields };

        updateRecord(threadInput)
            .then(() => {})
            .catch((error) => {
                console.log(JSON.stringify(error, null, 2));
            });
    }

    handlesuccess(event) {
        this.recordId = event.detail;

        this.quickTextCmp.clear();
        const inputFields = this.template.querySelectorAll('.msgText');

        if (inputFields) {
            inputFields.forEach((field) => {
                field.reset();
            });
        }
        //this.showspinner = false;
        this.showspinner = false;
        this.refreshMessages();
    }

    scrolltobottom() {
        var element = this.template.querySelector('.slds-box');
        if (element) {
            element.scrollTop = element.scrollHeight;
        }
    }
    refreshMessages() {
        return refreshApex(this._mySendForSplitting);
    }

    showQuickText(event) {
        this.quickTextCmp.showModal(event);
    }

    handleLangClick() {
        const englishEvent = new CustomEvent('englishevent', {
            detail: !this.englishTextTemplate
        });
        this.langBtnAriaToggle = !this.langBtnAriaToggle;
        this.dispatchEvent(englishEvent);
    }

    lockLangBtn() {
        this.langBtnLock = true;
    }

    //##################################//
    //#########    GETTERS    ##########//
    //##################################//

    get registereddate() {
        return getFieldValue(this.wiredThread.data, REGISTERED_DATE);
    }

    get journalEntries() {
        if (this.wiredJournalEntries) {
            return this.wiredJournalEntries.data;
        }

        return null;
    }

    get closedThread() {
        return !getFieldValue(this.wiredThread.data, ACTIVE_FIELD);
    }

    get quickTextCmp() {
        return this.template.querySelector('c-crm-messaging-quick-text');
    }

    get text() {
        return this.quickTextCmp ? this.quickTextCmp.conversationNote : '';
    }

    get langBtnVariant() {
        return this.englishTextTemplate === false ? 'neutral' : 'brand';
    }

    get langAria() {
        return this.langBtnAriaToggle === false ? 'Språk knapp, Norsk' : 'Språk knapp, Engelsk';
    }
}
