<#
.SYNOPSIS
    Provides simple access to the ConfigMgr Client Logs using CMTrace.exe
.DESCRIPTION
    Provides simple access to the ConfigMgr Client Logs using CMTrace.exe
.PARAMETER CMTrace
    Specify the Path to CMTrace.exe
.PARAMETER Hostname
    Specify a Default hostname for direct connection. Otherwise the Tool will prompt you to specify a hostname.
.PARAMETER ClientLogFilesDir
    Specify the directory in which the ConfigMgr Client LogFiles are located. (e.g: "Program Files\CCM\Logs")
.PARAMETER DisableLogFileMerging
    If specified, the LogFiles won't get merged by CMTrace
.PARAMETER WindowStyle
    Specify the Window Style of CMTrace and File Explorer. Default value is 'normal'
.EXAMPLE
    .\ConfigMgr_LogFile_Opener.ps1 -CMTrace 'C:\temp\CMTrace.exe' -Hostname 'PC01' -ClientLogFilesDir 'Program Files\CCM\Logs' -DisableLogFileMerging -WindowStyle Maximized
.NOTES
    Script name:   ConfigMgr_LogFile_Opener.ps1
    Author:        @SimonDettling <msitproblog.com>
    Date modified: 2016-12-19
    Version:       1.1.0
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false, HelpMessage='Specify the hostname for direct connection. Otherwise the Tool will prompt you to specify a hostname.')]
    [string] $Hostname = '',

    [Parameter(Mandatory=$false, HelpMessage='Specify the Path to CMTrace.exe')]
    [string] $CMTrace = 'C:\Windows\CMTrace.exe',

    [Parameter(Mandatory=$false, HelpMessage='Specify the directory in which the ConfigMgr Client Logfiles are located. (e.g: "Program Files\CCM\Logs")')]
    [string] $ClientLogFilesDir = 'c$\Windows\CCM\Logs',

    [Parameter(Mandatory=$false, HelpMessage="If specified, the LogFiles won't get merged by CMTrace")]
    [switch] $DisableLogFileMerging,

    [Parameter(Mandatory=$false, HelpMessage="Specify the Window Style of CMTrace and File Explorer. Default value is 'normal'")]
    [ValidateSet('Minimized', 'Maximized', 'Normal')]
    [string] $WindowStyle = 'Normal'
)

# Add Forms Assembly for displaying error message popups
Add-Type -AssemblyName System.Windows.Forms | Out-Null

$logfileTable = @{
    'ccmsetup' = @{
        'path' = 'c$\Windows\ccmsetup\Logs'
        'logfiles' = 'ccmsetup.log'
    }
    'ccmupdate' = @{
        'path' = $clientLogfilesDir
        'logfiles' = '"ScanAgent.log" "UpdatesDeployment.log" "UpdatesHandler.log" "UpdatesStore.log" "WUAHandler.log"'
    }
    'winupdate' = @{
        'path' = 'c$\Windows'
        'logfiles' = 'WindowsUpdate.log'
    }
    'ccmappdiscovery' = @{
        'path' = $clientLogfilesDir
        'logfiles' = 'AppDiscovery.log'
    }
    'ccmappenforce' = @{
        'path' = $clientLogfilesDir
        'logfiles' = 'AppEnforce.log'
    }
    'ccmexecmgr' = @{
        'path' = $clientLogfilesDir
        'logfiles' = 'execmgr.log'
    }
    'ccmexec' = @{
        'path' = $clientLogfilesDir
        'logfiles' = 'ccmexec.log'
    }
    'ccmstartup' = @{
        'path' = $clientLogfilesDir
        'logfiles' = 'ClientIDManagerStartup.log'
    }
    'ccmpolicy' = @{
        'path' = $clientLogfilesDir
        'logfiles' = '"PolicyAgent.log" "PolicyAgentProvider.log" "PolicyEvaluator.log" "StatusAgent.log"'
    }
    'ccmepagent' = @{
        'path' = $clientLogfilesDir
        'logfiles' = 'EndpointProtectionAgent.log'
    }
    'ccmdownload' = @{
        'path' = $clientLogfilesDir
        'logfiles' = '"CAS.log" "CIDownloader.log" "DataTransferService.log"'
    }
    'ccmeval' = @{
        'path' = $clientLogfilesDir
        'logfiles' = 'CcmEval.log'
    }
    'ccminventory' = @{
        'path' = $clientLogfilesDir
        'logfiles' = '"InventoryAgent.log" "InventoryProvider.log"'
    }
    'ccmsmsts' = @{
        'path' = $clientLogfilesDir
        'logfiles' = 'smsts.log'
    }
}

Function Open-LogFile ([string] $action) {
    # Get action from Hash Table, and throw error if it does not exist
    $actionHandler = $logfileTable.GetEnumerator() | Where-Object {$_.Key -eq $action}
    If (!$actionHandler) {
        Invoke-ErrorMessage -Message "Action '$action' can not be found in Hash Table"
    }

    # Assign values from Hash Table
    $logfilePath = "\\$hostname\$($actionHandler.Value.path)"
    $logfiles = $actionHandler.Value.logfiles

    # Check if path is accessible
    If (!(Test-Path -Path $logfilePath)) {
        Invoke-ErrorMessage -Message "'$logfilePath' is not accessible!"
    }

    # Check if CMTrace exists
    If (!(Test-Path -Path $cmtrace)) {
        Invoke-ErrorMessage -Message "'$cmtrace' is not accessible!"
    }

    # Check if CMTrace was started at least once. This is needed to make sure that the initial FTA PopUp doesn't appear.
    If (!(Test-Path -Path 'HKCU:\Software\Microsoft\Trace32')) {
        Invoke-ErrorMessage -Message "CMTrace needs be started at least once. Click 'OK' to launch CMTrace, confirm all dialogs and try again." -Icon 'Warning' -PostAction {Invoke-CMTrace}
    }

    # Write current path in Registry
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Trace32' -Value $logfilePath -Name 'Last Directory' -Force

    # Create Shell Object. Usage of the .NET Classes led to CMTrace Freezes.
    $shell = New-Object -ComObject WScript.Shell

    # Check if multiple files were specified
    If ($logfiles.contains('" "')) {
        # Start CMTrace and wait until it's open
        Start-Process -FilePath $cmtrace
        Start-Sleep -Seconds 1

        # Send CTRL+O to open the open file dialog
        $shell.SendKeys('^o')
        Start-Sleep -Seconds 1

        # Write logfiles name
        $shell.SendKeys($logfiles)

        # check if logfile merging is not disabled
        If (!$disableLogfileMerging) {
            # Navigate to Merge checkbox and enable it
            $shell.SendKeys('{TAB}{TAB}{TAB}{TAB}{TAB}')
            $shell.SendKeys(' ')
        }

        # Send ENTER
        $shell.SendKeys('{ENTER}')
    } Else {
        # Build full logfile path
        $fullLogfilePath = $logfilePath + '\' + $logfiles

        # Check if Logfile exists
        If (!(Test-Path -Path $fullLogfilePath)) {
            Invoke-ErrorMessage -Message "'$fullLogfilePath' is not accessible!"
        }

        # Open Logfile in CMTrace
        Start-Process -FilePath $cmtrace -ArgumentList $fullLogfilePath
    }

    # Wait until log file is loaded
    Start-Sleep -Seconds 1

    # Send CTRL + END to scroll to the bottom
    $shell.SendKeys('^{END}')

    # Check WindowStyle. NOTE: CMTrace can't be launched using the native 'WindowStyle' Attribute via Start-Process above.
    Switch ($windowStyle) {
        'Minimized' {$shell.SendKeys('% n')}
        'Maximized' {$shell.SendKeys('% x')}
    }

    # Set Empty path in registry
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Trace32' -Value '' -Name 'Last Directory' -Force

    Invoke-Menu
}

Function Open-Path ([string] $LogfilePath) {
    # build full path
    $logfilePath = "\\$hostname\$logfilePath"

    # Check if path is accessible
    If (!(Test-Path -Path $logfilePath)) {
        Invoke-ErrorMessage -Message "'$logfilePath' is not accessible!"
    }

    # Open File explorer
    Start-Process -FilePath 'C:\Windows\explorer.exe' -ArgumentList $logfilePath -WindowStyle $windowStyle

    Invoke-Menu
}

Function Invoke-CMTrace {
    # Check if CMTrace exists
    If (!(Test-Path -Path $cmtrace)) {
        Invoke-ErrorMessage -Message "'$cmtrace' is not accessible!"
    }

    # Open Logfile in CMTrace
    Start-Process -FilePath $cmtrace

    Invoke-Menu
}

Function Invoke-ErrorMessage([string] $Message, [string] $Icon = 'Error', [switch] $ResetHostname, [string] $PostAction) {
    # Display Error Message and exit script
    [System.Windows.Forms.MessageBox]::Show($message, 'ConfigMgr LogFile Opener', 'OK', $icon)

    # Check for Post action and execute it
    If ($postAction -ne '') {
        & $postAction
    }

    # Fire up menu and reset stored hostname if specified
    If ($resetHostname) {
        Invoke-Menu -ResetHostname
    } Else {
        Invoke-Menu
    }
}

Function Write-MenuHeader {
    Write-Output '###############################################'
    Write-Output '#                                             #'
    Write-Output '#          ConfigMgr LogFile Opener           #'
    Write-Output '#                    1.1.0                    #'
    Write-Output '#               msitproblog.com               #'
    Write-Output '#                                             #'
    Write-Output '###############################################'
    Write-Output ''
}

Function Invoke-Menu ([switch] $ResetHostname, [switch] $FirstLaunch) {
    # Reset Hostname if needed
    If ($resetHostname) {
        $hostname = ''
    }

    Clear-Host

    If ($hostname -eq '') {
        # Get targeted Computer
        Write-MenuHeader
        $hostname = Read-Host -Prompt 'Enter name of Device'

        # Check if no hostname was specified
        If ($hostname -eq '') {
            Invoke-ErrorMessage -Message 'Please specify a Device name.' -ResetHostname
        }
    }

    # Check if the provided Hostname is valid, if hostname has changed or the menu was invoked for the first time
    If ($resetHostname -or $firstLaunch) {
        If ([System.Uri]::CheckHostName($hostname) -eq 'Unknown') {
            Invoke-ErrorMessage -Message "The specified Device name '$hostname' is not valid." -ResetHostname
        }

        # Check if host is online
        If (!(Test-Path -Path "\\$hostname\c$")) {
            Invoke-ErrorMessage -Message "The specified Device '$hostname' is not accessible." -ResetHostname
        }
    }

    Clear-Host

    # Write main Menu
    Write-MenuHeader
    Write-Output "Connected Device: $hostname"
    Write-Output ''
    Write-Output '------------------- CMTrace -------------------'
    Write-Output '[1] ccmsetup.log'
    Write-Output '[2] ScanAgent.log, Updates*.log, WUAHandler.log'
    Write-Output '[3] AppDiscovery.log'
    Write-Output '[4] AppEnforce.log'
    Write-Output '[5] execmgr.log'
    Write-Output '[6] ccmexec.log'
    Write-Output '[7] ClientIDStartupManager.log'
    Write-Output '[8] Policy*.log, StatusAgent.log'
    Write-Output '[9] EndpointProtectionAgent.log'
    Write-Output '[10] CAS.log, CIDownloader.log, DataTransferService.log'
    Write-Output '[11] CcmEval.log'
    Write-Output '[12] InventoryAgent.log, InventoryProvider.log'
    Write-Output '[13] smsts.log'
    Write-Output '[14] WindowsUpdate.log'
    Write-Output ''
    Write-Output '---------------- File Explorer ----------------'
    Write-Output '[50] C:\Windows\CCM\Logs'
    Write-Output '[51] C:\Windows\ccmcache'
    Write-Output '[52] C:\Windows\ccmsetup'
    Write-Output '[53] C:\Windows\Logs\Software'
    Write-Output ''
    Write-Output '-------------------- Tool ---------------------'
    Write-Output '[97] Start CMTrace'
    Write-Output '[98] Change Device'
    Write-Output '[99] Exit'
    Write-Output ''

    Switch (Read-Host -Prompt 'Please select an Action') {
        1 {Open-LogFile 'ccmsetup'}
        2 {Open-LogFile 'ccmupdate'}
        3 {Open-LogFile 'ccmappdiscovery'}
        4 {Open-LogFile 'ccmappenforce'}
        5 {Open-LogFile 'ccmexecmgr'}
        6 {Open-LogFile 'ccmexec'}
        7 {Open-LogFile 'ccmstartup'}
        8 {Open-LogFile 'ccmpolicy'}
        9 {Open-LogFile 'ccmepagent'}
        10 {Open-LogFile 'ccmdownload'}
        11 {Open-LogFile 'ccmeval'}
        12 {Open-LogFile 'ccminventory'}
        13 {Open-LogFile 'ccmsmsts'}
        14 {Open-LogFile 'winupdate'}
        50 {Open-Path 'c$\Windows\CCM\Logs'}
        51 {Open-Path 'c$\Windows\ccmcache'}
        52 {Open-Path 'c$\Windows\ccmsetup'}
        53 {Open-Path 'c$\Windows\Logs\Software'}
        97 {Invoke-CMTrace}
        98 {Invoke-Menu -ResetHostname}
        99 {Clear-Host; Exit}
        Default {Invoke-Menu}
    }
}

Invoke-Menu -FirstLaunch