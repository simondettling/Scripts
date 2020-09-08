# Remove orphaned Active Directory Users from Configuration Manager
## Documentation
The full Documentation of this Script can be found on my blog: https://msitproblog.com/2018/05/15/remove-orphaned-active-directory-users-from-configuration-manager/

Below is a short summary of the most important steps.

## Prerequisites
* Configuration Manager Console
* Active Directory PowerShell Module

The Script was tested with Windows Server 2016/2019 and Configuration Manager current branch.

## Usage
Open the PowerShell file and modify the Site-Server and Site-Code, so it matches your environment.

Execute the script, which might take a while based on the amount of users it needs to process. When it completes, you should get a bunch of Warnings with users that don't exist anymore in Active Directory.

![alt text](https://msitproblog.com/wp-content/uploads/2018/05/ConfigMgr_DeletedADUsers_featureImage-1.png)

You can then either manually delete those users from Configuration Manager or you can change the Script Variable $deleteOrphanedUsers to $true, to make the Script delete them for you.

**Important: PowerShell will prompt you to confirm the deletion of every single user.**

(There is a little hint in the script on how you can automatically remove the users without any prompt. This modification needs to be done manually though because you need to know what you're doing. :) )
