<#
.SYNOPSIS
    Provides simple access to the ConfigMgr Client Logs using CMTrace or CMLogViewer
.DESCRIPTION
    Provides simple access to the ConfigMgr Client Logs using CMTrace or CMLogViewer
.PARAMETER CMTrace
    Specify the Path to CMTrace.exe
.PARAMETER CMLogViewer
    Specify the Path to CMLogViewer.exe
.PARAMETER Hostname
    Specify a Default hostname for direct connection. Otherwise the Tool will prompt you to specify a hostname.
.PARAMETER ClientLogFilesDir
    Specify the directory in which the ConfigMgr Client LogFiles are located. (e.g: "Program Files\CCM\Logs")
.PARAMETER DisableLogFileMerging
    If specified, the LogFiles won't get merged by CMTrace
.PARAMETER WindowStyle
    Specify the Window Style of CMTrace and File Explorer. Default value is 'normal'
.PARAMETER CMTraceActionDelay
    Specify the amount of time in milliseconds, the Script should wait between the Steps when opening multiple LogFiles in CMTrace. Default value is 1500
.PARAMETER ActiveLogProgram
    Specify which Log Program should be active when the tool is starting. Default value is 'CMTrace'
.PARAMETER DisableHistoryLogFiles
    If specified, the Tool won't open any history log files
.PARAMETER RecentLogLimit
    Specify the number of recent log files which will be listed in the menu. Default value is 15
.PARAMETER DisableUpdater
    If specified, the Tool won't prompt if there is a newer Version available
.PARAMETER EnableAutoLogLaunch
    If specified, the Tool will automatically open the corresponding logs when executing client actions.
.EXAMPLE
    .\ConfigMgr_LogFile_Opener.ps1 -CMTrace 'C:\temp\CMTrace.exe' -Hostname 'PC01' -ClientLogFilesDir 'Program Files\CCM\Logs' -DisableLogFileMerging -WindowStyle Maximized
    .\ConfigMgr_LogFile_Opener.ps1 -CMLogViewer 'C:\temp\CMLogViewer.exe' -Hostname 'PC02' -CMTraceActionDelay 2000 -DisableHistoryLogFiles -ActiveLogProgram CMLogViewer -RecentLogLimit 25
.NOTES
    Script name:   ConfigMgr_LogFile_Opener.ps1
    Author:        @SimonDettling <msitproblog.com>
    Date modified: 2019-08-01
    Version:       2.0.0
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$false, HelpMessage='Specify the hostname for direct connection. Otherwise the Tool will prompt you to specify a hostname.')]
    [String] $Hostname = '',

    [Parameter(Mandatory=$false, HelpMessage='Specify the Path to CMTrace.exe')]
    [String] $CMTrace = 'C:\Windows\CCM\CMTrace.exe',

    [Parameter(Mandatory=$false, HelpMessage='Specify the Path to CMLogViewer.exe')]
    [String] $CMLogViewer = 'C:\Program Files (x86)\Configuration Manager Support Center\CMLogViewer.exe',

    [Parameter(Mandatory=$false, HelpMessage='Specify the directory in which the ConfigMgr Client Logfiles are located. (e.g: "Program Files\CCM\Logs")')]
    [String] $ClientLogFilesDir = 'C$\Windows\CCM\Logs',

    [Parameter(Mandatory=$false, HelpMessage="If specified, the LogFiles won't get merged by CMTrace")]
    [Switch] $DisableLogFileMerging,

    [Parameter(Mandatory=$false, HelpMessage="Specify the Window Style of CMTrace and File Explorer. Default value is 'normal'")]
    [ValidateSet('Minimized', 'Maximized', 'Normal')]
    [String] $WindowStyle = 'Normal',

    [Parameter(Mandatory=$false, HelpMessage="Specify the amount of time in milliseconds, the Script should wait between the Steps when opening multiple LogFiles in CMTrace. Default value is 1500")]
    [Int] $CMTraceActionDelay = 1500,

    [Parameter(Mandatory=$false, HelpMessage="Specify which Log Program should be active when the tool is starting. Default value is 'CMTrace'")]
    [ValidateSet('CMTrace', 'CMLogViewer')]
    [String] $ActiveLogProgram = 'CMTrace',

    [Parameter(Mandatory=$false, HelpMessage="If specified, the Tool won't open any history log files")]
    [Switch] $DisableHistoryLogFiles,

    [Parameter(Mandatory=$false, HelpMessage="Specify the number of recent log files which will be listed in the menu. Default value is 15")]
    [Int] $RecentLogLimit = 15,

    [Parameter(Mandatory=$false, HelpMessage="If specified, the Tool won't prompt if there is a newer Version available")]
    [Switch] $DisableUpdater,

    [Parameter(Mandatory=$false, HelpMessage="If specified, the Tool will automatically open the corresponding logs when executing client actions.")]
    [Switch] $EnableAutoLogLaunch
)

# General options
$toolVersion = "2.0.0"
$updateUrl = "https://msitproblog.com/clfo_options.xml"

# Add Visual Basic Assembly for displaying message popups
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

# Create Shell Object, for handling CMTrace Inputs. (Usage of the .NET Classes led to CMTrace Freezes.)
$shellObj = New-Object -ComObject WScript.Shell

# Contains the information if the connected device is remote or local
$hostnameIsRemote = $true

# Get date time Pattern for Date/Time Conversion
$dateTimePattern = (Get-Culture).DateTimeFormat.ShortDatePattern  + " " + (Get-Culture).DateTimeFormat.ShortTimePattern

$logfileTable = @{
    'ccmsetup' = @{
        'path' = 'C$\Windows\ccmsetup\Logs'
        'logfiles' = @('ccmsetup.log')
    }
    'ccmupdate' = @{
        'path' = $clientLogfilesDir
        'logfiles' = @('ScanAgent.log', 'UpdatesDeployment.log', 'UpdatesHandler.log', 'UpdatesStore.log', 'WUAHandler.log')
    }
    'winupdate' = @{
        'path' = 'C$\Windows'
        'logfiles' = @('WindowsUpdate.log')
    }
    'ccmappdiscovery' = @{
        'path' = $clientLogfilesDir
        'logfiles' = @('AppDiscovery.log')
    }
    'ccmappenforce' = @{
        'path' = $clientLogfilesDir
        'logfiles' = @('AppEnforce.log')
    }
    'ccmexecmgr' = @{
        'path' = $clientLogfilesDir
        'logfiles' = @('execmgr.log')
    }
    'ccmexec' = @{
        'path' = $clientLogfilesDir
        'logfiles' = @('CcmExec.log')
    }
    'ccmstartup' = @{
        'path' = $clientLogfilesDir
        'logfiles' = @('ClientIDManagerStartup.log')
    }
    'ccmpolicy' = @{
        'path' = $clientLogfilesDir
        'logfiles' = @('PolicyAgent.log', 'PolicyAgentProvider.log', 'PolicyEvaluator.log', 'StatusAgent.log')
    }
    'ccmepagent' = @{
        'path' = $clientLogfilesDir
        'logfiles' = @('EndpointProtectionAgent.log')
    }
    'ccmdownload' = @{
        'path' = $clientLogfilesDir
        'logfiles' = @('CAS.log', 'CIDownloader.log', 'DataTransferService.log')
    }
    'ccmsetupeval' = @{
        'path' = 'C$\Windows\ccmsetup\Logs'
        'logfiles' = @('ccmsetup-ccmeval.log')
    }
    'ccminventory' = @{
        'path' = $clientLogfilesDir
        'logfiles' = @('InventoryAgent.log', 'InventoryProvider.log')
    }
    'ccmsmsts' = @{
        'path' = $clientLogfilesDir
        'logfiles' = @('smsts.log')
    }
    'ccmstatemessage' = @{
        'path' = $clientLogfilesDir
        'logfiles' = @('StateMessage.log')
    }
    'winservicingsetupact' = @{
        'path' = 'C$\Windows\Panther'
        'logfiles' = @('setupact.log')
    }
    'winservicingsetuperr' = @{
        'path' = 'C$\Windows\Panther'
        'logfiles' = @('setuperr.log')
    }
    'scepmpcmdrun' = @{
        'path' = 'C$\Windows\Temp'
        'logfiles' = @('MpCmdRun.log')
    }
}

$ccmBuildNoTable = @{
    '7711' = '2012 RTM'
    '7804' = '2012 SP1'
    '8239' = '2012 SP2 / R2 SP1'
    '7958' = '2012 R2 RTM'
    '8325' = 'CB 1511'
    '8355' = 'CB 1602'
    '8412' = 'CB 1606'
    '8458' = 'CB 1610'
    '8498' = 'CB 1702'
    '8540' = 'CB 1706'
    '8577' = 'CB 1710'
    '8634' = 'CB 1802'
    '8692' = 'CB 1806'
    '8740' = 'CB 1810'
    '8790' = 'CB 1902'
    '8853' = 'CB 1906'
}

$consoleExtensionXmlFile = 'ConfigMgr LogFile Opener.xml'
$consoleExtensionActionGUIDs = @('fb04b7a5-bc4c-4468-8eb8-937d8eb90efb', 'ed9dee86-eadd-4ac8-82a1-7234a4646e62', 'cbe3631f-901e-49ea-b3c2-4e32996720cd', '0770186d-ea57-4276-a46b-7344ae081b58', '64db983c-10bc-4b47-8f2d-cfff48f34faf', '3fd01cd1-9e01-461e-92cd-94866b8d1f39', '2b646eff-442b-410e-adf3-d4ec699e0ab4')
$consoleExtensionXmlContent = '<ActionDescription Class="Executable" DisplayName="Start ConfigMgr LogFile Opener" MnemonicDisplayName="Start ConfigMgr LogFile Opener" Description = "Start ConfigMgr LogFile Opener">
	<ShowOn>
		<string>ContextMenu</string>
	</ShowOn>
    <ImagesDescription>
        <ResourceAssembly>
            <Assembly>AdminUI.UIResources.dll</Assembly>
            <Type>Microsoft.ConfigurationManagement.AdminConsole.UIResources.Properties.Resources.resources</Type>
        </ResourceAssembly>
        <ImageResourceName>Tool</ImageResourceName>
    </ImagesDescription>
	<Executable>
		<FilePath>C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe</FilePath>
		<Parameters>-ExecutionPolicy Bypass -File "' + $MyInvocation.MyCommand.Path + '" -Hostname ##SUB:Name##</Parameters>
	</Executable>
</ActionDescription>'

$global:activeLogProgram = $activeLogProgram

Function Open-LogFile ([String] $Action) {
    # Get action from Hash Table, and throw error if it does not exist
    $actionHandler = $logfileTable.GetEnumerator() | Where-Object {$_.Key -eq $action}
    If (!$actionHandler) {
        Invoke-MessageBox -Message "Action '$action' can not be found in Hash Table"
        Return
    }

    # Assign values from Hash Table
    $logfilePath = "\\$hostname\$($actionHandler.Value.path)"
    $logfiles = $actionHandler.Value.logfiles

    # Check if logfile path  is accessible
    If (!(Test-Path -Path $logfilePath)) {
        Invoke-MessageBox -Message "'$logfilePath' is not accessible!"
        Return
    }

    Invoke-LogProgram -Path $logfilePath -Files $logfiles
}

Function Invoke-CMTrace ([String] $Path, [Array] $Files) {
    # Check if CMTrace exists
    If (!(Test-Path -Path $cmtrace)) {
        Invoke-MessageBox -Message "'$cmtrace' is not accessible!"
        Return
    }

    # Check if CMTrace was started at least once. This is needed to make sure that the initial FTA PopUp doesn't appear.
    If (!(Test-Path -Path 'HKCU:\Software\Microsoft\Trace32')) {
        Invoke-MessageBox -Message "CMTrace needs be started at least once. Click 'OK' to launch CMTrace, confirm all dialogs and try again." -Icon 'Exclamation'

        # Empty files array to start a single CMTrace Instance
        $files = @()
    }

    # Write current path in Registry
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Trace32' -Value $path -Name 'Last Directory' -Force

    # Check if multiple files were specified
    If ($files.Count -gt 1) {
        # Start CMTrace and wait until it's open
        Start-Process -FilePath $cmtrace
        Start-Sleep -Milliseconds $cmtraceActionDelay

        # Send CTRL+O to open the open file dialog
        $shellObj.SendKeys('^o')
        Start-Sleep -Milliseconds $cmtraceActionDelay

        # Write logfiles name in CMTrace format, "Log1" "Log2" "Log3" etc.
        $shellObj.SendKeys('"' + [String]::Join('" "', $files) + '"')

        # check if logfile merging is not disabled
        If (!$disableLogfileMerging) {
            # Navigate to Merge checkbox and enable it
            $shellObj.SendKeys('{TAB}{TAB}{TAB}{TAB}{TAB}')
            $shellObj.SendKeys(' ')
        }

        # Send ENTER
        $shellObj.SendKeys('{ENTER}')

        # Wait until log file is loaded
        Start-Sleep -Milliseconds $cmtraceActionDelay

        # Send CTRL + END to scroll to the bottom
        $shellObj.SendKeys('^{END}')

        # Set Empty path in registry
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Trace32' -Value '' -Name 'Last Directory' -Force
    }
    # Check if one file was specified
    ElseIf ($files.Count -eq 1) {
        # Build full logfile path
        $fullLogfilePath = $path + '\' + [String]::Join(" ", $files)

        # Check if Logfile exists
        If (!(Test-Path -Path $fullLogfilePath)) {
            Invoke-MessageBox -Message "'$fullLogfilePath' is not accessible!"
            Return
        }

        # Open Logfile in CMTrace
        Start-Process -FilePath $cmtrace -ArgumentList $fullLogfilePath

        # Wait until log file is loaded
        Start-Sleep -Milliseconds $cmtraceActionDelay

        # Send CTRL + END to scroll to the bottom
        $shellObj.SendKeys('^{END}')

        # Set Empty path in registry
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Trace32' -Value '' -Name 'Last Directory' -Force
    }
    # Check if no file was specified
    Else {
        # Open CMTrace
        Start-Process -FilePath $cmtrace
    }

    # Check WindowStyle. NOTE: CMTrace can't be launched using the native 'WindowStyle' Attribute via Start-Process above.
    Switch ($windowStyle) {
        'Minimized' {$shellObj.SendKeys('% n')}
        'Maximized' {$shellObj.SendKeys('% x')}
    }

}

Function Invoke-CMLogViewer ([String] $Path, [Array] $Files) {
    # Check if CMLogViewer exists
    If (!(Test-Path -Path $cmLogViewer)) {
        Invoke-MessageBox -Message "'$cmLogViewer' is not accessible!"
        Return
    }
    # Check if log files were specified
    If ($Files -gt 1) {
        # Check if History Logfiles are disabled
        If (!$disableHistoryLogFiles) {
            $discoveredFiles = @()
            # Go through each log file
            foreach ($file in $files) {
                # Search for history log files
                Get-ChildItem -Path $path -Filter ('*' + $file.TrimEnd('.log') + '*') | ForEach-Object {
                    $discoveredFiles += $_.Name
                }
            }

            # assign new log files array
            $files = $discoveredFiles
        }

        # Build full logfile path: "Path\Log1" "Path\Log2" "Path\Log3" etc.
        foreach ($file in $files) {
            $fullLogfilePath += '"' + $Path + '\' + $file + '" '
        }

        # Open Logfile in CMLogViewer
        Start-Process -FilePath $cmLogViewer -ArgumentList $fullLogfilePath -WindowStyle $windowStyle
    }
    # Check if no files were specified
    Else {
        # Open CMLogViewer
        Start-Process -FilePath $cmLogViewer -WindowStyle $windowStyle
    }
}

Function Invoke-LogProgram([String] $Path, [Array] $Files) {
    If ($global:activeLogProgram -eq 'CMTrace') {
        Invoke-CMTrace -Path $path -Files $files
    }
    ElseIf ($global:activeLogProgram -eq 'CMLogViewer') {
        Invoke-CMLogViewer -Path $path -Files $files
    }
}

Function Open-Path ([String] $Path) {
    # build full path
    $logfilePath = "\\$hostname\$Path"

    # Check if path is accessible
    If (!(Test-Path -Path $logfilePath)) {
        Invoke-MessageBox -Message "'$logfilePath' is not accessible!"
    } Else {
        # Open File explorer
        Start-Process -FilePath 'C:\Windows\explorer.exe' -ArgumentList $logfilePath -WindowStyle $windowStyle
    }
}

Function Invoke-ClientAction([String[]] $Action, [String] $LogFile) {
    Try {
        # Set ErrorActionPreference to stop, otherwise Try/Catch won't have an effect on Invoke-WmiMethod
        $ErrorActionPreference = 'Stop'

        foreach ($singleAction in $action) {
            # Trigger specified WMI Method on Client. Note: Invoke-Cim Command doesn't work here --> Error 0x8004101e
            If ($hostnameIsRemote) {
                Invoke-WmiMethod -ComputerName $hostname -Namespace 'root\CCM' -Class 'SMS_Client' -Name 'TriggerSchedule' -ArgumentList ('{' + $singleAction + '}') | Out-Null
            }
            Else {
                Invoke-WmiMethod -Namespace 'root\CCM' -Class 'SMS_Client' -Name 'TriggerSchedule' -ArgumentList ('{' + $singleAction + '}') | Out-Null
            }
        }

        # Display message box
        Invoke-MessageBox -Message 'The Client Action has been executed' -Icon 'Information'

        # Open corresponding log file
        If ($enableAutoLogLaunch -and $logFile -ne '') {
            Open-LogFile -Action $LogFile
        }
    }
    Catch {
        # Display error message in case of a failure and return to the client action menu
        $errorMessage = $_.Exception.Message
        Invoke-MessageBox -Message "Unable to execute the specified Client Action.`n`n$errorMessage"
    }
}

Function Invoke-MessageBox([String] $Message, [String] $Icon = 'Critical', [String] $Button = "OKOnly") {
    Return [Microsoft.VisualBasic.Interaction]::MsgBox($message, "$button,MsgBoxSetForeground,$icon", 'ConfigMgr LogFile Opener')
}

Function Get-ClientVersionString {
    Try {
        # Get client version from WMI
        If ($hostnameIsRemote) {
            $clientVersion = Get-CimInstance -ComputerName $hostname -Namespace 'root\CCM' -ClassName 'SMS_Client' -Property 'ClientVersion' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty 'ClientVersion'
        }
        Else {
            $clientVersion = Get-CimInstance -Namespace 'root\CCM' -ClassName 'SMS_Client' -Property 'ClientVersion' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty 'ClientVersion'
        }

        # Extract build number from client version
        $ccmBuildNo = $clientVersion.Split('.')[2]

        # Get BuildNo String from hash table
        $ccmBuildNoHandler = $ccmBuildNoTable.GetEnumerator() | Where-Object {$_.Key -eq $ccmBuildNo}

        # Build client version string
        If ($ccmBuildNoHandler) {
            $clientVersionString = "$($ccmBuildNoHandler.Value) ($clientVersion)"
        }
        Else {
            $clientVersionString = $clientVersion
        }

        Return $clientVersionString
    }
    Catch {
        Return 'n/a'
    }
}

Function Get-OperatingSystemData {
    $data = @{}
    [uint32]$ubrKey = 2147483650 # HKEY_LOCAL_MACHINE
    $ubrSubKeyName = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $ubrValueName = 'UBR'

    Try {
        # Get operating system data from WMI
        If ($hostnameIsRemote) {
            $osCimObject = Get-CimInstance -ComputerName $hostname -ClassName 'Win32_OperatingSystem' -Property Caption,Version,OSArchitecture,LastBootUpTime -ErrorAction SilentlyContinue
            $sysCimObject = Get-CimInstance -ComputerName $hostname -ClassName 'Win32_ComputerSystem' -Property Domain -ErrorAction SilentlyContinue
            $ubrCimObject = Invoke-CimMethod -ComputerName $hostname -Namespace "root\default" -ClassName StdRegProv -MethodName GetDwordValue -Arguments @{hDefKey = $ubrKey; sSubKeyName = $ubrSubKeyName; sValueName = $ubrValueName} -ErrorAction SilentlyContinue
        }
        Else {
            $osCimObject = Get-CimInstance -ClassName 'Win32_OperatingSystem' -Property Caption,Version,OSArchitecture,LastBootUpTime -ErrorAction SilentlyContinue
            $sysCimObject = Get-CimInstance -ClassName 'Win32_ComputerSystem' -Property Domain -ErrorAction SilentlyContinue
            $ubrCimObject = Invoke-CimMethod -Namespace "root\default" -ClassName StdRegProv -MethodName GetDwordValue -Arguments @{hDefKey = $ubrKey; sSubKeyName = $ubrSubKeyName; sValueName = $ubrValueName} -ErrorAction SilentlyContinue
        }

        # Remove unneeded things from OS caption
        $data.osString = "$($osCimObject.Caption.Replace('Microsoft', '').Trim())"
        $data.osString = $data.osString.Replace('Enterprise', 'Ent.')
        $data.osString = $data.osString.Replace('Standard', 'Std.')

        # Add Architecture if this is a non Server Operating System
        If ($data.osString -notmatch "Windows Server*") {
            $data.osString = $data.osString + " $($osCimObject.OSArchitecture)"
        }

        # Add BuildNo
        $data.osString = $data.osString + " ($($osCimObject.Version).$($ubrCimObject.uValue))"

        $data.lastBootTime = Get-Date $osCimObject.LastBootUpTime -Format $dateTimePattern

        $data.domain = $sysCimObject.Domain

        Return $data
    }
    Catch {
        $data.osString = 'n/a'
        $data.lastBootTime = 'n/a'
        $data.domain = 'n/a'

        Return $data
    }
}

Function Get-ModelString {
    Try {
        # Get client version from WMI
        If ($hostnameIsRemote) {
            $cimObject = Get-CimInstance -ComputerName $hostname -ClassName 'Win32_ComputerSystemProduct' -Property Vendor,Version -ErrorAction SilentlyContinue
        }
        Else {
            $cimObject = Get-CimInstance -ClassName 'Win32_ComputerSystemProduct' -Property Vendor,Version -ErrorAction SilentlyContinue
        }

        If ($cimObject.Vendor -eq "HP") {
            # Special Handling for HP Devices
            If ($hostnameIsRemote) {
                $cimObject2 = Get-CimInstance -ComputerName $hostname -ClassName 'Win32_ComputerSystem' -Property Model -ErrorAction SilentlyContinue
            }
            Else {
                $cimObject2 = Get-CimInstance -ClassName 'Win32_ComputerSystem' -Property Model -ErrorAction SilentlyContinue
            }

            Return "$($cimObject.Vendor) $($cimObject2.Model)"

        }
        Else {
            Return "$($cimObject.Vendor) $($cimObject.Version)"
        }
    }
    Catch {
        Return 'n/a'
    }
}

Function Get-RecentLog {
    $logfilePath = "\\$hostname\$clientLogFilesDir"

    # Check if CCM Logfile path is accessible
    If (!(Test-Path -Path $logfilePath)) {
        Invoke-MessageBox -Message "Unable to access '$logfilePath'."
        Return
    }

    # Check if CCM Logfile path contains any logs
    If (!(Get-ChildItem $logfilePath).Count) {
        Invoke-MessageBox -Message "Log directory '$logfilePath' doesn't contain any Log files." -Icon 'Exclamation'
        Return
    }

    # Get Recent Log Files
    $logs = Get-ChildItem $logfilePath | Sort-Object LastWriteTime -Descending | Select-Object Name,LastWriteTime -First $RecentLogLimit

    $list = @{}
    $listIndex = 1
    foreach ($log in $logs) {
        # Add Log data into hash table
        $list[$listIndex] += @{
            'Name' = $log.Name
            'Path' = $logfilePath
            'LastWriteTime' = Get-Date $log.LastWriteTime -Format $dateTimePattern
        }
        $listIndex++
    }

    # Return sorted Hash Table
    Return $list.GetEnumerator() | Sort-Object -Property Name
}

Function Set-ActiveLogProgram {
    Switch ($global:activeLogProgram) {
        'CMTrace' {
            $global:activeLogProgram = 'CMLogViewer'
        }
        'CMLogViewer' {
            $global:activeLogProgram = 'CMTrace'
        }
    }
}

Function Test-ConsoleInstallation {
    If (Test-Path Env:SMS_ADMIN_UI_PATH) {
        Return $true
    }
    Else {
        Return $false
    }
}

Function Test-Elevation {
    Return (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Function Install-ConsoleExtension {
    If (!(Test-ConsoleInstallation)) {
        Invoke-MessageBox -Message "No ConfigMgr Console found on this System."
        Return
    }

    If (!(Test-Elevation)) {
        Invoke-MessageBox -Message "Please run this tool as an Administrator to install the Console Extension."
        Return
    }

    foreach ($guid In $consoleExtensionActionGUIDs) {
        # Build path from GUID
        $path = "$($env:SMS_ADMIN_UI_PATH)..\..\..\XmlStorage\Extensions\Actions\$guid"

        # Create Actions Folder if needed
        If (!(Test-Path $path)) {
            New-Item -ItemType Directory -Path $path | Out-Null
        }

        # Populate Extension XML into Actions Path
        $consoleExtensionXmlContent | Out-File "$path\$consoleExtensionXmlFile" -Force -Encoding UTF8
    }

    Invoke-MessageBox -Message "Console Extension successfully installed/updated. Please restart all open ConfigMgr Consoles." -Icon Information
}

Function Remove-ConsoleExtension {
    If (!(Test-Elevation)) {
        Invoke-MessageBox -Message "Please run this tool as an Administrator to remove the Console Extension."
        Return
    }

    foreach ($guid In $consoleExtensionActionGUIDs) {
        # Build file path from GUID
        $file = "$($env:SMS_ADMIN_UI_PATH)..\..\..\XmlStorage\Extensions\Actions\$guid\$consoleExtensionXmlFile"

        # Remove Extension XML if exists
        If (Test-Path $file) {
            Remove-Item $file -Force
        }
    }

    Invoke-MessageBox -Message "Console Extension successfully removed. Please restart all open ConfigMgr Consoles." -Icon Information
}

Function Invoke-ToolUpdater {
    # Get XML Document Object
    $xml = New-Object System.Xml.XmlDocument

    # Try to load updater options
    Try {
        $xml.Load($updateUrl)
        $currentVersion = $xml.options.currentVersion
        $downloadPage = $xml.options.downloadPage.'#cdata-section'
    }
    Catch {
        Return $false
    }

    If ([System.Version] $toolVersion -lt [System.Version] $currentVersion) {
        $response = [Microsoft.VisualBasic.Interaction]::MsgBox("Version $currentVersion of ConfigMgr LogFile Opener is available. Do you want to Download the latest version?", "YesNo,MsgBoxSetForeground,Information", "ConfigMgr LogFile Opener - $toolVersion")

        If ($response -eq "Yes") {
            Start-Process $downloadPage
        }
    }
}

Function Stop-CcmExec {
    If ((Invoke-MessageBox -Message "Do you really want to stop the ConfigMgr Client service on $($hostname)?" -Icon Information -Button YesNo) -eq "Yes") {
        Try {
            If ($hostnameIsRemote) {
                $serviceObject = Get-Service -Name CcmExec -ComputerName $hostname | Stop-Service -PassThru
            }
            Else {
                $serviceObject = Get-Service -Name CcmExec | Stop-Service -PassThru
            }

            If ($serviceObject.Status -eq "Stopped") {
                Invoke-MessageBox -Message "ConfigMgr Client service successfully stopped on $($hostname)." -Icon Information

                # Open corresponding log file
                If ($enableAutoLogLaunch) {
                    Open-LogFile -Action 'ccmexec'
                }
            }
            Else {
                Invoke-MessageBox -Message "Unable to stop the ConfigMgr Client service on $($hostname).`n`nCurrent service status: $($service.Status)"
            }
        }
        Catch {
            # Display error message in case of a failure and return to the client action menu
            $errorMessage = $_.Exception.Message
            Invoke-MessageBox -Message "Unable to stop the ConfigMgr Client service on $($hostname).`n`n$errorMessage"
        }
    }
}

Function Start-CcmExec {
    $ErrorActionPreference = 'Stop'

    Try {
        If ($hostnameIsRemote) {
            $serviceObject = Get-Service -Name CcmExec -ComputerName $hostname | Start-Service -PassThru
        }
        Else {
            $serviceObject = Get-Service -Name CcmExec | Start-Service -PassThru
        }

        If ($serviceObject.Status -eq "Running") {
            Invoke-MessageBox -Message "ConfigMgr Client service successfully started on $($hostname)." -Icon Information

            # Open corresponding log file
            If ($enableAutoLogLaunch) {
                Open-LogFile -Action 'ccmexec'
            }
        }
        Else {
            Invoke-MessageBox -Message "Unable to start the ConfigMgr Client service on $($hostname).`n`nCurrent service status: $($service.Status)"
        }
    }
    Catch {
        # Display error message in case of a failure and return to the client action menu
        $errorMessage = $_.Exception.Message
        Invoke-MessageBox -Message "Unable to start the ConfigMgr Client service on $($hostname).`n`n$errorMessage"
    }
}

Function Restart-CcmExec {
    $ErrorActionPreference = 'Stop'

    If ((Invoke-MessageBox -Message "Do you really want to restart the ConfigMgr Client service on $($hostname)?" -Icon Information -Button YesNo) -eq "Yes") {
        Try {
            If ($hostnameIsRemote) {
                $serviceObject = Get-Service -Name CcmExec -ComputerName $hostname | Restart-Service -PassThru
            }
            Else {
                $serviceObject = Get-Service -Name CcmExec | Restart-Service -PassThru
            }

            If ($serviceObject.Status -eq "Running") {
                # Open corresponding log file
                If ($enableAutoLogLaunch) {
                    Open-LogFile -Action 'ccmexec'
                }

                Invoke-MessageBox -Message "ConfigMgr Client service successfully restarted on $($hostname)." -Icon Information
            }
            Else {
                Invoke-MessageBox -Message "Unable to restart the ConfigMgr Client service on $($hostname).`n`nCurrent service status: $($service.Status)"
            }
        }
        Catch {
            # Display error message in case of a failure and return to the client action menu
            $errorMessage = $_.Exception.Message
            Invoke-MessageBox -Message "Unable to restart the ConfigMgr Client service on $($hostname).`n`n$errorMessage"
        }
    }
}

Function Invoke-ConfigurationBaselineEvaluation {
    $ErrorActionPreference = 'Stop'

    Try {
        $baselineCount = 0
        If ($hostnameIsRemote) {
            Get-CimInstance -ComputerName $hostname -ClassName 'SMS_DesiredConfiguration' -Namespace 'root\ccm\dcm' | ForEach-Object {
                ([wmiclass]"\\$hostname\root\ccm\dcm:SMS_DesiredConfiguration").TriggerEvaluation($_.Name, $_.Version) | Out-Null
                $baselineCount++
            }
        }
        Else {
            Get-CimInstance -ClassName 'SMS_DesiredConfiguration' -Namespace 'root\ccm\dcm' | ForEach-Object {
                ([wmiclass]"root\ccm\dcm:SMS_DesiredConfiguration").TriggerEvaluation($_.Name, $_.Version) | Out-Null
                $baselineCount++
            }
        }

        If ($baselineCount -eq 1) {
            $messageText = "$baselineCount Configuration Baseline has been reevaluated on $($hostname)."
        } Else {
            $messageText = "$baselineCount Configuration Baselines have been reevaluated on $($hostname)."
        }

        Invoke-MessageBox -Message $messageText -Icon Information
     }
     Catch {
        # Display error message in case of a failure and return to the client action menu
        $errorMessage = $_.Exception.Message
        Invoke-MessageBox -Message "Unable to reevaluate Configuration Baselines on $($hostname).`n`n$errorMessage"
     }
}

Function Invoke-CcmEval {
    $ErrorActionPreference = 'Stop'

    Try {
        If ($hostnameIsRemote) {
            # Note: Native ScheduledTask Cmdlets are only working on Win8.1 / Srv 2012 R2 or newer
            # Create PowerShell Session for target computer
            $psSession = New-PSSession -ComputerName $hostname

            # Run ccmeeval Task on target computer
            Invoke-Command -Session $psSession -ScriptBlock { schtasks /Run /TN "\Microsoft\Configuration Manager\Configuration Manager Health Evaluation" } | Out-Null

            # Terminate PowerShell Session
            Remove-PSSession -Session $psSession
        }
        Else {
            schtasks /Run /TN "\Microsoft\Configuration Manager\Configuration Manager Health Evaluation" > $null
        }

        Invoke-MessageBox -Message "ConfigMgr Client Evaluation has been executed on $($hostname)." -Icon Information

        # Open corresponding log file
        If ($enableAutoLogLaunch) {
            Open-LogFile -Action 'ccmsetupeval'
        }
    }
    Catch {
        # Display error message in case of a failure and return to the client action menu
        $errorMessage = $_.Exception.Message
        Invoke-MessageBox -Message "Unable to run ConfigMgr Client Health Evaluation on $($hostname).`n`n$errorMessage"

        Return $false
    }
}

Function Update-SoftwareUpdateComplianceState {
    $ErrorActionPreference = 'Stop'

    Try {
        If ($hostnameIsRemote) {
            # Create PowerShell Session for target computer
            $psSession = New-PSSession -ComputerName $hostname

            # Refresh Software Update Compliance State
            Invoke-Command -Session $psSession -ScriptBlock {
                $updatesStore = New-Object -ComObject Microsoft.CCM.UpdatesStore
                $updatesStore.RefreshServerComplianceState()
            } | Out-Null

            # Terminate PowerShell Session
            Remove-PSSession -Session $psSession
        } Else {
            $updatesStore = New-Object -ComObject Microsoft.CCM.UpdatesStore
            $updatesStore.RefreshServerComplianceState()
        }

        Invoke-MessageBox -Message "Software Update Compliance State has been successfully refreshed on $($hostname)." -Icon Information

        # Open corresponding log file
        If ($enableAutoLogLaunch) {
            Open-LogFile -Action 'ccmupdate'
        }
    }
    Catch {
        # Display error message in case of a failure and return to the client action menu
        $errorMessage = $_.Exception.Message
        Invoke-MessageBox -Message "Unable to run refresh Software Update Compliance State on $($hostname).`n`n$errorMessage"

        Return $false
    }
}

Function Get-IPAddressString {
    $ErrorActionPreference = 'Stop'

    # Check if hostname is an ip address

    Try {
        If ($hostname -match '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b') {
            # If an IP address was used for the device connection then don't perform a dns lookup
            $ipAddress = $hostname
        }
        Else {
            # Determine Client IP address via DNS
            # TODO: This is currently limited to IPv4 and a single ip address
            $ipAddress = Resolve-DnsName $hostname | Where-Object {$_.Type -eq "A"} | Select-Object -ExpandProperty IPAddress -First 1
        }

        # Determine adapter type
        If ($hostnameIsRemote) {
            $netAdapterName = Get-CimInstance -ComputerName $hostname -ClassName Win32_NetworkAdapterConfiguration | Where-Object {$_.IPAddress -eq $ipAddress} -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Description
            $adapterTypeID = Get-CimInstance -ComputerName $hostname -Namespace "root/WMI" -Class MSNdis_PhysicalMediumType -ErrorAction SilentlyContinue | Where-Object {$_.InstanceName -eq $netAdapterName} | Select-Object -ExpandProperty NdisPhysicalMediumType
        }
        Else {
            $netAdapterName = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object {$_.IPAddress -eq $ipAddress} -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Description
            $adapterTypeID = Get-CimInstance -Namespace "root/WMI" -Class MSNdis_PhysicalMediumType -ErrorAction SilentlyContinue | Where-Object {$_.InstanceName -eq $netAdapterName} | Select-Object -ExpandProperty NdisPhysicalMediumType
        }

        $adapterType = ""
        Switch ($adapterTypeID) {
            0 {$adapterType = 'LAN'}
            9 {$adapterType = 'WLAN'}
            8 {$adapterType = 'WWAN'}
        }

        If ($adapterType -eq "") {
            Return "$ipAddress"
        }
        Else {
            Return "$ipAddress ($adapterType)"
        }

    }
    Catch {
        return 'n/a'
    }
}

Function Invoke-CcmRepair {
    $ErrorActionPreference = 'Stop'

    If ((Invoke-MessageBox -Message "Do you really want to repair the ConfigMgr Client on $($hostname)?" -Icon Information -Button YesNo) -eq "Yes") {
        Try {
            # Connect to WMI
            If ($hostnameIsRemote) {
                $wmi = [wmiclass] "\\$hostname\root\ccm:sms_client"
            }
            Else {
                $wmi = [wmiclass] "\root\ccm:sms_client"
            }

            # Trigger Client Repair
            If ($wmi.RepairClient()) {
                Invoke-MessageBox -Message "ConfigMgr Client Repair has been successfully started on $($hostname)." -Icon Information

                # Open corresponding log file
                If ($enableAutoLogLaunch) {
                    Open-LogFile -Action 'ccmsetup'
                }
            }
            Else {
                Invoke-MessageBox -Message "Unable to start the ConfigMgr Client Repair on $($hostname)."
            }
        }
        Catch {
            # Display error message in case of a failure and return to the client action menu
            $errorMessage = $_.Exception.Message
            Invoke-MessageBox -Message "Unable to start the ConfigMgr Client Repair on $($hostname).`n`n$errorMessage"
        }
    }
}

Function Invoke-CcmPolicyReset {
    $ErrorActionPreference = 'Stop'

    If ((Invoke-MessageBox -Message "Do you really want to reset the ConfigMgr Policies on $($hostname)?" -Icon Information -Button YesNo) -eq "Yes") {
        Try {
            # Connect to WMI
            If ($hostnameIsRemote) {
                $wmi = [wmiclass] "\\$hostname\root\ccm:sms_client"
            }
            Else {
                $wmi = [wmiclass] "\root\ccm:sms_client"
            }

            # Trigger Policy Reset
            If ($wmi.ResetPolicy()) {
                Invoke-MessageBox -Message "ConfigMgr Policies have been successfully reseted on $($hostname)." -Icon Information

                # Open corresponding log file
                If ($enableAutoLogLaunch) {
                    Open-LogFile -Action 'ccmpolicy'
                }
            }
            Else {
                Invoke-MessageBox -Message "Unable to reset the ConfigMgr Policies on $($hostname)."
            }
        }
        Catch {
            # Display error message in case of a failure and return to the client action menu
            $errorMessage = $_.Exception.Message
            Invoke-MessageBox -Message "Unable to reset the ConfigMgr Policies on $($hostname).`n`n$errorMessage"
        }
    }
}


Function Write-MenuHeader {
    Clear-Host
    Write-Output ' ###########################################################'
    Write-Output ' #                                                         #'
    Write-Output ' #                ConfigMgr LogFile Opener                 #'
    Write-Output " #                          $toolVersion                          #"
    Write-Output ' #                     msitproblog.com                     #'
    Write-Output ' #                                                         #'
    Write-Output ' ###########################################################'
    Write-Output ''
}

Function Invoke-MainMenu ([switch] $ResetHostname, [switch] $FirstLaunch) {
    # Reset Hostname if needed
    If ($resetHostname) {
        $hostname = ''
    }

    # Perform update check
    If ($firstLaunch -and $disableUpdater -eq $false) {
        Invoke-ToolUpdater
    }

    If ($hostname -eq '') {
        # Get targeted Computer
        Write-MenuHeader
        $hostname = (Read-Host -Prompt ' Enter name of Device').ToUpper()

        # Assign local hostname if no hostname was specified
        If ($hostname -eq '') {
            $hostname = ($env:COMPUTERNAME).ToUpper()

            # Notify user about the assignment of the local hostname
            Invoke-MessageBox -Message "The local device name '$hostname' has been assigned." -Icon 'Information' | Out-Null
        }
    }

    # Perform the following checks / tasks only if the hostname was changed or on first launch
    If ($resetHostname -or $firstLaunch) {
        # Check if the Device name only contains numbers
        If ($hostname -match '^[0-9]*$') {
            Invoke-MessageBox -Message "The specified Device name '$hostname' is not valid."
            Invoke-MainMenu -ResetHostname
        }

        # Check if Device is pingable
        If (!(Test-Connection -ComputerName $hostname -BufferSize 8 -Count 1 -Quiet)) {
            Invoke-MessageBox -Message "The specified Device name '$hostname' is not online."
            Invoke-MainMenu -ResetHostname
        }

        # Check if host is online
        If (!(Test-Path -Path "\\$hostname\C$")) {
            Invoke-MessageBox -Message "The specified Device '$hostname' is not accessible."
            Invoke-MainMenu -ResetHostname
        }

        # Check if the specified host is the local device
        If ($hostname.Split('.')[0] -eq $env:COMPUTERNAME) {
            $hostnameIsRemote = $false
        }
        Else {
            $hostnameIsRemote = $true
        }

        # Get Client Version from specified Device
        $clientVersionString = Get-ClientVersionString

        # Get Operating System data from specified Device
        $osData = Get-OperatingSystemData
        $osString = $osData.osString
        $lastBootTime = $osData.lastBootTime
        $domain = $osData.Domain

        # Get Model from specified Device
        $modelString = Get-ModelString

        # Get ip address information
        $ipAddressString = Get-IPAddressString
    }

    # Write main Menu
    Write-MenuHeader
    $color = $host.ui.RawUI.ForegroundColor
    $host.ui.RawUI.ForegroundColor = "Yellow"
    Write-Output " Connected Device : $hostname ($domain)"
    $host.ui.RawUI.ForegroundColor = $color
    Write-Output " Client Hardware  : $modelString"
    Write-Output " Operating System : $osString"
    Write-Output " ConfigMgr Client : $clientVersionString"
    Write-Output " Boot Time        : $lastBootTime"
    Write-Output " IP Address       : $ipAddressString"
    Write-Output ''
    Write-Output ' --- Logs --------------------------------------------------'
    Write-Output ' [1] ccmsetup.log'
    Write-Output ' [2] ScanAgent.log, Updates*.log, WUAHandler.log'
    Write-Output ' [3] AppDiscovery.log'
    Write-Output ' [4] AppEnforce.log'
    Write-Output ' [5] execmgr.log'
    Write-Output ' [6] CcmExec.log'
    Write-Output ' [7] ClientIDManagerStartup.log'
    Write-Output ' [8] Policy*.log, StatusAgent.log'
    Write-Output ' [9] EndpointProtectionAgent.log'
    Write-Output ' [10] CAS.log, CIDownloader.log, DataTransferService.log'
    Write-Output ' [11] ccmsetup-ccmeval.log'
    Write-Output ' [12] InventoryAgent.log, InventoryProvider.log'
    Write-Output ' [13] smsts.log'
    Write-Output ' [14] StateMessage.log'
    Write-Output ' [15] WindowsUpdate.log'
    Write-Output ' [16] setupact.log'
    Write-Output ' [17] setuperr.log'
    Write-Output ' [18] MpCmdRun.log'
    Write-Output ''
    Write-Output ' --- File Explorer -----------------------------------------'
    Write-Output ' [50] C:\Windows\CCM\Logs'
    Write-Output ' [51] C:\Windows\ccmcache'
    Write-Output ' [52] C:\Windows\ccmsetup'
    Write-Output ' [53] C:\Windows\Logs\Software'
    Write-Output ' [54] C:\Windows\Temp'
    Write-Output ''
    Write-Output ' --- Options -----------------------------------------------'
    Write-Output ' [93] Show recent logs     [94] Refresh Device data'
    Write-Output " [96] Client Actions       [97] Start $global:activeLogProgram"
    Write-Output " [98] Change Device        [99] Exit"
    Write-Output ' [X] Settings'
    Write-Output ''

    Switch (Read-Host -Prompt ' Please select an Action') {
        1 {Open-LogFile -Action 'ccmsetup'}
        2 {Open-LogFile -Action 'ccmupdate'}
        3 {Open-LogFile -Action 'ccmappdiscovery'}
        4 {Open-LogFile -Action 'ccmappenforce'}
        5 {Open-LogFile -Action 'ccmexecmgr'}
        6 {Open-LogFile -Action 'ccmexec'}
        7 {Open-LogFile -Action 'ccmstartup'}
        8 {Open-LogFile -Action 'ccmpolicy'}
        9 {Open-LogFile -Action 'ccmepagent'}
        10 {Open-LogFile -Action 'ccmdownload'}
        11 {Open-LogFile -Action 'ccmsetupeval'}
        12 {Open-LogFile -Action 'ccminventory'}
        13 {Open-LogFile -Action 'ccmsmsts'}
        14 {Open-LogFile -Action 'ccmstatemessage'}
        15 {Open-LogFile -Action 'winupdate'}
        16 {Open-LogFile -Action 'winservicingsetupact'}
        17 {Open-LogFile -Action 'winservicingsetuperr'}
        18 {Open-LogFile -Action 'scepmpcmdrun'}
        50 {Open-Path -Path 'C$\Windows\CCM\Logs'}
        51 {Open-Path -Path 'C$\Windows\ccmcache'}
        52 {Open-Path -Path 'C$\Windows\ccmsetup'}
        53 {Open-Path -Path 'C$\Windows\Logs\Software'}
        54 {Open-Path -Path 'C$\Windows\Temp'}
        93 {Invoke-RecentLogMenu}
        94 {Invoke-MainMenu -FirstLaunch}
        96 {Invoke-ClientActionMenu}
        97 {Invoke-LogProgram}
        98 {Invoke-MainMenu -ResetHostname}
        99 {Clear-Host; Exit}
        'X' {Invoke-SettingsMenu}
    }

    Invoke-MainMenu
}

Function Invoke-ClientActionMenu {
    Write-MenuHeader
    $color = $host.ui.RawUI.ForegroundColor
    $host.ui.RawUI.ForegroundColor = "Yellow"
    Write-Output " Connected Device : $hostname ($domain)"
    $host.ui.RawUI.ForegroundColor = $color
    Write-Output " Client Hardware  : $modelString"
    Write-Output " Operating System : $osString"
    Write-Output " ConfigMgr Client : $clientVersionString"
    Write-Output " Boot Time        : $lastBootTime"
    Write-Output " IP Address       : $ipAddressString"
    Write-Output ''
    Write-Output ' --- Default Actions ---------------------------------------'
    Write-Output ' [1] Application Deployment Evaluation Cycle'
    Write-Output ' [2] Discovery Data Collection Cycle'
    Write-Output ' [3] File Collection Cycle'
    Write-Output ' [4] Hardware Inventory Cycle'
    Write-Output ' [5] Machine Policy Retrieval & Evaluation Cycle'
    Write-Output ' [6] Software Inventory Cycle'
    Write-Output ' [7] Software Metering Usage Report Cycle'
    Write-Output ' [8] Software Updates Assignments Evaluation Cycle'
    Write-Output ' [9] Software Update Scan Cycle'
    Write-Output ' [10] Windows Installers Source List Update Cycle'
    Write-Output ' [11] State Message Refresh'
    Write-Output ''
    Write-Output ' --- Advanced Actions --------------------------------------'
    Write-Output ' [20] Reevaluate Endpoint protection deployment'
    Write-Output ' [21] Reevaluate Endpoint protection policies'
    Write-Output ' [22] Reevaluate Configuration Baselines'
    Write-Output ' [23] Refresh Software Update Compliance State'
    Write-Output ' [24] Reset Policies'
    Write-Output ''
    Write-Output ' --- Client Tasks ------------------------------------------'
    Write-Output ' [40] Start ConfigMgr Client'
    Write-Output ' [41] Stop ConfigMgr Client'
    Write-Output ' [42] Restart ConfigMgr Client'
    Write-Output ' [43] Run ConfigMgr Client Health Evaluation'
    Write-Output ' [44] Repair ConfigMgr Client'
    Write-Output ''
    Write-Output ' --- Options -----------------------------------------------'
    Write-Output " [98] Back to Main Menu    [99] Exit"
    Write-Output ''

    Switch (Read-Host -Prompt ' Please select an Action') {
        1 {Invoke-ClientAction -Action '00000000-0000-0000-0000-000000000121' -LogFile 'ccmappdiscovery'}
        2 {Invoke-ClientAction -Action '00000000-0000-0000-0000-000000000003'}
        3 {Invoke-ClientAction -Action '00000000-0000-0000-0000-000000000010'}
        4 {Invoke-ClientAction -Action '00000000-0000-0000-0000-000000000001' -LogFile 'ccminventory'}
        5 {Invoke-ClientAction -Action '00000000-0000-0000-0000-000000000021','00000000-0000-0000-0000-000000000022' -LogFile 'ccmpolicy'}
        6 {Invoke-ClientAction -Action '00000000-0000-0000-0000-000000000002'}
        7 {Invoke-ClientAction -Action '00000000-0000-0000-0000-000000000031'}
        8 {Invoke-ClientAction -Action '00000000-0000-0000-0000-000000000108' -LogFile 'ccmupdate'}
        9 {Invoke-ClientAction -Action '00000000-0000-0000-0000-000000000113'-LogFile 'ccmupdate'}
        10 {Invoke-ClientAction -Action '00000000-0000-0000-0000-000000000032' }
        11 {Invoke-ClientAction -Action '00000000-0000-0000-0000-000000000111' -LogFile 'ccmstatemessage'}
        20 {Invoke-ClientAction -Action '00000000-0000-0000-0000-000000000221' -LogFile 'ccmepagent'}
        21 {Invoke-ClientAction -Action '00000000-0000-0000-0000-000000000222' -LogFile 'ccmepagent'}
        22 {Invoke-ConfigurationBaselineEvaluation}
        23 {Update-SoftwareUpdateComplianceState}
        24 {Invoke-CcmPolicyReset}
        40 {Start-CcmExec}
        41 {Stop-CcmExec}
        42 {Restart-CcmExec}
        43 {Invoke-CcmEval}
        44 {Invoke-CcmRepair}
        98 {Invoke-MainMenu}
        99 {Clear-Host; Exit}
    }

    Invoke-ClientActionMenu
}

Function Invoke-RecentLogMenu {
    $recentLogTable = Get-RecentLog

    # Invoke Main Menu in case of error (e.g. Log Directoy not accessible)
    If (!$recentLogTable) {
        Invoke-MainMenu
    }

    Write-MenuHeader
    $color = $host.ui.RawUI.ForegroundColor
    $host.ui.RawUI.ForegroundColor = "Yellow"
    Write-Output " Connected Device : $hostname ($domain)"
    $host.ui.RawUI.ForegroundColor = $color
    Write-Output " Client Hardware  : $modelString"
    Write-Output " Operating System : $osString"
    Write-Output " ConfigMgr Client : $clientVersionString"
    Write-Output " Boot Time        : $lastBootTime"
    Write-Output " IP Address       : $ipAddressString"
    Write-Output ''
    Write-Output ' --- Recent Logs -------------------------------------------'

    foreach ($log in $recentLogTable.GetEnumerator()) {
        Write-Output " [$($log.Name)] $($log.Value.Name) - $($log.Value.LastWriteTime)"
    }

    Write-Output ''
    Write-Output ' --- Options -----------------------------------------------'
    Write-Output " [97] Refresh Recent Logs  [98] Back to Main Menu"
    Write-Output " [99] Exit"
    Write-Output ''

    $input = Read-Host -Prompt ' Please select an Action'
    Switch ($input) {
        97 {Invoke-RecentLogMenu}
        98 {Invoke-MainMenu}
        99 {Clear-Host; Exit}
        Default {
            # Convert input to integer
            Try {
                $inputInt32 = [convert]::ToInt32($input, 10)

                # Get log handler for user input
                $logHandler = $recentLogTable.GetEnumerator() | Where-Object {$_.Name -eq $inputInt32}
            }
            Catch {
                Invoke-RecentLogMenu
            }

            If ($logHandler) {
                # Invoke requested log
                Invoke-LogProgram -Path $logHandler.Value.Path -Files $logHandler.Value.Name
            }
        }
    }

    Invoke-RecentLogMenu
}

Function Invoke-SettingsMenu {
    Write-MenuHeader
    Write-Output ' --- Console Extension  ------------------------------------'
    Write-Output ' [1] Install / Update Console Extension'
    Write-Output ' [2] Remove Console Extension'
    Write-Output ''
    Write-Output ' --- Log Program -------------------------------------------'
    Write-Output " [10] Toggle Log Program ($global:activeLogProgram)"
    Write-Output ''
    Write-Output ' --- Options -----------------------------------------------'
    Write-Output " [98] Back to Main Menu    [99] Exit"
    Write-Output ''

    Switch (Read-Host -Prompt ' Please select an Action') {
        1 {Install-ConsoleExtension}
        2 {Remove-ConsoleExtension}
        10 {Set-ActiveLogProgram}
        98 {Invoke-MainMenu}
        99 {Clear-Host; Exit}
    }

    Invoke-SettingsMenu
}

# Check PowerShell Version
If ($PSVersionTable.PSVersion.Major -lt 3) {
    Invoke-MessageBox -Message 'This tool requires PowerShell 3.0 or later!'
    Exit
}

# Fire up Main Menu
Invoke-MainMenu -FirstLaunch