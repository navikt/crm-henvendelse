import { LightningElement, api, track, wire } from 'lwc';
import getThreads from '@salesforce/apex/CRM_MessageHelper.getThreadsCollection';
import createThread from '@salesforce/apex/CRM_MessageHelper.createThread';
import { refreshApex } from '@salesforce/apex';
import ERROR_LABEL from '@salesforce/label/c.Henvendelse_Error';
import ERROR_MESSAGE from '@salesforce/label/c.Henvendelse_Error_Message';

export default class CrmMessagingMessageComponent extends LightningElement {
    @api recordId;
    @api singleThread;
    @api showClose;
    @api showQuick;
    @api englishTextTemplate;
    @api textTemplate; //Support for conditional text template
    @api newDesign = false;
    @api submitButtonLabel = 'Send';
    @api isThread;
    @api showLanguageChangeModal = false;
    @api hideChangeLngBtn = false;

    @track slotsNeedCheckedOrRendered = { messages: true }; // To check the slot content the slot has to be rendered initially

    showmodal = false;
    showtaskmodal = false;
    activeSectionMessage = '';
    threads;
    singlethread;
    _threadsforRefresh;
    actualCardTitle;
    hasError = false;
    labels = {
        ERROR_LABEL,
        ERROR_MESSAGE
    };
    _iconName = 'standard:messaging_user';

    renderedCallback() {
        this.handleSlotChanges();
    }

    @wire(getThreads, { recordId: '$recordId', singleThread: '$singleThread' }) //Calls apex and extracts messages related to this record
    wiredThreads(result) {
        this._threadsforRefresh = result;

        if (result.error) {
            this.error = result.error;
            this.hasError = true;
        } else if (result.data) {
            this.threads = result.data;
        }
    }

    get showSpinner() {
        return !this.threads && !this.hasError;
    }

    get shownewbutton() {
        return this.threads && this.threads.length === 0 && this.recordId;
    }

    get cardTitle() {
        return this.actualCardTitle ?? (this.singleThread ? 'Samtale' : 'Samtaler');
    }

    @api
    set cardTitle(cardTitle) {
        this.actualCardTitle = cardTitle;
    }

    get cardClass() {
        return this.newDesign
            ? 'slds-card__header slds-grid paddingAndCustomColor slds-p-left_none slds-p-bottom_none'
            : 'slds-card__header slds-grid paddingAndCustomColor';
    }

    get iconName() {
        return this._iconName;
    }

    @api
    set iconName(newIconName) {
        this._iconName = newIconName;
    }

    handlenewpressed() {
        createThread({ recordId: this.recordId })
            .then(() => {
                return refreshApex(this._threadsforRefresh);
            })
            .catch((error) => {
                console.error(error);
            });
    }

    handleEnglishEvent(event) {
        const englishEvent = new CustomEvent('englisheventtwo', {
            detail: event.detail
        });
        this.dispatchEvent(englishEvent);
    }

    // Make the component check slot content dynamically.
    // If the slot is not rendered in the DOM we have no way of checking it's content
    @api
    checkSlotChange(slotName) {
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

    handleSumbit() {
        this.dispatchEvent(new CustomEvent('submitfromchild'));
    }

    forwardEvent(event) {
        this.dispatchEvent(new CustomEvent(event.type));
    }
}
