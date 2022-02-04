import { LightningElement, api, track } from 'lwc';

export default class CommunityTextarea extends LightningElement {
    @api maxLength;
    errorMessage = 'Tekstfeltet kan ikke være tomt';
    message;
    errorState = false;

    renderedCallback() {
        if (this.mirror.style.minHeight == '') {
            this.mirror.style.minHeight = this.tekstboks.offsetHeight + 'px';
        }
    }

    handleChange(event) {
        this.message = event.target.value;
        this.publishMessage();
    }

    handleMessage(event) {
        this.errorState = false;
        let text = event.target.value;
        this.message = text;
        this.mirror.textContent = this.message + '\n s';
        this.tekstboks.style.height = this.mirror.offsetHeight + 'px';
        let counter = this.template.querySelector('.remainingCounter');
        counter.ariaLive = this.remainingCharacters <= 20 ? 'polite' : 'off';
    }

    publishMessage() {
        const textChangedEvent = new CustomEvent('textchanged', {
            detail: this.message
        });
        this.dispatchEvent(textChangedEvent);
    }

    @api
    clearText() {
        this.message = '';
        this.tekstboks.value = this.message;
        this.publishMessage();
    }

    get remainingCharacters() {
        return this.message ? this.maxLength - this.message.length : this.maxLength;
    }

    get remainingCharacterText() {
        return (
            'Du har ' +
            Math.abs(this.remainingCharacters) +
            ' tegn ' +
            (this.remainingCharacters < 0 ? 'for mye' : 'igjen')
        );
    }

    get remainingCharacterClass() {
        return (
            'navds-textarea__counter navds-body-short remainingCounter' +
            (this.remainingCharacters < 0 ? ' navds-textarea__counter--error' : '')
        );
    }

    get tekstboks() {
        return this.template.querySelector('.tekstboks');
    }

    get mirror() {
        return this.template.querySelector('.mirror');
    }

    checkError() {
        if (!this.message || this.message.length == 0) {
            this.errorState = true;
            this.errorMessage = 'Tekstfeltet kan ikke være tomt.';
        } else if (this.message.length > this.maxLength) {
            this.errorState = true;
            this.errorMessage = 'Tekstefeltet kan ikke ha for mange tegn.';
        } else {
            this.errorState = false;
        }
    }

    get wrapperClass() {
        return 'navds-form-field navds-form-field--medium' + (this.errorState ? ' navds-textarea--error' : '');
    }

    @api
    focus() {
        this.tekstboks.focus();
    }
}
