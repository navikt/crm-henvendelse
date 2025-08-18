import { LightningElement, api } from 'lwc';

export default class CommunityExternalMessageGroup extends LightningElement {
    @api messages;

    get decoratedMessages() {
        return this.messages.map((msgWrap, index) => {
            return {
                ...msgWrap,
                bubbleStyle: msgWrap.showHeader && index > 0 ? 'margin-top: var(--a-spacing-5);' : ''
            };
        });
    }
}
