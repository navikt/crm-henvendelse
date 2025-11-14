import { LightningElement, api, wire } from 'lwc';
import { subscribe, unsubscribe } from 'lightning/empApi';
import { updateRecord, getRecord, getFieldValue, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import userId from '@salesforce/user/Id';

import getmessages from '@salesforce/apex/CRM_MessageHelperExperience.getMessagesFromThread';
import markAsReadByNav from '@salesforce/apex/CRM_MessageHelper.markAsReadByNav';

import ACTIVE_FIELD from '@salesforce/schema/Thread__c.CRM_isActive__c';
import THREAD_ID_FIELD from '@salesforce/schema/Thread__c.Id';
import THREAD_TYPE from '@salesforce/schema/Thread__c.CRM_Thread_Type__c';
import REGISTERED_DATE from '@salesforce/schema/Thread__c.CRM_Date_Time_Registered__c';

import END_DIALOGUE_LABEL from '@salesforce/label/c.Henvendelse_End_Dialogue';
import END_DIALOGUE_ALERT_TEXT from '@salesforce/label/c.Henvendelse_End_Dialogue_Alert_Text';
import DIALOGUE_STARTED_TEXT from '@salesforce/label/c.Henvendelse_Dialogue_Started';
import LANGUAGE_CHANGE_ALERT_TEXT from '@salesforce/label/c.Henvendelse_Language_Change_Alert_Text';
import LANGUAGE_CHANGE_YES from '@salesforce/label/c.Henvendelse_Language_Change_Yes';
import LANGUAGE_CHANGE_NO from '@salesforce/label/c.Henvendelse_Language_Change_No';
import CANCEL_LABEL from '@salesforce/label/c.Henvendelse_Cancel';

import { publishToAmplitude } from 'c/amplitude';
import LoggerUtility from 'c/loggerUtility';

export default class MessagingThreadViewer extends LightningElement {
    @api thread;
    @api showClose;
    @api showQuick;
    @api englishTextTemplate;
    @api textTemplate; // Support for conditional text template as input
    @api submitButtonLabel = 'Send';
    @api isThread;
    @api hideChangeLngBtn = false;
    @api isCaseReserved;

    labels = {
        END_DIALOGUE_LABEL,
        END_DIALOGUE_ALERT_TEXT,
        DIALOGUE_STARTED_TEXT,
        CANCEL_LABEL,
        LANGUAGE_CHANGE_ALERT_TEXT,
        LANGUAGE_CHANGE_YES,
        LANGUAGE_CHANGE_NO
    };

    _wiredMessagesResult;
    threadId;
    messages = [];
    registereddate;
    threadType;
    isThreadClosed = false;
    showspinner = false;
    hideModal = true;
    langBtnAriaToggle = false;
    resizablePanelTop;
    onresize = false; // true when in process of resizing
    mouseListenerCounter = false; // flag for detecting if onmousemove listener is set for element
    langBtnLock = false;

    connectedCallback() {
        if (this.thread) {
            this.threadId = this.thread.Id;
        }

        this.handleSubscribe();
        markAsReadByNav({ threadId: this.threadId });
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    renderedCallback() {
        this.scrolltobottom();

        this.resizablePanelTop = this.template.querySelector('section');
        this.resizablePanelTop.addEventListener('mousemove', this.mouseMoveEventHandlerBinded, false);
        this.resizablePanelTop.addEventListener('mouseleave', this.mouseLeaveEventHandler, false);
    }

    handleSubscribe() {
        if (this.subscription) return;

        const messageCallback = (response) => {
            const messageThreadId = response.data.sobject.CRM_Thread__c;
            if (this.threadId === messageThreadId) {
                this.refreshMessages();
            }
        };

        subscribe('/topic/Thread_New_Message', -1, messageCallback).then((response) => {
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        if (!this.subscription) return;

        unsubscribe(this.subscription)
            .then(() => {
                this.subscription = null;
            })
            .catch((err) => {
                console.warn('EMP unsubscribe failed', err);
            });
    }

    @wire(getRecord, {
        recordId: '$threadId',
        fields: [ACTIVE_FIELD, REGISTERED_DATE, THREAD_TYPE]
    })
    wiredThread(resp) {
        const { data, error } = resp;
        if (data) {
            try {
                this.registereddate = getFieldValue(data, REGISTERED_DATE);
                this.threadType = getFieldValue(data, THREAD_TYPE);
                this.isThreadClosed = !getFieldValue(data, ACTIVE_FIELD);
            } catch (err) {
                this.logThreadError(err, resp);
            }
        } else if (error) {
            console.error(error);
            this.logThreadError(null, resp);
        }
    }

    @wire(getmessages, { threadId: '$threadId' })
    wiremessages(result) {
        this._wiredMessagesResult = result;
        if (result.error) {
            this.error = result.error;
        } else if (result.data) {
            this.messages = result.data;
            this.showspinner = false;
        }
    }

    handleSubmit(event) {
        event.preventDefault();

        const submitEvent = new CustomEvent('messagesentonsubmit', {
            bubbles: true,
            composed: true
        });
        this.dispatchEvent(submitEvent);

        publishToAmplitude('STO', { type: 'handleSubmit on thread' });

        if (this.quickTextCmp?.isOpen) return;

        this.showspinner = true;
        const textInput = event.detail.fields;
        // If messagefield is empty, stop the submit
        textInput.CRM_Thread__c = this.thread.Id;
        textInput.CRM_From_User__c = userId;

        if (!textInput.CRM_Message_Text__c) {
            const toastEvent = new ShowToastEvent({
                title: 'Message Body missing',
                message: 'Make sure that you fill in the message text',
                variant: 'error'
            });
            this.dispatchEvent(toastEvent);
            this.showspinner = false;
        } else {
            this.template.querySelector('lightning-record-edit-form').submit(textInput);
        }
    }

    handleSuccess(event) {
        this.recordId = event.detail;
        this.quickTextCmp.clear();
        this.template.querySelectorAll('.msgText')?.forEach((field) => field.reset());

        if (this.threadType === 'BTO') {
            this.closeThread();
        } else {
            this.showspinner = false;
            this.refreshMessages();
        }
    }

    closeThread() {
        publishToAmplitude('STO', { type: 'closeThread' });
        if (!this.hideModal) {
            this.closeModal();
        }

        const fields = {};
        fields[THREAD_ID_FIELD.fieldApiName] = this.threadId;
        fields[ACTIVE_FIELD.fieldApiName] = false;

        this.showspinner = true;
        updateRecord({ fields })
            .then(() => {
                notifyRecordUpdateAvailable([{recordId: this.threadId}]);
                const closedEvent = new CustomEvent('threadclosed', {
                    bubbles: true,
                    composed: true
                });
                this.dispatchEvent(closedEvent);
            })
            .catch((error) => {
                console.log(JSON.stringify(error, null, 2));
            })
            .finally(() => {
                this.refreshMessages();
                this.showspinner = false;
            });
    }

    refreshMessages() {
        return refreshApex(this._wiredMessagesResult);
    }

    scrolltobottom() {
        const element = this.template.querySelector('[data-id="messagesContainer"]');
        if (element) {
            element.scrollTop = element.scrollHeight;
        }
    }

    // Enriching the toolbar event with reference to the thread id
    // A custom toolbaraction event can be passed from the component in the toolbar slot that the thread viewer enrich with the thread id
    handleToolbarAction(event) {
        event.detail.threadId = this.threadId;
        event.threadId = this.threadId;
    }

    showQuickText(event) {
        publishToAmplitude('STO', { type: 'showQuickText' });
        this.quickTextCmp.showModal(event);
    }

    handleLangClick() {
        publishToAmplitude('STO', { type: 'handleLangClick' });
        const langObj = {
            englishTextTemplate: this.resetTemplate ? this.englishTextTemplate : !this.englishTextTemplate,
            userInput: this.text,
            resetTemplate: this.resetTemplate,
            closeLanguageModal: this.closeLanguageModal
        };
        const englishEvent = new CustomEvent('englishevent', {
            detail: langObj
        });
        this.langBtnAriaToggle = !this.langBtnAriaToggle;
        this.resetTemplate = false;
        this.closeLanguageModal = false;
        this.dispatchEvent(englishEvent);
    }

    lockLangBtn() {
        this.langBtnLock = true;
    }

    toggleEndDialogueButton() {
        this.hideModal = !this.hideModal;
    }

    handleEnglishStoClearEvent(event) {
        const langObj = { englishTextTemplate: this.englishTextTemplate, userInput: event.detail };
        const englishEvent = new CustomEvent('englishevent', {
            detail: langObj
        });
        this.dispatchEvent(englishEvent);
    }

    closeLanguageChangeModal() {
        this.closeLanguageModal = true;
        this.handleLangClick();
    }

    changeTemplate() {
        this.resetTemplate = true;
        this.handleLangClick();
    }

    // Getters
    get quickTextCmp() {
        return this.template.querySelector('c-crm-messaging-quick-text');
    }

    get text() {
        //return this.quickTextCmp?.conversationNote ?? '';
        return this.quickTextCmp ? this.quickTextCmp.conversationNote : '';
    }

    get showChangeLngBtn() {
        return !this.hideChangeLngBtn;
    }

    get modalClass() {
        return `slds-modal slds-show ${this.hideModal ? '' : 'slds-fade-in-open'} modalStyling`;
    }

    get backdropClass() {
        return this.hideModal ? 'slds-hide' : 'backdrop';
    }

    get langBtnVariant() {
        return !this.englishTextTemplate ? 'neutral' : 'brand';
    }

    get langAria() {
        return !this.langBtnAriaToggle ? 'Språk knapp, Norsk' : 'Språk knapp, Engelsk';
    }

    get hasEnglishTemplate() {
        return this.englishTextTemplate !== undefined;
    }

    get buttonExpanded() {
        return this.hideModal.toString();
    }

    get showCloseButton() {
        return this.showClose && this.threadType !== 'BTO';
    }

    // Modal
    openModal() {
        publishToAmplitude('STO', { type: 'openModal close thread' });
        this.hideModal = false;
        const cancelBtn = this.template.querySelector('.cancelButton');
        cancelBtn?.focus();
    }

    closeModal() {
        publishToAmplitude('STO', { type: 'closeModal close thread' });
        this.hideModal = true;
        const endDialogueBtn = this.template.querySelector('.endDialogueBtn');
        endDialogueBtn?.focus();
    }

    trapFocusStart() {
        const firstElement = this.template.querySelector('.closeButton');
        firstElement.focus();
    }

    trapFocusEnd() {
        const lastElement = this.template.querySelector('.cancelButton');
        lastElement.focus();
    }

    //Event Handlers
    mouseMoveEventHandler(e) {
        // detecting if cursor is in the area of interest
        if (this.resizablePanelTop.getBoundingClientRect().bottom - e.pageY < 10) {
            // change cursor style, and adding listener for mousedown event
            document.body.style.cursor = 'ns-resize';
            if (!this.mouseListenerCounter) {
                this.resizablePanelTop.addEventListener('mousedown', this.mouseDownEventHandlerBinded, false);
                this.mouseListenerCounter = true;
            }
        } else {
            // remove listener and reset cursor when cursor is out of area of interest
            if (this.mouseListenerCounter) {
                this.resizablePanelTop.removeEventListener('mousedown', this.mouseDownEventHandlerBinded, false);
                this.mouseListenerCounter = false;
            }
            document.body.style.cursor = 'auto';
        }
    }
    //binding, to make 'this' available when running in context of other object
    mouseMoveEventHandlerBinded = this.mouseMoveEventHandler.bind(this);

    mouseLeaveEventHandler() {
        if (this.mouseListenerCounter) {
            this.resizablePanelTop.removeEventListener('mousedown', this.mouseDownEventHandlerBinded, false);
            this.mouseListenerCounter = false;
        }
        document.body.style.cursor = 'auto';
    }

    mouseDownEventHandler() {
        this.onresize = true;
        this.resizablePanelTop.removeEventListener('mousedown', this.mouseDownEventHandlerBinded, false);
        document.addEventListener('mouseup', this.mouseUpEventHandlerBinded, true);
        this.resizablePanelTop.removeEventListener('mousemove', this.mouseMoveEventHandlerBinded, false);
        this.resizablePanelTop.removeEventListener('mouseleave', this.mouseLeaveEventHandler, false);
        document.addEventListener('mousemove', this.resizeEventHandlerBinded, true);
    }
    mouseDownEventHandlerBinded = this.mouseDownEventHandler.bind(this);

    resizeEventHandler(e) {
        e.preventDefault();
        this.resizablePanelTop.style.height = this.resizablePanelTop.offsetHeight + e.movementY + 'px';
    }
    resizeEventHandlerBinded = this.resizeEventHandler.bind(this);

    mouseUpEventHandler() {
        this.onresize = false;
        this.resizablePanelTop.removeEventListener('mousedown', this.mouseDownEventHandlerBinded, false);
        document.removeEventListener('mouseup', this.mouseUpEventHandlerBinded, true);
        document.removeEventListener('mousemove', this.resizeEventHandlerBinded, true);
        document.body.style.cursor = 'auto';
        this.resizablePanelTop.addEventListener('mousemove', this.mouseMoveEventHandlerBinded, false);
        this.resizablePanelTop.addEventListener('mouseleave', this.mouseLeaveEventHandler, false);
        this.mouseListenerCounter = false;
    }
    mouseUpEventHandlerBinded = this.mouseUpEventHandler.bind(this);

    logThreadError(error, response) {
        const report = `Error: ${error}, response: ${JSON.stringify(response)}`;
        LoggerUtility.logError(
            'NKS',
            'STO',
            report,
            'Could not fetch active field from thread internal view',
            this.threadId
        );
    }
}
