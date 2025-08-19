import { LightningElement, api } from 'lwc';

export default class CommunityMessageContainer extends LightningElement {
    @api messageGroups;

    get decoratedBlocks() {
        return (this.messageGroups || []).map((block) => {
            if (block.type === 'group') {
                const decoratedMessages = (block.groupMessages || []).map((msgWrap, idx) => ({
                    ...msgWrap,
                    bubbleStyle: msgWrap.showHeader && idx > 0 ? 'margin-top: var(--a-spacing-5);' : ''
                }));
                return { ...block, groupMessages: decoratedMessages, isGroup: true, isEvent: false };
            }
            return { ...block, isGroup: false, isEvent: true };
        });
    }
}
