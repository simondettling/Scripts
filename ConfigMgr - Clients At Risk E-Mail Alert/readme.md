# Configuration Manager - Clients At Risk E-Mail Alert
This PowerShell Script will send you an E-Mail with all Devices which have the Status 'At Risk' in Configuration Manager 2012. Right now you can only manually check the Devices which are 'At Risk' via the 'System Center Endpoint Protection Status' Dashboard.

You can run this script on any System in your environment. It will remotley connect to the WMI Namespace of your Configuration Manager Site Server to get the necessary informations.

Please fill / modify the PowerShell Variables in the beginning of the Script with the needed data.

You can run the script as Scheduled Task, using the following syntax:

`C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoLogo -NonInteractive -ExecutionPolicy Bypass "C:\Path\To\Script\ConfigMgr_Clients_At_Risk.ps1"`
