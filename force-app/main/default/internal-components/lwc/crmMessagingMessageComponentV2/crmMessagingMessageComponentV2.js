import { LightningElement, api, track, wire } from 'lwc';
import getThreads from '@salesforce/apex/CRM_MessageHelper.getThreadsCollection';
import createThread from '@salesforce/apex/CRM_MessageHelper.createThread';
import { refreshApex } from '@salesforce/apex';
import ERROR_LABEL from '@salesforce/label/c.NKS_Error';
import ERROR_MESSAGE from '@salesforce/label/c.NKS_Error_Message';

export default class CrmMessagingMessageComponent extends LightningElement {
    @api recordId;
    @api singleThread;
    @api showClose;
    @api showQuick;
    @api englishTextTemplate;
    @api textTemplate;
    @api caseId;
    @api isThread;

    @track slotsNeedCheckedOrRendered = { messages: true };

    showmodal = false;
    showtaskmodal = false;
    activeSectionMessage = '';
    threads;
    singlethread;
    _threadsforRefresh;
    setCardTitle;
    hasError = false;
    labels = { ERROR_LABEL, ERROR_MESSAGE };

    renderedCallback() {
        this.handleSlotChanges();
    }

    @wire(getThreads, { recordId: '$recordId', singleThread: '$singleThread' })
    wiredThreads(result) {
        this._threadsforRefresh = result;

        if (result.error) {
            this.error = result.error;
            this.hasError = true;
            console.log(JSON.stringify(result.error, null, 2));
        } else if (result.data) {
            this.threads = result.data;
        }
    }
    handlenewpressed() {
        createThread({ recordId: this.recordId })
            .then((result) => {
                return refreshApex(this._threadsforRefresh);
            })
            .catch((error) => {});
    }

    get showSpinner() {
        return !this.threads && !this.hasError;
    }

    get shownewbutton() {
        return this.threads && this.threads.length === 0 && this.recordId;
    }

    get cardTitle() {
        return this.setCardTitle ?? (this.singleThread === true ? 'Samtale' : 'Samtaler');
    }

    @api
    set cardTitle(cardTitle) {
        this.setCardTitle = cardTitle;
    }

    handleEnglishEvent(event) {
        const englishEvent = new CustomEvent('englisheventtwo', {
            detail: event.detail
        });
        this.dispatchEvent(englishEvent);
    }

    @api
    checkSlotChange(slotName) {
        console.log('Api call');
        console.log(slotName);
        console.log(this.slotsNeedCheckedOrRendered[slotName]);
        this.slotsNeedCheckedOrRendered[slotName] = true;
    }

    handleSlotChanges() {
        const slots = this.template.querySelectorAll('slot');
        if (!slots) return;
        const changeableSlots = Object.keys(this.slotsNeedCheckedOrRendered).filter(
            (slotValue) => this.slotsNeedCheckedOrRendered[slotValue]
        );
        for (const slotName of changeableSlots) {
            let slot;
            for (const a of slots) {
                if (a.name === slotName) {
                    slot = a;
                    break;
                }
            }
            if (!slot) continue;
            const hasContent = slot.assignedElements().length !== 0;
            this.slotsNeedCheckedOrRendered[slot.name] = hasContent;
        }
    }
}
