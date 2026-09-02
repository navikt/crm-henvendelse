# crm-henvendelse

[![Build](https://github.com/navikt/crm-henvendelse/workflows/%5BPUSH%5D%20Create%20Package/badge.svg)](https://github.com/navikt/crm-henvendelse/actions?query=workflow%3Acreate)
[![GitHub version](https://badgen.net/github/release/navikt/crm-henvendelse/stable)](https://github.com/navikt/crm-henvendelse)
[![MIT License](https://img.shields.io/apm/l/atomic-design-ui.svg?)](https://github.com/navikt/crm-henvendelse/blob/master/LICENSE)

Repository containing data model and functionality connected to dialogues
between NAV and their end-users. This package exposes a custom rest API for
consumers to submit and retrieve inquiry(henvendels) information to and from
Salesforce.

## 1. Core objects

The package consists of three custom objects, `Thread__c` and `Message__c` and
`Conversation_Note__c.` Thread and message are made to model a threaded dialogue
similar to i.e slack, teams etc. `Conversation_Note__c` models a written note
summary from NAV to summarize either a phone- or physical meeting.

### 1.1 Thread model

Below are some of the most essential fields defined on Thread\_\_c

| Name                             | Type             | Required | Description                                                                                                                                                        |
| :------------------------------- | :--------------- | :------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| CRM_Account\_\_c                 | Lookup(Account)  | false    | If the thread is related to an account, standard sharing setup will automatically grant access to the related community user (for person accounts)                 |
| CRM_Thread_Type\_\_c             | Picklist         | false    | Specifies the type of thread and should be used to filter all process automation built upon the core solution                                                      |
| CRM_Related_Object\_\_c          | String           | false    | Reference to the object the thread related to (i.e. a Salesforce ID of a record)                                                                                   |
| CRM_Related_Object_Type\_\_c     | String           | false    | API name of the reference in related object (If this is a SF ID)                                                                                                   |
| CRM_Latest_Message_Datetime\_\_c | String           | false    | Depicts the timestamp of the newest message in the thread (Calculated via flow)                                                                                    |
| CRM_From\_\_c                    | Lookup(User)     | false    | Relation to a users record (if the dialogue was started by NAV)                                                                                                    |
| CRM_Contact\_\_c                 | Lookup(Contact)  | false    | Relation to a community users contact record (if the dialogue was started by the external party)                                                                   |
| CRM_From_External\_\_c           | Formula(Boolean) | false    | Formula field to determine if the dialogue was initiated by the external party or NAV                                                                              |
| CRM_API_Reference\_\_c           | String           | false    | To prevent exposing salesforce external IDs in an API this field is always automatically generated for new record                                                  |
| CRM_Date_Time_Registered\_\_c    | Datetime         | false    | Automatically populated on creation of new threads (supporting migrating conversations from other systems without tampering with the system generated CreatedDate) |
| CRM_Sensitive_Information\_\_c   | Boolean          | false    | Boolean tag to activate the redaction process for a thread. Contact the team for more information about this.                                                      |

### 1.2 Message model

Below are some of the most essential fields defined on Message\_\_c

| Name                  | Type                | Required | Description                                                                                                                                                                                     |
| :-------------------- | :------------------ | :------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| CRM_Thread\_\_c       | Lookup(Thread\_\_c) | true     | There is a master-detail relation between thread and message (<strong>Remember this means that access to the thread record automatically grants access to all messages in the thread</strong>)  |
| CRM_Type\_\_c         | Picklist            | false    | Defines the message type and also controls how the message is shown in the standard components. Valid values are INFO, MESSAGE and EVENT. This defaults to message.                             |
| CRM_Event_Type\_\_c   | Picklist            | false    | Controlled by the type field and defines a event type if EVENT is selected.                                                                                                                     |
| CRM_Message_Text\_\_c | String              | false    | The actual message text                                                                                                                                                                         |
| CRM_Sent_date\_\_c    | Datetime            | false    | Timestamp for when the message was sent (defaults to created date in flow if not set upon insert)                                                                                               |
| CRM_Read\_\_c         | Boolean             | true     | Reflects the state of the message (from end-user side) if the message has been read. This is automatically set to true when opening the thread via the <i>crmMessagingCommunityThreadViewer</i> |
| CRM_From_User\_\_c    | Boolean             | true     | Lookup to a user record if the message has been sent from an internal user                                                                                                                      |
| CRM_From_Contact\_\_c | Boolean             | true     | Lookup to a contact record if the message has been sent from an external user                                                                                                                   |

### 1.3 Conversation note model

Below are some of the most essential fields defined on Conversation_Note\_\_c

| Name                           | Type            | Required | Description                                                                                                                |
| :----------------------------- | :-------------- | :------- | :------------------------------------------------------------------------------------------------------------------------- |
| CRM_Account\_\_c               | Lookup(Account) | false    | The account the conversation note is related to                                                                            |
| CRM_Communication_Channel\_\_c | Picklist        | false    | Channel of communication for the note (PHONE OR MEETING)                                                                   |
| CRM_Conversation_Note\_\_c     | Picklist        | false    | The actual written conversation note (summary of a conversation)                                                           |
| CRM_Date_Time_Registered\_\_c  | Datetime        | false    | Timestamp for when the note was written. (Automatically populated by default)                                              |
| CRM_Is_Read\_\_c               | Boolean         | false    | Determines if the note has been read by the recipient (Account/end user)                                                   |
| CRM_Read_Date\_\_c             | Datetime        | false    | Timestamp for when the conversation note was marked as read (Automatically populated when CRM_Is_Read\_\_c is set to true) |

## 2. Access and permissions

Baseline access to functionality in regards to the core is covered in the Messaging_Read_and_Write_Messages_and_Threads permission set. Additionally the Messaging_Quicktext and Redaction_Permission_Set grants access for internal users to user i.e. quick texts in the standard components.

## 3. Core components

The frontend functionality is delivered by a set og LWC that can be exposed [externally](force-app/main/default/external-components/.doc/) and [internally](force-app/main/default/internal-components/.doc/)

## 3. Guidelines

When implementing use of this package there are some important guidelines to follow to keep process automation specific for <strong>your</strong> usecase.

1. You should always define a new thread type for a different process. This means one or more new values should be added to the CRM_Thread_Type\_\_c field. Keep in mind that the amount of data in the tables are way over the LDV limit meaning you should always optimize your queries using indexed fields. For this purpose the <strong>CRM_Type\_\_c</strong> har been created and indexed on the thread object (This is populated in a flow for ALL thread types and copies the CRM_Thread_Type\_\_c value)
2. Be extremely careful when implementing validation rules to ensure these do ONLY trigger for your process' thread type
3. Please contact #crm-platform-team on slack if you require i.e. new message type or event types for to ensure this keeps the core functionality intact.
4. As of now the API defined in RestServices is tightly connected to STO/STB flow so please contact the team if there is need to restructure the API for more generic thread type handling (should be fairly easy to implement)
5. For journal and archive requirements a discussion is needed as currently the document template is a bit tightly connected to the STO solution and would need minor rework.

## 4. Dependencies

This package is dependant on the following packages

-   [crm-platform-base](https://github.com/navikt/crm-platform-base)
-   [crm-journal-utilities](https://github.com/navikt/crm-journal-utilities)
-   [crm-shared-user-notification](https://github.com/navikt/crm-shared-user-notification)
-   [crm-shared-flowComponents](https://github.com/navikt/crm-shared-flowComponents)

## 5. Installation

1. Install [npm](https://nodejs.org/en/download/)
1. Install [Salesforce DX CLI](https://developer.salesforce.com/tools/sfdxcli)
    - Alternative: `npm install sfdx-cli --global`
1. Clone this repository ([GitHub Desktop](https://desktop.github.com) is recommended for non-developers)
1. Run `npm install` from the project root folder
1. Install [SSDX](https://github.com/navikt/ssdx)
    - **Non-developers may stop after this step**
1. Install [VS Code](https://code.visualstudio.com) (recommended)
    - Install [Salesforce Extension Pack](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode)
    - **Install recommended plugins!** A notification should appear when opening VS Code. It will prompt you to install recommended plugins.
1. Install [AdoptOpenJDK](https://adoptopenjdk.net) (only version 8 or 11)
1. Open VS Code settings and search for `salesforcedx-vscode-apex`
1. Under `Java Home`, add the following:
    - macOS: `/Library/Java/JavaVirtualMachines/adoptopenjdk-[VERSION_NUMBER].jdk/Contents/Home`
    - Windows: `C:\\Program Files\\AdoptOpenJDK\\jdk-[VERSION_NUMBER]-hotspot`

## 6. Build

To build locally without using SSDX, do the following:

1. If you haven't authenticated a DX user to production / DevHub, run `sfdx auth:web:login -d -a production` and log in
    - Ask `#crm-platform-team` on Slack if you don't have a user
    - If you change from one repo to another, you can change the default DevHub username in `.sfdx/sfdx-config.json`, but you can also just run the command above
1. Create a scratch org, install dependencies and push metadata:

```bash
sfdx force:org:create -f ./config/project-scratch-def.json --setalias scratch_org --durationdays 1 --setdefaultusername
echo y | sfdx plugins:install sfpowerkit@2.0.1
keys="" && for p in $(sfdx force:package:list --json | jq '.result | .[].Name' -r); do keys+=$p":PACKAGE_KEY "; done
sfdx sfpowerkit:package:dependencies:install -u scratch_org -r -a -w 60 -k ${keys}
sfdx force:source:push
sfdx force:org:open
```

## Scratch org Setup

There are three apex scripts in dummy data that can be run in order to generate and cleanup dummy data: `MergeAccounts`, `GenerateData` and `GenerateDataThread`. MergeAccounts will try to clean up any duplicate account that were created when importing dummy data. This should be run before `GenerateData`. `GenerateDataThread` must run as its own execution after `GenerateData` - it can't be combined with `GenerateData` into a single anonymous Apex run because that mixes DML on a setup object (`User`) with non-setup objects (`Thread__c`), which Salesforce doesn't allow in the same transaction.

The apex scripts can de run with these commands:

-   `sfdx force:apex:execute -f ./dummy-data/MergeAccounts.apex`
-   `sfdx force:apex:execute -f ./dummy-data/GenerateData.apex`
-   `sfdx force:apex:execute -f ./dummy-data/GenerateDataThread.apex`

`package.json` contains some jobs in scripts that can be run in the scratch org:

-   `scratch:user:enableDebug` Enable debug molde on user
-   `scratch:enableMock:200` Enable all mocks
-   `scratch:postCreate` Runs the two mentioned scripts and the apex scripts

## Other

Questions? Ask on #crm-platform-team on Slack.
