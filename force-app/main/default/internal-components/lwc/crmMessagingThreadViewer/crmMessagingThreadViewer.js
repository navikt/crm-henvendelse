import { LightningElement, api, wire } from 'lwc';
import getmessages from '@salesforce/apex/CRM_MessageHelperExperience.getMessagesFromThread';
import markAsReadByNav from '@salesforce/apex/CRM_MessageHelper.markAsReadByNav';
import { subscribe, unsubscribe } from 'lightning/empApi';
import userId from '@salesforce/user/Id';
import { updateRecord, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACTIVE_FIELD from '@salesforce/schema/Thread__c.CRM_isActive__c';
import THREAD_ID_FIELD from '@salesforce/schema/Thread__c.Id';
import REGISTERED_DATE from '@salesforce/schema/Thread__c.CRM_Date_Time_Registered__c';
import END_DIALOGUE_LABEL from '@salesforce/label/c.Henvendelse_End_Dialogue';
import END_DIALOGUE_ALERT_TEXT from '@salesforce/label/c.Henvendelse_End_Dialogue_Alert_Text';
import DIALOGUE_STARTED_TEXT from '@salesforce/label/c.Henvendelse_Dialogue_Started';
import LANGUAGE_CHANGE_ALERT_TEXT from '@salesforce/label/c.Henvendelse_Language_Change_Alert_Text';
import LANGUAGE_CHANGE_YES from '@salesforce/label/c.Henvendelse_Language_Change_Yes';
import LANGUAGE_CHANGE_NO from '@salesforce/label/c.Henvendelse_Language_Change_No';
import CANCEL_LABEL from '@salesforce/label/c.Henvendelse_Cancel';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { publishToAmplitude } from 'c/amplitude';
import LoggerUtility from 'c/loggerUtility';
import newDesignTemplate from './newDesignTemplate.html';
import oldDesignTemplate from './oldDesignTemplate.html';

export default class MessagingThreadViewer extends LightningElement {
    @api thread;
    @api showClose;
    @api showQuick;
    @api englishTextTemplate;
    @api textTemplate; //Support for conditional text template as input
    @api newDesign = false;
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
    createdbyid;
    usertype;
    otheruser;
    _mySendForSplitting;
    threadheader;
    threadId;
    messages = [];
    showspinner = false;
    hideModal = true;
    langBtnAriaToggle = false;
    resizablePanelTop;
    onresize = false; // true when in process of resizing
    mouseListenerCounter = false; // flag for detecting if onmousemove listener is set for element
    registereddate;
    closedThread;
    langBtnLock = false;
    _showLanguageChangeModal = false;

    render() {
        return this.newDesign ? newDesignTemplate : oldDesignTemplate;
    }

    connectedCallback() {
        if (this.thread) {
            this.threadId = this.thread.Id;
        }
        this.handleSubscribe();
        this.scrolltobottom();
        markAsReadByNav({ threadId: this.threadId });
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    renderedCallback() {
        this.scrolltobottom();
        const test = this.template.querySelector('.cancelButton');
        if (test) {
            test.focus();
        }
        this.resizablePanelTop = this.template.querySelector('section');
        this.resizablePanelTop.addEventListener('mousemove', this.mouseMoveEventHandlerBinded, false);
        this.resizablePanelTop.addEventListener('mouseleave', this.mouseLeaveEventHandler, false);
    }

    //##################################//
    //#####    Event Handlers    #######//
    //##################################//

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

    //Handles subscription to streaming API for listening to changes to auth status
    handleSubscribe() {
        // Callback invoked whenever a new message event is received
        const messageCallback = (response) => {
            const messageThreadId = response.data.sobject.CRM_Thread__c;
            if (this.threadId === messageThreadId) {
                //Refreshes the message in the component if the new message event is for the viewed thread
                this.refreshMessages();
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
            .then(() => {
                //Successfull unsubscribe
            })
            .catch((error) => {
                console.log('EMP unsubscribe failed: ' + JSON.stringify(error, null, 2));
            });
    }

    @wire(getRecord, {
        recordId: '$threadId',
        fields: [ACTIVE_FIELD, REGISTERED_DATE]
    })
    wiredThread(resp) {
        const { data, error } = resp;
        if (data) {
            try {
                this.registereddate = getFieldValue(data, REGISTERED_DATE);
                const active = getFieldValue(data, ACTIVE_FIELD);
                this.closedThread = !active;
            } catch (catchError) {
                this.doTheLog(catchError, resp);
            }
        }
        if (error) {
            console.log('Was error');
            console.log(error);
            this.doTheLog(null, resp);
        }
    }

    @wire(getmessages, { threadId: '$threadId' }) //Calls apex and extracts messages related to this record
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
        if (this.newDesign) {
            this.dispatchEvent(new CustomEvent('submitfromgrandchild'));
        }

        publishToAmplitude('STO', { type: 'handlesubmit on thread' });
        event.preventDefault();
        if (!this.quickTextCmp.isOpen) {
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
        let threadId = this.threadId;
        let eventDetails = event.detail;
        eventDetails.threadId = threadId;
        event.threadId = threadId;
    }

    closeThread() {
        publishToAmplitude('STO', { type: 'closeThread' });
        this.closeModal();
        const fields = {};
        fields[THREAD_ID_FIELD.fieldApiName] = this.threadId;
        fields[ACTIVE_FIELD.fieldApiName] = false;

        const threadInput = { fields };
        this.showspinner = true;
        updateRecord(threadInput)
            .then(() => {
                if (!this.newDesign) {
                    const event1 = new ShowToastEvent({
                        title: 'Avsluttet',
                        message: 'Samtalen ble avsluttet',
                        variant: 'success'
                    });
                    this.dispatchEvent(event1);
                } else {
                    this.dispatchEvent(new CustomEvent('closedevent'));
                }
            })
            .catch((error) => {
                console.log(JSON.stringify(error, null, 2));
                if (!this.newDesign) {
                    const event1 = new ShowToastEvent({
                        title: 'Det oppstod en feil',
                        message: 'Samtalen kunne ikke bli avsluttet',
                        variant: 'error'
                    });
                    this.dispatchEvent(event1);
                }
            })
            .finally(() => {
                this.refreshMessages();
                this.showspinner = false;
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
        this.showspinner = false;
        this.refreshMessages();
    }

    scrolltobottom() {
        const element = this.newDesign
            ? this.template.querySelector('[data-id="messagesContainer"]')
            : this.template.querySelector('.slds-box');
        if (element) {
            element.scrollTop = element.scrollHeight;
        }
    }
    refreshMessages() {
        return refreshApex(this._mySendForSplitting);
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

    //##################################//
    //#########    GETTERS    ##########//
    //##################################//

    @api
    get showLanguageChangeModal() {
        return this._showLanguageChangeModal;
    }

    set showLanguageChangeModal(value) {
        this._showLanguageChangeModal = value;
    }

    get quickTextCmp() {
        return this.template.querySelector('c-crm-messaging-quick-text');
    }

    get text() {
        return this.quickTextCmp ? this.quickTextCmp.conversationNote : '';
    }

    get showChangeLngBtn() {
        return !this.hideChangeLngBtn;
    }

    get modalClass() {
        return (
            'slds-modal slds-show ' +
            (this.hideModal ? '' : 'slds-fade-in-open') +
            (this.newDesign ? ' modalStyling' : '')
        );
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

    //##################################//
    //########    MODAL    #############//
    //##################################//

    openModal() {
        publishToAmplitude('STO', { type: 'openModal close thread' });
        this.hideModal = false;
    }

    closeModal() {
        publishToAmplitude('STO', { type: 'closeModal close thread' });
        this.hideModal = true;
        const btn = this.template.querySelector('.endDialogueBtn');
        btn.focus();
    }

    trapFocusStart() {
        const firstElement = this.template.querySelector('.closeButton');
        firstElement.focus();
    }

    trapFocusEnd() {
        const lastElement = this.template.querySelector('.cancelButton');
        lastElement.focus();
    }

    //##################################//
    //##########   Logging   ###########//
    //##################################//

    doTheLog(error, response) {
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
