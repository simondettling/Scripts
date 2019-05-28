#########################################################################
#
#        Name:   ConfigMgr_Clients_At_Risk.ps1
#    Modified:   2015-09-09
#      Author:   @SimonDettling <http://msitproblog.com>
#     Version:	 1.0.0
#
#########################################################################

# Specify your site code
$siteCode = "PRI"

# Specify the FQDN of your Configuration Manager Site Server
$siteServer = "siteserver.domain.tld"

# Specify E-Mail related settings
$mailSmtp = 'smtp.domain.tld'
$mailFrom = "config.mgr@domain.tld"
[string[]] $mailTo = "recipient1@domain.tld", "recipient2@domain.tld"
$mailSubject = "Configuration Manager - Clients at Risk"

# Specify the warning threshold. If this threshold is reached, the E-Mail will have a orange background color
$warningThreshold = 10

# Specify the error threshold. If this threshold is reached, the E-Mail will have a red background color
$errorThreshold = 15

# Outputs the Results to the console
$outputResult = $false

#########################################################################
# BEGIN SCRIPT BLOCK
#########################################################################
$wqlQuery = "SELECT Name FROM SMS_R_System INNER JOIN SMS_G_System_EndpointProtectionStatus ON SMS_G_System_EndpointProtectionStatus.ResourceId = SMS_R_System.ResourceId WHERE SMS_G_System_EndpointProtectionStatus.AtRisk = 1"
$mailBody = ""

# Get Clients at risk
$deviceNames = Get-WmiObject -Namespace "root\sms\site_$siteCode" -ComputerName $siteServer -Query $wqlQuery | Select Name | Sort Name
$deviceCount = ($deviceNames | Measure-Object).Count

# Check Threshold and set backgrounds
If ($deviceCount -ge $errorThreshold) {
    $mailBody += "<body style='background-color: #E1A6A6;'>"
} ElseIf ($deviceCount -ge $warningThreshold) {
    $mailBody += "<body style='background-color: #FFDF60;'>"
} Else {
    $mailBody += "<body>"
}

# Set Title
$mailBody += "<p style='font-family: Arial;'>The following $deviceCount Devices are 'At Risk' in System Center Configuration Manager:</p>"

If ($deviceCount -ne 0) {
	# Get and write device name
    foreach ($deviceObj In $deviceNames) {
        $name = $deviceObj.Name.ToUpper()
        $mailBody += "<p style='font-family: Arial; margin: 0'>- $name</p>"
    }
    $mailBody += "</body>"

    Send-MailMessage -SmtpServer $mailSmtp -From $mailFrom -To $mailTo -Subject $mailSubject -BodyAsHtml $mailBody -Priority High
}

If ($outputResult -eq $true) {
	Write-Output $deviceNames
}
#########################################################################
# END SCRIPT BLOCK 
#########################################################################