public inherited sharing class CRM_MessageSelector extends CRM_ApiSelector {
    public CRM_MessageSelector() {
        super(false);
    }

    /**
     * @description: Returns the default conditions for message to be returnned in the API
     * @author Stian Ruud Schikora | 01-31-2022
     * @return String
     **/
    public String getApiConditions() {
        return 'CRM_Type__c IN (\'Message\', \'Info\', \'Event\')';
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Message__c.CRM_Type__c,
            Message__c.CRM_HenvendelseId__c,
            Message__c.CRM_Read__c,
            Message__c.CRM_Thread__c,
            Message__c.CRM_Message_Text__c,
            Message__c.Id,
            Message__c.CRM_Sent_Date__c,
            Message__c.CRM_Read_Datetime__c,
            Message__c.CRM_External_Message__c,
            Message__c.CRM_From_Ident_Formula__c,
            Message__c.CRM_From_NAV_Unit__c,
            Message__c.CRM_API_Reference__c,
            Message__c.CRM_Sensitive_Information__c,
            Message__c.CRM_Event_Type__c
        };
    }

    public Schema.SObjectType getSObjectType() {
        return Message__c.sObjectType;
    }

    public List<Message__c> selectById(Set<Id> idSet) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('Id in :idSet AND ' + getApiConditions());
        return (List<Message__c>) Database.query(query.toSOQL());
    }

    public List<Message__c> selectByApiReference(List<String> refSet) {
        fflib_QueryFactory query = newQueryFactory();
        query.setCondition('CRM_API_Reference__c in :refSet AND ' + getApiConditions());
        return (List<Message__c>) Database.query(query.toSOQL());
    }
}
