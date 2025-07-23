import { LightningElement, api } from 'lwc';

export default class CommunityModal extends LightningElement {
    @api showModal = false;
    @api overrideFirstFocus = false;
    @api hideFooterLine = false;
    @api hidePadding = false;
    @api hidePaddingMobile = false;
    @api showCloseButton = false;

    bufferFocus = false;

    closeModal() {
        this.dispatchEvent(
            new CustomEvent('modalclosed', {
                detail: false
            })
        );
    }

    renderedCallback() {
        if (this.bufferFocus) {
            this.focusModal();
        }
    }

    dispatchFocusFirst() {
        if (this.overrideFirstFocus === false) {
            this.focusLoop();
        } else {
            const focusFirstEvent = new CustomEvent('focusfirst', {
                detail: null
            });
            this.dispatchEvent(focusFirstEvent);
        }
    }

    dispatchFocusLast() {
        const focusLastEvent = new CustomEvent('focuslast', {
            detail: null
        });
        this.dispatchEvent(focusLastEvent);
    }

    @api
    focusModal() {
        const modal = this.template.querySelector('.modal');
        if (modal) {
            this.bufferFocus = false;
            modal.focus();
        } else {
            this.bufferFocus = true;
        }
    }

    @api
    focusLoop() {
        const modalFocusElement = this.template.querySelector('.modalFocus');
        modalFocusElement.focus();
    }

    handleFocus(event) {
        if (event.target.classList.contains('lastFocusable')) {
            this.dispatchFocusFirst();
        }
        if (event.target.classList.contains('firstFocusable')) {
            this.dispatchFocusLast();
        }
    }

    get modalClasses() {
        return (
            'modal modalMobile overrides' +
            (!this.hidePaddingMobile ? '' : ' noHorizontalPadding-mobile') +
            (!this.hidePadding ? ' modal-padding' : ' remove-modal-padding')
        );
    }
}
