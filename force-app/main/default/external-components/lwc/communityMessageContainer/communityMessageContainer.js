import { LightningElement, api } from 'lwc';

export default class CommunityMessageContainer extends LightningElement {
    @api messageGroups;

    get decoratedBlocks() {
        const blocks = this.messageGroups || [];
        return blocks.map((block, idx) => {
            const nextBlock = blocks[idx + 1];
            if (block.type === 'group') {
                const decoratedMessages = (block.groupMessages || []).map((msgWrap, msgIdx) => ({
                    ...msgWrap,
                    bubbleStyle: msgWrap.showHeader && msgIdx > 0 ? 'margin-top: var(--a-spacing-5);' : ''
                }));
                return {
                    ...block,
                    isGroup: true,
                    isEvent: false,
                    groupMessages: decoratedMessages,
                    blockClass: 'block-gap'
                };
            }
            let blockClass = '';
            if (!nextBlock || nextBlock.type !== 'event') {
                blockClass = 'block-gap';
            } else {
                blockClass = 'tight-gap';
            }
            return {
                ...block,
                isGroup: false,
                isEvent: true,
                blockClass
            };
        });
    }
}
