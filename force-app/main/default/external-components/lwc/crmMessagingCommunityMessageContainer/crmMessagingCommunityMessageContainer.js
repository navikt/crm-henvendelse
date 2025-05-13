import { LightningElement, api } from 'lwc';
import uId from '@salesforce/user/Id';

export default class CommunityMessageContainer extends LightningElement {
    @api message;
    @api userContactId;

    userId = uId;

    get isoutbound() {
        return this.message.CRM_External_Message__c;
    }

    get isevent() {
        return this.message.CRM_Type__c == 'Event';
    }
}
