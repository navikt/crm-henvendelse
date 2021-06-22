import { LightningElement, api, track } from 'lwc';
import Id from '@salesforce/user/Id';

export default class messagingMessageContainer extends LightningElement {
    showpopover = false;
    isreply = false;
    isevent = false;
    showReplybutton;
    @api message;
    @track isoutbound;
    @track userid;
    connectedCallback() {
        this.userid = Id;
        //Indicate if the message is inbound or outbound, i.e left or right hand of the screen. tea

        if (this.userid == this.message.CRM_From__c) {
            this.isoutbound = true;
        } else {
            this.isoutbound = false;
        }

        if (this.message.Type__c == 'Event') {
            this.isevent = true;
        }
        if (typeof this.message.Previous_Message__c != 'undefined') {
            this.showReplybutton = false;
        }
        //if there is a reply, hide it
    }
    showdata() {
        this.showpopover = true;
    }
    hidedata() {
        this.showpopover = false;
    }
    replythreadPressed() {
        const selectedEvent = new CustomEvent('answerpressed', { detail: this.message.Id });
        this.dispatchEvent(selectedEvent);
    }
}
