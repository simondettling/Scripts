<#
.SYNOPSIS
    Creates a Reference VM which will be used to create a Reference Image via Microsoft Deployment Toolkit
.DESCRIPTION
    Creates a Reference VM which will be used to create a Reference Image via Microsoft Deployment Toolkit
.PARAMETER Name
    Name of the virtual machine that will be created
.EXAMPLE
    .\New-ReferenceVM.ps1 -Name REF001
.NOTES
    Script name: New-ReferenceVM.ps1
    Author:      @SimonDettling <msitproblog.com>
    DateCreated: 2016-02-17
    Version:     1.0.0
#>
[CmdletBinding(SupportsShouldProcess=$true)]

param(
    [parameter(Mandatory=$true, ParameterSetName="Single", HelpMessage="Name of the virtual machine that will be created")]
    [ValidateNotNullOrEmpty()]
    [string] $name
)

# Initialize variables
$vmName = $name
$vmRam = 4096MB
$vmDiskSize = 50GB
$vmGeneration = 1
$vCPUs = 4
$vSwitchName = "vSwitch LAN"
$mdtLiteTouch = "\\MDT01.domain.tld\MDTBuildLab`$\Boot\MDT Build Lab x86.iso"
$bootIso = "D:\Boot Image\${vmName}_BootImage.iso"
$vhdx = (Get-VMHost).VirtualHardDiskPath + "\${vmName}_C.VHDX"
$sleepTimer = 15
$vmConnectExe = "C:\Windows\System32\vmconnect.exe"

# Check if Hyper-V is installed
If ((Get-WindowsFeature "Hyper-V").Installed -eq $false) {
    throw "Hyper-V Role is not present on this system"
}

# Check if Boot Image is accessible
If ((Test-Path $mdtLiteTouch) -eq $false) {
    throw "Lite Touch ISO '$mdtLiteTouc' is not accessible"
}

# Perform cleanup, in case the previous script didn't complete successfully
If (Test-Path $bootIso) {
    Stop-VM -Name $vmName -Force | Out-Null
    Remove-VM -Name $vmName -Force | Out-Null
    Remove-Item $vhdx -Force | Out-Null
    Remove-Item $bootIso -Force | Out-Null
    Clear-Host
}

# Copy Lite Touch ISO
Copy-Item -Path $mdtLiteTouch -Destination $bootIso -Force -Verbose

# Create new VM
New-VM -Name $vmName -MemoryStartupBytes $vmRam -NewVHDPath $vhdx -NewVHDSizeBytes $vmDiskSize -SwitchName $vSwitchName -Generation $vmGeneration -Verbose

# Set vCPUs and Start / Stop Action
Set-VM -Name $vmName -ProcessorCount $vCPUs -AutomaticStartAction Nothing -AutomaticStopAction TurnOff -Verbose

# Mount Boot ISO
Set-VMDvdDrive -VMName $vmName -Path $bootIso -Verbose

# Fire up VM
Start-VM -Name $vmName -Verbose

# Start Virtual Machine Connection
Start-Process -FilePath $vmConnectExe -ArgumentList "LOCALHOST $vmName" -Verbose

# Wait until VM is turned off
$vm = Get-VM -Name $vmName -Verbose
while ($vm.State -ne "Off") {
    Write-Host "VM is still running. Will try again in $sleepTimer seconds..."
    Start-Sleep -Seconds $sleepTimer
}

# Remove VM and vhdx file
Remove-VM -Name $vmName -Force -Verbose
Remove-Item $vhdx -Force -Verbose

# Remove copied Boot-Image
Remove-Item $bootIso -Force -Verbose