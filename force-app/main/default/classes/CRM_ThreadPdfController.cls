public without sharing class CRM_ThreadPdfController {
    private static final Integer MAX_LINE_LENGTH = 80;
    private transient string threadId;
    public List<ThreadMessage> threadMessages { get; set; }
    private static LongWordSplitter splitter = new LongWordSplitter(MAX_LINE_LENGTH);

    public CRM_ThreadPdfController(ApexPages.StandardController stdController) {
        threadId = stdController.getId();
        List<Message__c> messages = [
            SELECT
                CRM_Type__c,
                CRM_External_Message__c,
                CRM_From_Contact__r.Name,
                CRM_From_Ident_Formula__c,
                CRM_Sent_date__c,
                CRM_Message_Text__c
            FROM Message__c
            WHERE CRM_Thread__c = :threadId
            ORDER BY CRM_Sent_date__c ASC
        ];
        if (messages != null) {
            threadMessages = new List<ThreadMessage>();
            for (Message__c message : messages) {
                threadMessages.add(new ThreadMessage(message));
            }
        }
    }

    public class ThreadMessage {
        public String type { get; private set; }
        public Boolean externalMessage { get; private set; }
        public String fromName { get; private set; }
        public String fromIdent { get; private set; }
        public Datetime sentDate { get; private set; }
        public String messageText { get; private set; }

        public ThreadMessage(Message__c message) {
            this.type = message.CRM_Type__c;
            this.externalMessage = message.CRM_External_Message__c;
            this.fromName = message.CRM_From_Contact__r.Name;
            this.fromIdent = message.CRM_From_Ident_Formula__c;
            this.sentDate = message.CRM_Sent_date__c;
            this.messageText = splitter.splitWordsInMessage(message.CRM_Message_Text__c);
        }
    }

    public class LongWordSplitter {
        private Integer length;
        public LongWordSplitter(Integer length) {
            this.length = length;
        }
        public String splitWordsInMessage(String message) {
            if (String.isBlank(message)) {
                return message;
            }

            if (message.length() <= length) {
                return escapeSpecialCharacters(message);
            }

            return String.join(splitWordsInLines(escapeSpecialCharacters(message).split('\n|\n\r')), '\n');
        }
        @TestVisible
        private List<String> splitWordsInLines(List<String> lines) {
            if (lines == null) {
                return null;
            }
            List<String> newLines = new List<String>();
            for (String line : lines) {
                newLines.add(splitWordsInLine(line));
            }
            return newLines;
        }
        @TestVisible
        private String splitWordsInLine(String line) {
            if (line == null) {
                return null;
            }
            return String.join(splitWords(line.split('\\s')), ' ');
        }
        @TestVisible
        private List<String> splitWords(List<String> words) {
            if (words == null) {
                return null;
            }
            List<String> newWords = new List<String>();
            for (String word : words) {
                if (word.startsWith('http://') || word.startsWith('https://')) {
                    newWords.add(splitLink(word));
                } else {
                    newWords.add(splitWord(word));
                }
            }
            return newWords;
        }
        public String splitWord(String word) {
            if (word == null) {
                return null;
            }
            List<String> wordParts = new List<String>();
            do {
                wordParts.add(word.left(length));
                word = word.right(word.length() - length);
            } while (word.length() > 0);
            return String.join(wordParts, ' ');
        }

        private String escapeSpecialCharacters(String word) {
            return word.replace('<', '&lt;').replace('>', '&gt;');
        }

        @TestVisible
        private String splitLink(String link) {
            if (link == null) {
                return null;
            }
            if (link.length() <= length) {
                return link;
            }
            return '<a style="color:black; text-decoration: none;" href="' + link + '"> ' + splitWord(link) + ' </a>';
        }
    }
}
