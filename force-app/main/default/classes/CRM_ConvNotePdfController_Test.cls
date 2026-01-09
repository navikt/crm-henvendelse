@isTest
public class CRM_ConvNotePdfController_Test {
    @TestSetup
    static void makeData() {
        CRM_HENV_TestDataFactory.createRecord(new Conversation_Note__c(CRM_Conversation_Note__c = 'Dummy text'));
    }

    @isTest
    static void testConvNotePdf() {
        PageReference pageRef = Page.CRM_Conversation_Note_PDF;
        Test.setCurrentPage(pageRef);
        Id convNoteId = [SELECT Id FROM Conversation_Note__c LIMIT 1].Id;

        ApexPages.currentPage().getParameters().put('id', convNoteId);

        CRM_ConvNotePdfController pdfController = new CRM_ConvNotePdfController();
        System.assert(String.isNotBlank(pdfController.messageText));
        System.assertNotEquals(null, pdfController.convNote);
    }

    @isTest
    static void splitWordTest() {
        CRM_ConvNotePdfController.LongWordSplitter splitter = new CRM_ConvNotePdfController.LongWordSplitter(10);
        System.assertEquals(null, splitter.splitWord(null), 'if argument is null - returns null');
        System.assertEquals('', splitter.splitWord(''), 'if argument is empty string - returns empty string');
        System.assertEquals(
            'shrtstr',
            splitter.splitWord('shrtstr'),
            'if argument is shorter than limit - returns argument'
        );
        System.assertEquals(
            'a_longer_s tring',
            splitter.splitWord('a_longer_string'),
            'if argument is longer than limit - returns splittet string'
        );
        System.assertEquals(
            'a_string_w ich_should _be_splitt et_to_five _pieces',
            splitter.splitWord('a_string_wich_should_be_splittet_to_five_pieces'),
            'if argument is longer than limit - returns splittet string'
        );
    }
    @isTest
    public static void splitLinkTest() {
        CRM_ConvNotePdfController.LongWordSplitter splitter = new CRM_ConvNotePdfController.LongWordSplitter(20);
        System.assertEquals(null, splitter.splitLink(null), 'if argument is null - returns null');
        System.assertEquals('', splitter.splitLink(''), 'if argument is empty string - returns empty string');
        System.assertEquals(
            'http://short_link',
            splitter.splitLink('http://short_link'),
            'if argument is shorter than limit - returns argument'
        );
        System.assertEquals(
            '<a style="color:black; text-decoration: none;" href="http://this_link_is_longer_than_given_length"> http://this_link_is_ longer_than_given_le ngth </a>',
            splitter.splitLink('http://this_link_is_longer_than_given_length'),
            'if argument is longer than limit - returns html formatted link'
        );
    }
    @isTest
    static void splitWordsTest() {
        CRM_ConvNotePdfController.LongWordSplitter splitter = new CRM_ConvNotePdfController.LongWordSplitter(10);
        System.assertEquals(null, splitter.splitWords(null), 'if argument is null - returns argument');
        System.assertEquals(
            0,
            splitter.splitWords(new List<String>()).size(),
            'if argument is empty list - returns empty list'
        );
        List<String> fourWordsList = new List<String>();
        fourWordsList.add('hello');
        fourWordsList.add('world!');
        fourWordsList.add('alonglongword');
        fourWordsList.add('shortword');
        List<String> resultList = splitter.splitWords(fourWordsList);
        System.assertEquals('hello', resultList[0]);
        System.assertEquals('world!', resultList[1]);
        System.assertEquals('alonglongw ord', resultList[2]);
        System.assertEquals('shortword', resultList[3]);
    }
    @isTest
    static void splitWordsInLineTest() {
        CRM_ConvNotePdfController.LongWordSplitter splitter = new CRM_ConvNotePdfController.LongWordSplitter(10);
        System.assertEquals(null, splitter.splitWordsInLine(null), 'if argument is null - returns null');
        System.assertEquals('', splitter.splitWordsInLine(''), 'if argument is empty string - returns empty string');
        System.assertEquals(
            'hello world! alonglongw ord shortword',
            splitter.splitWordsInLine('hello world! alonglongword shortword')
        );
    }
    @isTest
    static void splitWordsInLinesTest() {
        CRM_ConvNotePdfController.LongWordSplitter splitter = new CRM_ConvNotePdfController.LongWordSplitter(10);
        System.assertEquals(null, splitter.splitWordsInLines(null), 'if argument is null - returns argument');
        System.assertEquals(
            0,
            splitter.splitWordsInLines(new List<String>()).size(),
            'if argument is empty list - returns empty list'
        );
        List<String> fourLinesList = new List<String>();
        fourLinesList.add('hello world!');
        fourLinesList.add('line with longlonglonglong words');
        fourLinesList.add('line with veryveryveryverylonglonglonglong words');
        fourLinesList.add('short words in this line');
        List<String> resultList = splitter.splitWordsInLines(fourLinesList);
        System.assertEquals('hello world!', resultList[0]);
        System.assertEquals('line with longlonglo nglong words', resultList[1]);
        System.assertEquals('line with veryveryve ryverylong longlonglo ng words', resultList[2]);
        System.assertEquals('short words in this line', resultList[3]);
    }
    @isTest
    static void splitWordsInMessageTest() {
        CRM_ConvNotePdfController.LongWordSplitter splitter = new CRM_ConvNotePdfController.LongWordSplitter(10);
        System.assertEquals(null, splitter.splitWordsInMessage(null), 'if argument is null - returns null');
        System.assertEquals('', splitter.splitWordsInMessage(''), 'if argument is empty string - returns empty string');
        String multilineString =
            'hello world!\n' +
            'line with longlonglonglong words\n' +
            'line with veryveryveryverylonglonglonglong words\n' +
            'short words in this line\n' +
            'a short link here: http://www and along one https://www.nav.com';
        String expectedString =
            'hello world!\n' +
            'line with longlonglo nglong words\n' +
            'line with veryveryve ryverylong longlonglo ng words\n' +
            'short words in this line\n' +
            'a short link here: http://www and along one <a style="color:black; text-decoration: none;" href="https://www.nav.com"> https://ww w.nav.com </a>';
        System.assertEquals(expectedString, splitter.splitWordsInMessage(multilineString));
    }
}
