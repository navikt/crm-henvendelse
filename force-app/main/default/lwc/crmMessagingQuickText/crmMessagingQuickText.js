import { LightningElement, track, api, wire } from 'lwc';
import searchRecords from '@salesforce/apex/CRM_HenvendelseQuicktextController.searchRecords';
import getQuicktexts from '@salesforce/apex/CRM_HenvendelseQuicktextController.getQuicktexts';
//LABEL IMPORTS
import BLANK_ERROR from '@salesforce/label/c.CRMHenveldelse_Blank';
export default class nksQuickText extends LightningElement {
    labels = {
        BLANK_ERROR
    };

    _conversationNote;
    @api comments;
    @track data = [];
    loadingData = false;
    @api required = false;
    quicktexts;
    qmap;
    get inputFormats() {
        return [''];
    }
    initialRender = true;

    //Screen reader does not detect component as as input field until after the first focus
    renderedCallback() {
        if (this.initialRender === true) {
            let inputField = this.template.querySelector('.conversationNoteTextArea');
            inputField.focus();
            inputField.blur();
            this.initialRender = false;
        }
    }

    @wire(getQuicktexts, {})
    wiredQuicktexts(value) {
        if (value.data) {
            this.quicktexts = value.data;
            this.qmap = new Map(value.data.map((key) => [key.nksAbbreviationKey__c.toUpperCase(), key.Message]));
        }
    }

    @api get conversationNote() {
        return this._conversationNote;
    }

    set conversationNote(value) {
        this._conversationNote = value;
    }

    @api get conversationNoteRich() {
        return this._conversationNote;
    }

    set conversationNoteRich(value) {
        this._conversationNote = value;
    }

    handlePaste(evt) {
        const editor = this.template.querySelector('.conversationNoteTextArea');
        editor.setRangeText(
            this.toPlainText((evt.clipboardData || window.clipboardData).getData('text')),
            editor.selectionStart,
            editor.selectionEnd,
            'end'
        );
        evt.preventDefault();
    }

    modalOnEscape(evt) {
        if (evt.key === 'Escape') {
            this.hideModal(evt);
            evt.preventDefault();
            evt.stopImmediatePropagation();
        }
    }

    handleKeyUp(evt) {
        const queryTerm = evt.target.value;
        if (evt.key.length > 1 && evt.key !== 'Enter' && evt.key !== 'Backspace') {
            return;
        }

        if (evt.key === 'Enter' || (queryTerm.length > 2 && this.loadingData == false)) {
            evt.stopPropagation();
            this.loadingData = true;
            searchRecords({
                search: queryTerm
            })
                .then((result) => {
                    this.numberOfRows = result.length;
                    this.data = result;
                })
                .catch((error) => {
                    console.log(error);
                })
                .finally(() => {
                    this.loadingData = false;
                });
        }
    }

    @api showModal(event) {
        this.template.querySelector('[data-id="modal"]').className = 'modalShow';
        this.template.querySelector('lightning-input').focus();
    }

    hideModal(event) {
        this.template.querySelector('[data-id="modal"]').className = 'modalHide';
    }
    @api isopen() {
        if (this.template.querySelector('[data-id="modal"]').className == 'modalShow') {
            return true;
        } else {
            return false;
        }
    }

    insertText(event) {
        const editor = this.template.querySelector('.conversationNoteTextArea');
        editor.focus();
        editor.setRangeText(
            this.toPlainText(event.currentTarget.dataset.message),
            editor.selectionStart,
            editor.selectionEnd,
            'select'
        );

        this.hideModal(undefined);
        this.conversationNote = editor.value;
        const attributeChangeEvent = new CustomEvent('commentschange', {
            detail: this.conversationNote
        });
        this.dispatchEvent(attributeChangeEvent);
    }

    handleChange(event) {
        this[event.target.name] = event.target.value;
        this.conversationNote = event.target.value;
        const attributeChangeEvent = new CustomEvent('commentschange', {
            detail: this.conversationNote
        });
        this.dispatchEvent(attributeChangeEvent);
    }

    insertquicktext(event) {
        if (event.keyCode === 32) {
            const editor = this.template.querySelector('.conversationNoteTextArea');
            const carretPositionEnd = editor.selectionEnd;
            const lastItem = editor.value
                .substring(0, carretPositionEnd)
                .replace(/(\r\n|\n|\r)/g, ' ')
                .trim()
                .split(' ')
                .pop();
            const abbreviation = lastItem.toUpperCase();
            const quickText = this.qmap.get(abbreviation);

            if (this.qmap.has(abbreviation)) {
                const startindex = carretPositionEnd - lastItem.length - 1;

                if (lastItem.charAt(0) === lastItem.charAt(0).toLowerCase()) {
                    const lowerCaseQuickText = quickText.toLowerCase();
                    editor.setRangeText(lowerCaseQuickText + ' ', startindex, carretPositionEnd, 'end');
                } else {
                    const upperCaseQuickText = quickText.charAt(0).toUpperCase() + quickText.slice(1);
                    editor.setRangeText(upperCaseQuickText + ' ', startindex, carretPositionEnd, 'end');
                }
            }
        }
    }

    toPlainText(value) {
        let plainText = value ? value : '';
        plainText = plainText.replace(/<\/[^\s>]+>/g, '\n'); //Replaces all ending tags with newlines.
        plainText = plainText.replace(/<[^>]+>/g, ''); //Remove remaining html tags
        plainText = plainText.replace(/&nbsp;/g, ' '); //Removes &nbsp; from the html that can arise from copy-paste
        return plainText;
    }

    setFocusOnTextArea() {
        let inputField = this.template.querySelector('.conversationNoteTextArea');
        inputField.focus();
    }

    @api
    validate() {
        if (this.required === true) {
            return this.conversationNote && this.conversationNote.length > 0
                ? { isValid: true }
                : { isValid: false, errorMessage: this.labels.BLANK_ERROR }; //CUSTOM LABEL HERE
        } else {
            return { isValid: true };
        }
    }
    setheader() {}
    @api clear(event) {
        let inputField = this.template.querySelector('.conversationNoteTextArea');
        inputField.value = '';
    }
    handlePaste() {
        handleChange();
    }
}
