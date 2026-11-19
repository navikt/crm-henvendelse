public class CRM_QuickTextMergeConfig {
    public static Map<String, Set<String>> allowedFields() {
        return new Map<String, Set<String>>{ 
            'Account' => new Set<String>{ 'Name' },
            'User' => new Set<String>{ 'NKS_GreetingName__c' }
        };
    }
}
