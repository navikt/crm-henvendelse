public without sharing class CRM_ConvNotePdfController {
    private static final Integer MAX_LINE_LENGTH = 80;
    private transient string convNoteId;
    public String messageText { get; private set; }
    private static LongWordSplitter splitter = new LongWordSplitter(MAX_LINE_LENGTH);

    public CRM_ConvNotePdfController(ApexPages.StandardController stdController) {
        convNoteId = stdController.getId();
        Conversation_Note__c convNote = [
            SELECT CRM_Conversation_Note__c
            FROM Conversation_Note__c
            WHERE Id = :convNoteId
            LIMIT 1
        ];
        messageText = splitter.splitWordsInMessage(convNote.CRM_Conversation_Note__c);
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
