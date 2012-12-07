
/**
 * Copyright (c) 2012, Stephen Willcock
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, 
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, 
 *      this list of conditions and the following disclaimer in the documentation 
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors 
 *      may be used to endorse or promote products derived from this software without 
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

global with sharing class CommunityRegistrationHandler implements Auth.RegistrationHandler
{
	// See: http://www.salesforce.com/us/developer/docs/apexcode/Content/apex_auth_plugin.htm

	global User createUser(Id portalId, Auth.UserData data)
	{
        debug('createUser',data);

		// TODO - replace this primitive Contact search with your own implementation 
		List<Contact> contacts = [SELECT Id FROM Contact WHERE Email = :data.Email ORDER BY CreatedDate DESC];
		Contact contact = contacts.isEmpty() ? null : contacts[0];

        if (contact==null)
        {
            throw new CommunityRegistrationHandlerException('Unable to find a contact for this email address: ' + data.Email);
        }
                
        List<User> users = [SELECT Id,Email,Username,FirstName,LastName,Alias,CommunityNickname,ProfileId,
        	ContactId,LocaleSidKey,LanguageLocaleKey,TimeZoneSidKey,EmailEncodingKey FROM User WHERE ContactId = :contact.Id];
		User user = users.isEmpty() ? null : users[0];
		        
        if(user==null)
        {
	        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = 'High Volume Customer Portal'];
			Profile profile = profiles.isEmpty() ? null : profiles[0];
			
	        if(profile==null)
	            throw new CommunityRegistrationHandlerException('Could not find a Community user profile');

			// TODO nickname/alias collision avoidance
	        String alias = data.email.replace('@', '').substring(0, 8);
	        String nickname = data.attributeMap.get('display_name');
	        
	        user = new User(
	            Email = data.email,
	            Username = data.email,
	            Alias = alias,
	            CommunityNickname = nickname,
	            ProfileId = profile.Id,
	            ContactId = contact.Id
	        );
        }

		updateUserSobject(user,data);

        return user;
    }
    
    global void updateUser(Id userId, Id portalId, Auth.UserData data)
    {
        debug('updateUser',data);
        User user = new User(Id=userId);
        updateUserSobject(user,data);
        update user;
    }

	void updateUserSobject(User user, Auth.UserData data)
	{
        user.FirstName = data.firstName;
        user.LastName = data.lastName;
        user.LocaleSidKey = data.locale;
        user.LanguageLocaleKey = data.attributeMap.get('language');
        user.TimeZoneSidKey = 'Europe/London'; // TODO
        user.EmailEncodingKey  = 'ISO-8859-1';
	}


	void debug(String context,Auth.UserData data)
	{
		system.debug('§ ' + context);
        // Useful data which you may want to store or make use of:
		system.debug('§ organization_id ' + data.attributeMap.get('organization_id'));
		system.debug('§ user_id ' + data.attributeMap.get('user_id'));
		system.debug('§ username ' + data.attributeMap.get('username'));
	}
	
    class CommunityRegistrationHandlerException extends Exception{}
    
	static testMethod void testCreateAndUpdateUser()
	{
		Account account = new Account(Name='TestAccount');
		insert account;
		Contact contact = new Contact(AccountId=account.id, FirstName='testFirstName', LastName='testLastName', email='someone@somewhere.com');
		insert contact; 
		CommunityRegistrationHandler handler = new CommunityRegistrationHandler();
		Auth.UserData data = new Auth.UserData( 'testId', //String identifier 
			'testFirstName', // String firstName
			'testLastName', // String lastName
			'testFullName', // String fullName
			'someone@somewhere.com', // String email
			null, // String link
			'testUserName', // String userName
			'en_US', // String locale
			'salesforce', // String provider
			null, // String siteLoginUrl
			new Map<String, String>{
				'display_name'=>'testDisplayName',
				'language'=>'en_US',
				'organization_id'=>'testOrgId',
				'user_id'=>'testUserId',
				'username'=>'testUsername'
				} // Map<String, String> attributeMap
          );
		User user = handler.createUser(null, data);
		System.assertEquals('testFirstName', user.firstName);
		System.assertEquals('testLastName', user.lastName);
		insert(user);
		data.firstName='updatedFirstName';
		handler.updateUser(user.id, null, data);
		user = [SELECT firstName,lastName FROM user WHERE id=:user.id];
		System.assertEquals('updatedFirstName', user.firstName);
		System.assertEquals('testLastName', user.lastName);
	}    
}