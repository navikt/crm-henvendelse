import { LightningElement, api, wire, track } from 'lwc';
import getmessages from '@salesforce/apex/CRM_MessageHelper.getMessagesFromThread';
import markAsReadByNav from '@salesforce/apex/CRM_MessageHelper.markAsReadByNav';
import { subscribe, unsubscribe } from 'lightning/empApi';
import userId from '@salesforce/user/Id';
import { updateRecord, getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACTIVE_FIELD from '@salesforce/schema/Thread__c.CRM_isActive__c';
import THREAD_ID_FIELD from '@salesforce/schema/Thread__c.Id';
import REGISTERED_DATE from '@salesforce/schema/Thread__c.CRM_Date_Time_Registered__c';
import COMPLETE_LABEL from '@salesforce/label/c.NKS_Complete';
import CREATE_NAV_TASK_LABEL from '@salesforce/label/c.NKS_Create_NAV_Task';
import JOURNAL_LABEL from '@salesforce/label/c.NKS_Journal';
import END_DIALOGUE_LABEL from '@salesforce/label/c.NKS_End_Dialogue';
import SEND_TO_REDACTION_LABEL from '@salesforce/label/c.NKS_Set_To_Redaction';
import END_DIALOGUE_ALERT_TEXT from '@salesforce/label/c.NKS_End_Dialogue_Alert_Text';
import DIALOGUE_STARTED_TEXT from '@salesforce/label/c.NKS_DIALOGUE_STARTED';
import CANCEL_LABEL from '@salesforce/label/c.NKS_Cancel';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { publishToAmplitude } from 'c/amplitude';
import LoggerUtility from 'c/loggerUtility';

export default class MessagingThreadViewer extends LightningElement {
    @api recordId;
    @api thread;
    @api showQuick;
    @api englishTextTemplate;
    @api textTemplate;
    @api showClose;

    @track langBtnLock = false;

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
    onresize = false;
    mouseListenerCounter = false;
    registereddate;
    closedThread;

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
        if (this.resizablePanelTop.getBoundingClientRect().bottom - e.pageY < 10) {
            document.body.style.cursor = 'ns-resize';
            if (this.mouseListenerCounter !== true) {
                this.resizablePanelTop.addEventListener('mousedown', this.mouseDownEventHandlerBinded, false);
                this.mouseListenerCounter = true;
            }
        } else {
            if (this.mouseListenerCounter === true) {
                this.resizablePanelTop.removeEventListener('mousedown', this.mouseDownEventHandlerBinded, false);
                this.mouseListenerCounter = false;
            }
            document.body.style.cursor = 'auto';
        }
    }
    mouseMoveEventHandlerBinded = this.mouseMoveEventHandler.bind(this);

    mouseLeaveEventHandler(e) {
        if (this.mouseListenerCounter === true) {
            this.resizablePanelTop.removeEventListener('mousedown', this.mouseDownEventHandlerBinded, false);
            this.mouseListenerCounter = false;
        }
        document.body.style.cursor = 'auto';
    }

    mouseDownEventHandler(e) {
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

    mouseUpEventHandler(e) {
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

    handleSubscribe() {
        let _this = this;
        const messageCallback = function (response) {
            const messageThreadId = response.data.sobject.CRM_Thread__c;
            if (_this.threadId == messageThreadId) {
                _this.refreshMessages();
            }
        };
        subscribe('/topic/Thread_New_Message', -1, messageCallback).then((response) => {
            this.subscription = response;
        });
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription, (response) => {
            console.log('Unsubscribed: ', JSON.stringify(response));
        })
            .then((success) => {})
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

    @wire(getmessages, { threadId: '$threadId' })
    wiremessages(result) {
        this._mySendForSplitting = result;
        if (result.error) {
            this.error = result.error;
        } else if (result.data) {
            this.messages = result.data;
            this.showspinner = false;
        }
    }
    handlesubmit(event) {
        publishToAmplitude('STO', { type: 'handlesubmit on thread' });

        this.lockLangBtn();
        event.preventDefault();
        if (!this.quickTextCmp.isOpen()) {
            this.showspinner = true;
            const textInput = event.detail.fields;
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
                const event1 = new ShowToastEvent({
                    title: 'Avsluttet',
                    message: 'Samtalen ble avsluttet',
                    variant: 'success'
                });
                this.dispatchEvent(event1);
            })

            .catch((error) => {
                console.log(JSON.stringify(error, null, 2));
                const event1 = new ShowToastEvent({
                    title: 'Det oppstod en feil',
                    message: 'Samtalen kunne ikke bli avsluttet',
                    variant: 'error'
                });
                this.dispatchEvent(event1);
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
        let element = this.template.querySelector('.slds-box');
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

    get quickTextCmp() {
        return this.template.querySelector('c-crm-messaging-quick-text-v-2');
    }

    get text() {
        return this.quickTextCmp ? this.quickTextCmp.conversationNote : '';
    }

    get modalClass() {
        return 'slds-modal slds-show uiPanel north' + (this.hideModal === true ? ' geir' : ' slds-fade-in-open');
    }

    get backdropClass() {
        return this.hideModal === true ? 'slds-hide' : 'backdrop';
    }

    get langBtnVariant() {
        return this.englishTextTemplate === false ? 'neutral' : 'brand';
    }

    get langAria() {
        return this.langBtnAriaToggle === false ? 'Språk knapp, Norsk' : 'Språk knapp, Engelsk';
    }

    get hasEnglishTemplate() {
        return this.englishTextTemplate !== undefined;
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

    //##################################//
    //##########   STO Button Container   ###########//
    //##################################//
    @api caseId;
    @api isThread = false;

    labels = {
        COMPLETE_LABEL,
        CREATE_NAV_TASK_LABEL,
        JOURNAL_LABEL,
        END_DIALOGUE_LABEL,
        SEND_TO_REDACTION_LABEL,
        END_DIALOGUE_ALERT_TEXT,
        DIALOGUE_STARTED_TEXT,
        CANCEL_LABEL
    };
    showFlow = false;
    showComplete = false;
    showRedact = false;
    showJournal = false;
    showCreateNavTask = false;
    label;

    get inputVariables() {
        if (this.isThread) {
            return [
                {
                    name: 'recordId',
                    type: 'String',
                    value: this.threadId
                }
            ];
        }
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.caseId
            }
        ];
    }

    get journalFlowName() {
        return this.isThread ? 'STO_Create_Thread_Journal_Entry' : 'CRM_Case_Journal_STO_Thread';
    }

    get createNavTaskFlowName() {
        return this.isThread ? 'NKS_Thread_Send_NAV_Task' : 'NKS_Case_Send_NAV_Task';
    }

    get redactFlowName() {
        return this.isThread ? 'Thread_Set_To_Redaction' : 'Case_STO_Sladd';
    }

    get completeFlowName() {
        return this.isThread ? 'STO_Action_Complete' : 'Case_STO_Complete';
    }

    toggleFlow(event) {
        this.showFlow = !this.showFlow;
        this.label = event.target.label;
        this.handleShowFlows();
        publishToAmplitude('STO', { type: this.label + ' pressed' });
    }

    handleShowFlows() {
        this.showComplete = this.label === this.labels.COMPLETE_LABEL;
        this.showRedact = this.label === this.labels.SEND_TO_REDACTION_LABEL;
        this.showCreateNavTask = this.label === this.labels.CREATE_NAV_TASK_LABEL;
        this.showJournal = this.label === this.labels.JOURNAL_LABEL;
    }

    handleStatusChange(event) {
        let flowStatus = event.detail.status;
        if (flowStatus === 'FINISHED' || flowStatus === 'FINISHED_SCREEN') {
            this.showFlow = false;
        }
    }
}
