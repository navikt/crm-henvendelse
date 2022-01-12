import { LightningElement, api } from 'lwc';
import logos from '@salesforce/resourceUrl/stoLogos';

export default class CommunityMessageInbound extends LightningElement {
    @api message;
    showNavlogo;
    navlogo = logos + '/navLogoRed.svg';

    connectedCallback() {
        if (this.message.CRM_From_User__c && this.message.CRM_From_User__c !== '') {
            this.showNavlogo = true;
        }
    }

    get sender() {
        return this.message.CRM_External_Message__c === true ? 'NAV' : this.message.CRM_From_Label__c;
    }
}
