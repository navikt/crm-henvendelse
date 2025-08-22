/**
 * Helper class for the Messaging solution for Experience site
 * @Author Vegard Sørheller
 * @Date 30.05.2024
 */
public with sharing class CRM_MessageHelperExperience {
    @AuraEnabled
    public static string getUserContactId() {
        return [SELECT Id, ContactId FROM User WHERE Id = :UserInfo.getUserId()]?.ContactId;
    }

    @AuraEnabled(cacheable=true)
    public static List<Message__c> getMessagesFromThread(Id threadId) {
        try {
            List<Message__c> msgList = new List<Message__c>();
            for (Message__c m : [
                SELECT
                    Id,
                    CRM_Message_Text__c,
                    CRM_Type__c,
                    CRM_Event_Type__c,
                    CRM_Sent_date__c,
                    CRM_From_User__c,
                    CRM_From_Contact__c,
                    CRM_From_First_Name__c,
                    CRM_External_Message__c,
                    CRM_From_Label__c,
                    CRM_Sensitive_Information__c
                FROM Message__c
                WHERE CRM_Thread__c = :threadId
                ORDER BY CRM_Sent_date__c ASC
            ]) {
                if (m.CRM_Message_Text__c != null) {
                    msgList.add(m);
                }
            }
            return msgList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Method for marking unread messages - called onload fromt the end user perspective. Does only represent customer read.
     * @Lars Petter Johnsen
     * @Date 31052021
     */
    @AuraEnabled
    public static void markAsRead(Id threadId) {
        List<Message__c> msgList = [
            SELECT Id, CRM_Read__c, CRM_Read_Datetime__c
            FROM Message__c
            WHERE CRM_Read__c = FALSE AND CRM_Thread__c = :threadId
        ];
        for (Message__c msg : msgList) {
            msg.CRM_Read__c = true;
            msg.CRM_Read_Datetime__c = DateTime.now();
        }
        try {
            update msgList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Creates a message
     * Used in the community components
     * @Author Lars Petter Johnsen
     */
    @AuraEnabled
    public static Boolean createMessage(Id threadId, String messageText, Id fromContactId) {
        Message__c m = new Message__c();
        m.CRM_Message_Text__c = messageText;
        m.CRM_Thread__c = threadId;
        m.CRM_From_Contact__c = fromContactId;
        m.CRM_Read__c = true;
        m.CRM_Read_Datetime__c = DateTime.now();

        Thread__c t = [SELECT Id, CRM_isActive__c FROM Thread__c WHERE Id = :threadId LIMIT 1][0];
        if (!t.CRM_isActive__c) {
            return false;
        }
        try {
            insert m;
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<MessageGroupWrapper> getGroupedMessagesFromThread(Id threadId) {
        try {
            List<Message__c> messages = [
                SELECT
                    Id,
                    CRM_Message_Text__c,
                    CRM_Type__c,
                    CRM_Event_Type__c,
                    CRM_Sent_date__c,
                    CRM_From_User__c,
                    CRM_From_Contact__c,
                    CRM_From_First_Name__c,
                    CRM_External_Message__c,
                    CRM_From_Label__c,
                    CRM_Sensitive_Information__c
                FROM Message__c
                WHERE CRM_Thread__c = :threadId
                ORDER BY CRM_Sent_date__c ASC
            ];

            List<MessageGroupWrapper> groups = new List<MessageGroupWrapper>();
            List<Message> buffer = new List<Message>();
            Boolean currentIsExternal = null;
            DateTime lastHeaderTime = null;

            for (Message__c m : messages) {
                if (m.CRM_Message_Text__c == null)
                    continue;

                Boolean isEvent = m.CRM_Type__c == 'Event';
                Boolean isExternal = m.CRM_External_Message__c;
                DateTime sentDate = m.CRM_Sent_date__c;

                if (isEvent) {
                    addMessageGroupFromBuffer(groups, buffer, currentIsExternal);
                    addEventBlock(groups, m, isExternal);
                    lastHeaderTime = null;
                } else {
                    Boolean showHeader = shouldShowHeader(buffer, lastHeaderTime, sentDate);
                    if (shouldStartNewGroup(buffer, currentIsExternal, isExternal)) {
                        addMessageGroupFromBuffer(groups, buffer, currentIsExternal);
                        currentIsExternal = isExternal;
                        lastHeaderTime = sentDate;
                        showHeader = true;
                    }
                    buffer.add(new Message(m, showHeader));
                    lastHeaderTime = updateLastHeaderTime(lastHeaderTime, sentDate, showHeader);
                }
            }
            addMessageGroupFromBuffer(groups, buffer, currentIsExternal);
            return groups;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    private static Boolean shouldStartNewGroup(List<Message> buffer, Boolean currentIsExternal, Boolean isExternal) {
        return buffer.isEmpty() || currentIsExternal == null || currentIsExternal != isExternal;
    }

    private static Boolean shouldShowHeader(List<Message> buffer, DateTime lastHeaderTime, DateTime sentDate) {
        if (buffer.isEmpty())
            return true;
        if (lastHeaderTime != null && sentDate != null) {
            Long diff = sentDate.getTime() - lastHeaderTime.getTime();
            if (diff >= 3600000)
                return true;
        }
        return false;
    }

    private static DateTime updateLastHeaderTime(DateTime lastHeaderTime, DateTime sentDate, Boolean showHeader) {
        if (showHeader)
            return sentDate;
        return lastHeaderTime;
    }

    private static void addMessageGroupFromBuffer(
        List<MessageGroupWrapper> groups,
        List<Message> buffer,
        Boolean currentIsExternal
    ) {
        if (!buffer.isEmpty()) {
            MessageGroupWrapper groupBlock = new MessageGroupWrapper('group');
            groupBlock.blockId = 'group_' + buffer[0].message.Id;
            groupBlock.groupMessages = buffer.clone();
            groupBlock.groupIsExternal = currentIsExternal;
            groups.add(groupBlock);
            buffer.clear();
        }
    }

    private static void addEventBlock(List<MessageGroupWrapper> groups, Message__c m, Boolean isExternal) {
        MessageGroupWrapper eventBlock = new MessageGroupWrapper('event');
        eventBlock.blockId = 'event_' + m.Id;
        eventBlock.eventMessage = m;
        eventBlock.eventIsExternal = isExternal;
        groups.add(eventBlock);
    }

    public class MessageGroupWrapper {
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String blockId;
        @AuraEnabled
        public List<Message> groupMessages;
        @AuraEnabled
        public Boolean groupIsExternal;
        @AuraEnabled
        public Message__c eventMessage;
        @AuraEnabled
        public Boolean eventIsExternal;

        public MessageGroupWrapper(String type) {
            this.type = type;
        }
    }

    public class Message {
        @AuraEnabled
        public Message__c message { get; set; }
        @AuraEnabled
        public Boolean showHeader { get; set; }
        @AuraEnabled
        public Boolean isEvent { get; set; }

        public Message(Message__c message, Boolean showHeader) {
            this.message = message;
            this.showHeader = showHeader;
            this.isEvent = message.CRM_Type__c == 'Event';
        }
    }
}
