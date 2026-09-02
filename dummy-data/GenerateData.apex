//Set user role
if(String.isBlank(UserInfo.getUserRoleId())) {
    update new User(Id = UserInfo.getUserId(), UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'NKS'][0].Id);
}

//Dummy data script for creating community user and associated dummy data
Account communityAccount = [SELECT Id, FirstName, LastName, PersonContactId FROM Account WHERE CRM_Person__r.Name = '12345678901' LIMIT 1];

Profile portalProfile = [SELECT Id, Name FROM Profile WHERE UserType = 'PowerCustomerSuccess' and Name = 'Customer Community Plus User' LIMIT 1];


User portalUser = new User();
portalUser.FirstName = communityAccount.FirstName;
portalUser.LastName = communityAccount.LastName;
portalUser.ContactId = communityAccount.PersonContactId;
portalUser.Alias = 'hpott';
portalUser.Username = 'harry.potter@test.nav.henvendelse';
portalUser.Email = 'harry.potter@test.nav.henvendelse';
portalUser.ProfileId = portalProfile.Id;
portalUser.EmailEncodingKey = 'UTF-8';
portalUser.CommunityNickname = 'testUser1';
portalUser.TimeZoneSidKey = 'Europe/Paris';
portalUser.LocaleSidKey = 'no_NO';
portalUser.LanguageLocaleKey = 'no';
insert portalUser;
