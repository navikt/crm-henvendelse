import { LightningElement, api } from 'lwc';

export default class MessagingMessageOutbound extends LightningElement {
    @api message;
    @api userid;

    get isOwner() {
        if (this.userid === this.message.CRM_From_User__c) {
            return true;
        }
        return false;
    }

    get isInfo() {
        return this.message.CRM_Type__c === 'Info';
    }

    get isRedactionMessage() {
        return this.message.CRM_Event_Type__c === 'REDACTED';
    }

    get fromIdent() {
        return this.message.CRM_From_Ident_Formula__c;
    }

    get fromFirstName() {
        return this.message.CRM_From_First_Name__c;
    }

    get redactionInfo() {
        const navIdent = this.fromIdent;
        const navUnit = this.fromFirstName;
        if (navIdent && navUnit) {
            return `${navIdent} (Nav-enhet ${navUnit})`;
        }
        if (navIdent) {
            return navIdent;
        }
        if (navUnit) {
            return `(Nav-enhet ${navUnit})`;
        }
        return '';
    }
}
