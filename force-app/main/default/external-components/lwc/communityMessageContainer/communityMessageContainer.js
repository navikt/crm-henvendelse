import { LightningElement, api } from 'lwc';

export default class CommunityMessageContainer extends LightningElement {
    @api messageGroups;

    get decoratedGroups() {
        return this.messageGroups.map((group) => {
            const decoratedMessages = group.messages.map((msgWrap, index) => ({
                ...msgWrap,
                isExternal: msgWrap.message.CRM_External_Message__c,
                bubbleStyle: msgWrap.showHeader && index > 0 ? 'margin-top: var(--a-spacing-5);' : ''
            }));

            const nonEventMessages = decoratedMessages.filter((m) => !m.isEvent);

            return {
                ...group,
                messages: decoratedMessages,
                nonEventMessages: nonEventMessages
            };
        });
    }
}
