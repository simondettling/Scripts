<#
.SYNOPSIS
    Performs a Syntax Checks on all given PHP Files using php.exe
.DESCRIPTION
    Performs a Syntax Checks on all given PHP Files using php.exe
.PARAMETER Directory
    Directory in which the PHP Files are stored
.PARAMETER PhpExe
    Path to the php.exe
.PARAMETER LogFile
    Path to where the log file should be written
.EXAMPLE
    .\New-PHPSyntaxCheck.ps1 -Directory "C:\inetpub\wwwroot\website42" -PhpExe "C:\PHP\php.exe" -LogFile "C:\temp\PHP_SyntaxCheck.log"
.NOTES
    Name:      New-PHPSyntaxCheck.ps1
    Modified:  2015-12-04
    Author:    @SimonDettling <http://msitproblog.com>
    Version:   1.0.0
#>
[CmdletBinding(SupportsShouldProcess=$true)]

param(
    [parameter(Mandatory=$true, ParameterSetName="Single", HelpMessage="Directory in which the PHP Files are stored")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [string] $Directory,

    [parameter(Mandatory=$true, ParameterSetName="Single", HelpMessage="Path to the php.exe")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [string] $PhpExe,

    [parameter(Mandatory=$true, ParameterSetName="Single", HelpMessage="Path where the log file should be written to")]
    [ValidateNotNullOrEmpty()]
    [string] $LogFile
)

# Create new process object
$process = New-Object System.Diagnostics.Process

# Go through each php file
$phpFiles = Get-ChildItem -Path $Directory -Recurse -Include "*.php"
foreach ($file in $phpFiles) {
    # Create fancy progress bar
    $i += (100 / $phpFiles.Length)
    Write-Progress -Activity "Checking $($phpFiles.Length) PHP Files for Syntax Errors" -CurrentOperation $file -PercentComplete $i

    # Create Process Info
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $PhpExe
    $pinfo.Arguments = "-l $file"
    $pinfo.CreateNoWindow = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false

    # Assign Process Info
    $process.StartInfo = $pinfo

    # Kick off process
    $process.Start() | Out-Null

    # Wait until process has terminated
    While (!$process.HasExited) {
        Sleep -Milliseconds 100
    }

    # Write Output to log file
    $output = $process.StandardOutput.ReadToEnd()
    $output | Out-File $LogFile -Append

    # Write failed checks to console
    If ($process.ExitCode -ne 0) {
        Write-Host $output -ForegroundColor Yellow
    }
}