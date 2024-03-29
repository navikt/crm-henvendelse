/**
 * @description       :
 * @author            : mamikals
 * @group             :
 * @last modified on  : 19-06-2023
 * @last modified by  : mamikals
 **/
public with sharing class ArchiveBatch extends CRM_ApplicationDomain implements Database.Batchable<SObject>, Database.AllowsCallouts, Schedulable {
    private String domain;
    private LoggerUtility logger;

    public ArchiveBatch(String domain) {
        this.domain = domain != null ? domain.toUpperCase() : '';
        this.logger = new LoggerUtility(domain);
    }

    /*Schedulable
        Scheduled for every day at 23:00 by running the following in dev console:
        String cronExp = '0 0 23 * * ?';
        System.schedule('ArchiveBatch', cronExp, new ArchiveBatch('domain'));
        Make sure to set correct domain param
    */
    public void execute(System.SchedulableContext schContext) {
        ArchiveBatch batch = new ArchiveBatch(domain);
        Database.executebatch(batch, 10);
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Ready_for_Deletion__c, Reference_Object__c, Reference_Id__c, Actor_Id__c, Confidential__c, Domain__c, Fnr__c, Orgnr__c, Status__c, Theme__c, Archive_Data__c FROM Archive_Entry__c WHERE Status__c = \'Failed\' AND Domain__c = :domain';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Archive_Entry__c> scope) {
        List<ArchiveRequestWrapper> archiveRecordsToPost = new List<ArchiveRequestWrapper>();
        for (Archive_Entry__c archiveEntry : scope) {
            ArchiveRequestWrapper reqWrapper = new ArchiveRequestWrapper(
                archiveEntry.Domain__c,
                archiveEntry.Actor_Id__c,
                archiveEntry.Fnr__c,
                archiveEntry.Orgnr__c,
                archiveEntry.Theme__c,
                archiveEntry.Confidential__c,
                archiveEntry.Reference_Id__c,
                archiveEntry.Archive_Data__c,
                archiveEntry.Reference_Object__c
            );
            archiveRecordsToPost.add(reqWrapper);
        }

        List<ArchiveService.ArchiveResponseWrapper> response;
        try {
            response = new ArchiveService().postToArchive(archiveRecordsToPost);
            if (response == null) {
                throw new ArchiveException('Response was null.');
            }
        } catch (Exception e) {
            logger.error(e.getMessage() + '. ' + e.getStackTraceString(), null, domainNameMap.get(domain));
        } finally {
            logger.publish();
        }

        // Update Archive Entry status based on response
        if (response != null) {
            for (Archive_Entry__c archiveEntry : scope) {
                archiveEntry.Status__c = (response[0].id != null &&
                    String.valueOf(response[0].id) != '')
                    ? 'Completed'
                    : 'Failed';
                archiveEntry.Archived_Date__c = (archiveEntry.Status__c == 'Completed') ? System.now() : null;
                archiveEntry.Ready_for_Deletion__c = archiveEntry.Status__c == 'Completed';
            }

            // Update Archive Entry records
            update scope;
        }
    }

    public void finish(Database.BatchableContext BC) {
    }

    public class ArchiveException extends Exception {
    }
}
