import { LightningElement, api } from 'lwc';

export default class CommunityMessageContainer extends LightningElement {
    @api messageGroups;

    get decoratedGroups() {
        return this.messageGroups.map((group) => ({
            ...group,
            messages: group.messages.map((msgWrap, index) => ({
                ...msgWrap,
                bubbleStyle: msgWrap.showHeader && index > 0 ? 'margin-top: var(--a-spacing-5);' : ''
            }))
        }));
    }
}
