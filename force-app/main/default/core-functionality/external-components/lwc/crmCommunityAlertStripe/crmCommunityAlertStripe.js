import { LightningElement, api } from 'lwc';
import ALERTLOGOS from '@salesforce/resourceUrl/alertlogos';

export default class Alertstripe extends LightningElement {
    @api type; //info, suksess, advarsel, feil,
    @api alerttext; //text to be displayed
    logopath;

    getalerttype() {
        if (this.type === 'info') {
            this.logopath = ALERTLOGOS + '/InformationFilled.svg';
            return 'alertstripe alertstripe--info';
        } else if (this.type === 'suksess') {
            this.logopath = ALERTLOGOS + '/SuccessFilled.svg';
            return 'alertstripe alertstripe--suksess';
        } else if (this.type === 'advarsel') {
            this.logopath = ALERTLOGOS + '/WarningFilled.svg';
            return 'alertstripe alertstripe--advarsel';
        } else if (this.type === 'feil') {
            this.logopath = ALERTLOGOS + '/ErrorFilled.svg';
            return 'alertstripe alertstripe--feil';
        }
    }

    renderedCallback() {
        this.template.querySelector('[data-id="divblock"]').className = this.getalerttype();
    }
}
