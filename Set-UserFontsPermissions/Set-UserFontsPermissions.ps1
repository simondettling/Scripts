<#
.SYNOPSIS
    Grants the specified User / Group the Permission to add and remove Fonts, without the needs of local Administrator permissions. IMPORTANT: You need to restart your device, after executing the Script!
.DESCRIPTION
    Grants the specified User / Group the Permission to add and remove Fonts, without the needs of local Administrator permissions. IMPORTANT: You need to restart your device, after executing the Script!
.PARAMETER User
    User or Group name which will be granted permission. e.g "DOMAIN\Group", "DOMAIN\User"
.EXAMPLE
    .\Set-UserFontsPermissions.ps1 -User "DOMAIN\Group"
.NOTES
    Script name: Set-UserFontsPermissions.ps1
    Author:      @SimonDettling <msitproblog.com>
    DateCreated: 2016-04-07
    Version:     1.0.0

    Script based on the following TechNet Forum Thread <http://bit.ly/1RFNQrH>

    WARNING: This Script modifies the Windows Operating System in unsupported ways. Use at your own risk!
#>
[CmdletBinding(SupportsShouldProcess=$true)]

param(
    [parameter(Mandatory=$true, ParameterSetName="Single", HelpMessage='User or Group name which will be granted Permission. e.g "DOMAIN\Group", "DOMAIN\User"')]
    [ValidateNotNullOrEmpty()]
    [string] $user
)

Write-Verbose "Clearing Read-Only and System-File Attribute of C:\Windows\Fonts"
Invoke-Expression "attrib -r -s 'C:\Windows\Fonts'"

Write-Verbose "Take Ownership of folder C:\Windows\Fonts"
Invoke-Expression "takeown /f 'C:\Windows\Fonts' /r /d n"

Write-Verbose "Grant Domain Users Modify Access to C:\Windows\Fonts"
Invoke-Expression "icacls 'C:\Windows\Fonts' /grant '${user}:(M)' /t"

Write-Verbose "Grant Domain Users Modify Access Font Cache File"
Invoke-Expression "icacls 'C:\Windows\System32\FNTCACHE.dat' /grant '${user}:(M)' /t"

Write-Verbose "Grant Domain Users Modify Access to Font Registry Hive"
$acl = Get-Acl -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
$rule = New-Object System.Security.AccessControl.RegistryAccessRule("$user","FullControl","Allow")
$acl.SetAccessRule($rule)
$acl | Set-Acl -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"

Write-Verbose "Terminate Script with Exit Code 3010 - Reboot needed"
Exit 3010