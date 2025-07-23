import { LightningElement, api } from 'lwc';

export default class CommunityTextarea extends LightningElement {
    @api maxLength;
    @api label;

    errorMessage = 'Tekstboksen kan ikke være tom';
    message;
    errorState = false;

    handleChange(event) {
        this.message = event.target.value;
        this.publishMessage();
    }

    handleMessage(event) {
        this.errorState = false;
        this.message = event.target.value;
        this.processMessageStyling();
    }

    checkError() {
        if (!this.message || this.message.length === 0) {
            this.errorState = true;
            this.errorMessage = 'Tekstboksen kan ikke være tom.';
        } else if (this.limitCharacters && this.message.length > this.maxLength) {
            this.errorState = true;
            this.errorMessage = 'Det er for mange tegn i tekstboksen.';
        } else {
            this.errorState = false;
        }
    }

    processMessageStyling() {
        // eslint-disable-next-line @locker/locker/distorted-node-text-content-setter
        this.mirror.textContent = this.message + '\n s';
        this.textBox.style.height = this.mirror.offsetHeight + 'px';
        if (this.limitCharacters) {
            let counter = this.template.querySelector('.remainingCounter');
            counter.ariaLive = this.remainingCharacters <= 20 ? 'polite' : 'off';
        }
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
        this.textBox.value = this.message;
        this.publishMessage();
        this.processMessageStyling();
    }

    @api
    focus() {
        this.textBox.focus();
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

    get labelText() {
        return 'Tekstområde' + (this.limitCharacters ? ' med plass til ' + this.maxLength + ' tegn' : '');
    }

    get limitCharacters() {
        return this.maxLength !== 0 && this.maxLength != null;
    }

    get textBox() {
        return this.template.querySelector('.textBox');
    }

    get mirror() {
        return this.template.querySelector('.mirror');
    }

    get wrapperClass() {
        return (
            'navds-form-field navds-form-field--medium navds-textarea--resize-both ' +
            (this.errorState ? ' navds-textarea--error' : '')
        );
    }
}
