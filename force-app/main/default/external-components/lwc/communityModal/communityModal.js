import { LightningElement, api } from 'lwc';

export default class CommunityModal extends LightningElement {
    @api showFooterLine = false;
    @api hidePadding = false;
    @api hidePaddingMobile = false;
    @api showCloseButton = false;

    bufferFocus = false;
    _showModal = false;
    _lastFocusedElement = null;

    @api
    get showModal() {
        return this._showModal;
    }
    set showModal(val) {
        this._showModal = val;
        if (val) {
            Promise.resolve().then(() => {
                this._lastFocusedElement = document.activeElement;
                this.focusFirstElement();
            });
        } else {
            if (this._lastFocusedElement) {
                // eslint-disable-next-line @lwc/lwc/no-async-operation, @locker/locker/distorted-window-set-timeout
                setTimeout(() => {
                    this._lastFocusedElement.focus();
                }, 0);
            }
        }
    }

    renderedCallback() {
        if (this.bufferFocus) {
            this.focusFirstElement();
        }
    }

    focusFirstElement() {
        const focusable = this.modalFocusableElements;
        if (focusable.length) {
            focusable[0].focus();
        } else {
            this.template.querySelector('.modal').focus();
        }
        this.bufferFocus = false;
    }

    focusLastElement() {
        const focusable = this.modalFocusableElements;
        if (focusable.length) {
            focusable[focusable.length - 1].focus();
        }
    }

    handleFocus(event) {
        if (event.target.classList.contains('lastFocusable')) {
            this.focusFirstElement();
        } else if (event.target.classList.contains('firstFocusable')) {
            this.focusLastElement();
        }
    }

    handleKeyDown(event) {
        if (event.key === 'Escape') {
            this.closeModal();
        }
    }

    closeModal() {
        this.dispatchEvent(new CustomEvent('modalclosed', { detail: false }));
        this._showModal = false;
    }

    get modalClass() {
        return (
            'modal modalMobile overrides' +
            (!this.hidePaddingMobile ? '' : ' noHorizontalPadding-mobile') +
            (!this.hidePadding ? ' modal-padding' : ' remove-modal-padding')
        );
    }

    get modalFocusableElements() {
        const modal = this.template.querySelector('.modal');
        if (!modal) return [];
        const selectors = [
            'a[href]:not([tabindex="-1"]):not([disabled])',
            'area[href]:not([tabindex="-1"]):not([disabled])',
            'input:not([type="hidden"]):not([disabled]):not([tabindex="-1"])',
            'select:not([disabled]):not([tabindex="-1"])',
            'textarea:not([disabled]):not([tabindex="-1"])',
            'button:not([disabled]):not([tabindex="-1"])',
            '[tabindex]:not([tabindex="-1"]):not([disabled])'
        ];
        return Array.prototype.slice.call(modal.querySelectorAll(selectors.join(','))).filter(function (el) {
            return el.offsetParent !== null;
        });
    }
}
