<#
.SYNOPSIS
    Provides simple access to the ConfigMgr Client Logs using CMTrace.exe
.DESCRIPTION
    Provides simple access to the ConfigMgr Client Logs using CMTrace.exe
.PARAMETER cmtrace
    Specify the Path to CMTrace.exe
.EXAMPLE
    .\ConfigMgr_LogFile_Opener.ps1 -cmtrace C:\temp\CMTrace.exe
.NOTES
    Script name: ConfigMgr_LogFile_Opener.ps1
    Author:      @SimonDettling <msitproblog.com>
    DateCreated: 2016-11-19
    Version:     1.0.0
#>

[CmdletBinding(SupportsShouldProcess=$true)]

param(
    [parameter(Mandatory=$false, ParameterSetName="Single", HelpMessage="Specify the Path to CMTrace.exe")]
    [string] $cmtrace = "C:\Windows\CMTrace.exe"
)

Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Windows.Forms

$logfileTable = @{
    "ccmsetup" = @{
        "path" = "Windows\ccmsetup\Logs"
        "logfiles" = "ccmsetup.log"
    }
    "ccmupdate" = @{
        "path" = "Windows\CCM\Logs"
        "logfiles" = '"ScanAgent.log" "UpdatesDeployment.log" "UpdatesHandler.log" "UpdatesStore.log" "WUAHandler.log"'
    }
    "winupdate" = @{
        "path" = "Windows"
        "logfiles" = 'WindowsUpdate.log'
    }
    "ccmappdiscovery" = @{
        "path" = "Windows\CCM\Logs"
        "logfiles" = 'AppDiscovery.log'
    }
    "ccmappenforce" = @{
        "path" = "Windows\CCM\Logs"
        "logfiles" = 'AppEnforce.log'
    }
    "ccmexecmgr" = @{
        "path" = "Windows\CCM\Logs"
        "logfiles" = 'execmgr.log'
    }
    "ccmexec" = @{
        "path" = "Windows\CCM\Logs"
        "logfiles" = 'ccmexec.log'
    }
    "ccmstartup" = @{
        "path" = "Windows\CCM\Logs"
        "logfiles" = 'ClientIDManagerStartup.log'
    }
    "ccmpolicy" = @{
        "path" = "Windows\CCM\Logs"
        "logfiles" = '"PolicyAgent.log" "PolicyAgentProvider.log" "PolicyEvaluator.log" "StatusAgent.log"'
    }
    "ccmepagent" = @{
        "path" = "Windows\CCM\Logs"
        "logfiles" = 'EndpointProtectionAgent.log'
    }
    "ccmdownload" = @{
        "path" = "Windows\CCM\Logs"
        "logfiles" = '"CAS.log" "CIDownloader.log" "DataTransferService.log"'
    }
    "ccmeval" = @{
        "path" = "Windows\ccmsetup\Logs"
        "logfiles" = 'ccmsetup-ccmeval.log'
    }
    "ccminventory" = @{
        "path" = "Windows\CCM\Logs"
        "logfiles" = '"InventoryAgent.log" "InventoryProvider.log"'
    }
}

Function Open-LogFile {
    # Get Parameters
    Param(
        [Parameter(Mandatory=$true,Position=0,valueFromPipeline=$true)]
        [string]
        $action,

        [Parameter(Mandatory=$false,Position=1,valueFromPipeline=$true)]
        [string]
        $hostname
    )

    # Get action from Hash Table, and throw error if it does not exist
    $actionHandler = $logfileTable.GetEnumerator() | Where-Object {$_.Key -eq $action}
    If (!$actionHandler) {
        Invoke-ErrorMessage "Action '$action' can not be found in Hash Table."
    }

    # Assign values from Hash Table
    $logfilePath = "\\$hostname\c$\$($actionHandler.Value.path)"
    $logfiles = $actionHandler.Value.logfiles

    # Check if path is accessible
    If ((Test-Path $logfilePath) -eq $false) {
        Invoke-ErrorMessage("'$logfilePath' is not accessible")
    }

    # Check if CMTrace exists
    If ((Test-Path $cmtrace) -eq $false) {
        Invoke-ErrorMessage("'$cmtrace' is not accessible")
    }

    # Start CMTrace and wait 1 second
    Start-Process -FilePath $cmtrace
    Start-Sleep -Milliseconds 1000

    # Write current path in Registry
    Set-ItemProperty -Path HKCU:\Software\Microsoft\Trace32 -Value $logfilePath -Name "Last Directory" -Force

    # Send CTRL+O to open the open file dialog
    [System.Windows.Forms.SendKeys]::SendWait("^o")
    Start-Sleep -Milliseconds 1000

    # Write logfiles name
    [System.Windows.Forms.SendKeys]::SendWait($logfiles)

    # Check if multiple files were specified
    If ($logfiles.contains('" "')) {
        # Navigate to Merge checkbox and enable it
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}{TAB}{TAB}{TAB}{TAB}")
        [System.Windows.Forms.SendKeys]::SendWait(" ")
    }

    # Send ENTER
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

    # Wait two seconds until log file is loaded
    Start-Sleep -Milliseconds 2000

    # Send CTRL + END to scroll to the bottom
    [System.Windows.Forms.SendKeys]::SendWait("^{END}")

    # Set Empty path in registry
    Set-ItemProperty -Path HKCU:\Software\Microsoft\Trace32 -Value "" -Name "Last Directory" -Force
}

Function Open-Path {
    # Get Parameters
    Param(
        [Parameter(Mandatory=$true,Position=0,valueFromPipeline=$true)]
        [string]
        $logfilePath,

        [Parameter(Mandatory=$false,Position=1,valueFromPipeline=$true)]
        [string]
        $hostname
    )

    # build full path
    $logfilePath = "\\$hostname\c$\$logfilePath"

    # Check if path is accessible
    If ((Test-Path $logfilePath) -eq $false) {
        Invoke-ErrorMessage("'$logfilePath' is not accessible")
    }

    # Open explorer
    Start-Process $logfilePath
}

Function Invoke-ErrorMessage {
    # Get Parameters
    Param(
        [Parameter(Mandatory=$true,Position=0,valueFromPipeline=$true)]
        [string]
        $message
    )

    # Display Error Message and exit script
    [System.Windows.Forms.MessageBox]::Show($message,"ConfigMgr Log File Opener",'OK','Error')
    Exit
}

Function Write-MenuHeader {
    Write-Output "###############################################"
    Write-Output "#                                             #"
    Write-Output "#          ConfigMgr LogFile Opener           #"
    Write-Output "#                    1.0.0                    #"
    Write-Output "#               msitproblog.com               #"
    Write-Output "#                                             #"
    Write-Output "###############################################"
    Write-Output ""
}

Function Invoke-Menu {
    Clear-Host

    # Get targeted Computer
    Write-MenuHeader
    $hostname = Read-Host "Enter Hostname of Client Computer"
    Clear-Host

    # Check if a inout was specified
    If ($hostname -eq "") {
        Invoke-Menu
    }

    # Write Menu
    Write-MenuHeader
    Write-Output "Connected Device: $hostname"
    Write-Output ""
    Write-Output "------------------- CMTrace -------------------"
    Write-Output "[1] ccmsetup.log"
    Write-Output "[2] ScanAgent.log, Updates*.log, WUAHandler.log"
    Write-Output "[3] AppDiscovery.log"
    Write-Output "[4] AppEnforce.log"
    Write-Output "[5] execmgr.log"
    Write-Output "[6] ccmexec.log"
    Write-Output "[7] ClientIDStartupManager.log"
    Write-Output "[8] Policy*.log, StatusAgent.log"
    Write-Output "[9] EndpointProtectionAgent.log"
    Write-Output "[10] CAS.log, CIDownloader.log, DataTransferService.log"
    Write-Output "[11] CcmEval.log"
    Write-Output "[12] InventoryAgent.log, InventoryProvider.log"
    Write-Output ""
    Write-Output "---------------- File Explorer ----------------"
    Write-Output "[13] C:\Windows\CCM\Logs"
    Write-Output "[14] C:\Windows\ccmcache"
    Write-Output "[15] C:\Windows\ccmsetup"
    Write-Output "[16] C:\Windows\Logs\Software"
    Write-Output ""
    Write-Output "[98] Change Hostname"
    Write-Output "[99] Exit"
    Write-Output ""

    While (1) {
        Switch (Read-Host "Please select an Action") {
         1 {Open-LogFile "ccmsetup" $hostname}
         2 {Open-LogFile "ccmupdate" $hostname}
         3 {Open-LogFile "ccmappdiscovery" $hostname}
         4 {Open-LogFile "ccmappenforce" $hostname}
         5 {Open-LogFile "ccmexecmgr" $hostname}
         6 {Open-LogFile "ccmexec" $hostname}
         7 {Open-LogFile "ccmstartup" $hostname}
         8 {Open-LogFile "ccmpolicy" $hostname}
         9 {Open-LogFile "ccmepagent" $hostname}
         10 {Open-LogFile "ccmdownload" $hostname}
         11 {Open-LogFile "ccmeval" $hostname}
         12 {Open-LogFile "ccminventory" $hostname}
         13 {Open-Path "Windows\CCM\Logs" $hostname}
         14 {Open-Path "Windows\ccmcache" $hostname}
         15 {Open-Path "Windows\ccmsetup" $hostname}
         16 {Open-Path "Windows\Logs\Software" $hostname}
         98 {Invoke-Menu}
         99 {Exit}
        }
    }
}

Invoke-Menu