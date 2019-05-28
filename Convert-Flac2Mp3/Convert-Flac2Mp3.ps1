<#
.SYNOPSIS
    Converts FLAC files to MP3
.DESCRIPTION
    Converts FLAC files to MP3
.PARAMETER ffmpegExe
    Path to the ffmpeg.exe. If not specified, the script will download the latest version.
.PARAMETER ffmpegDownloadUrl
    Download URL of ffmpeg.
.PARAMETER sourceFolder
    Path to source folder in which the media files are stored
.PARAMETER destinationFolder
    Path to the destination folder
.PARAMETER bitrate
    Specify the bitrate of the destination MP3. (Default: 320k)
.EXAMPLE
    .\Convert-Flac2Mp3.ps1 -sourceFolder "C:\temp\Source" -destinationFolder "C:\temp\Destination" -bitrate 256k
.NOTES
    Name:      Convert-Flac2Mp3.ps1
    Modified:  2017-01-30
    Author:    @SimonDettling
    Version:   1.1.0
#>
[CmdletBinding(SupportsShouldProcess=$true)]

param(
    [Parameter(Mandatory=$false, HelpMessage='Path to the ffmpeg.exe. If not specified, the script will download the latest version.')]
    [string] $ffmpegExe = '',

    [Parameter(Mandatory=$false, HelpMessage='Download URL of ffmpeg.')]
    [string] $ffmpegDownloadUrl = 'https://ffmpeg.zeranoe.com/builds/win64/static/ffmpeg-latest-win64-static.zip',

    [parameter(Mandatory=$true, ParameterSetName="Single", HelpMessage="Path to source folder in which the media files are stored")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [string] $sourceFolder,

    [parameter(Mandatory=$true, ParameterSetName="Single", HelpMessage="Path to the destination folder")]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path -Path $_})]
    [string] $destinationFolder,

    [parameter(Mandatory=$false, ParameterSetName="Single", HelpMessage="Specify the bitrate of the destination MP3. (Default: 320k)")]
    [ValidateNotNullOrEmpty()]
    [string] $bitrate = "320k"
)

# Get all media files from source folder
$files = Get-ChildItem $sourceFolder -Recurse -Force -Include *.flac,*.m4a

# Check if there are any media files
If (!($files.Length)) {
    throw ("Source folder does not contain any audio files")
}

If ($ffmpegExe -eq '') {
    # Get Temporary Path
    $tmpFile = 'ffmpeg-latest-win64-static.zip'
    $tmpPath = [System.IO.Path]::GetTempPath()
    $tmpDownloadFile = $tmpPath + $tmpFile

    # Download ffmpeg to temp path
    Write-Progress -Activity 'Downloading ffmpeg' -PercentComplete 10
    Invoke-WebRequest -Uri $ffmpegDownloadUrl -OutFile $tmpDownloadFile

    # Extract downloaded ffmpeg archive
    Write-Progress -Activity 'Extracting ffmpeg' -PercentComplete 20
    Expand-Archive -LiteralPath $tmpDownloadFile -DestinationPath $tmpPath -Force

    # Assign ffmpeg.exe
    $tmpPath = $tmpPath + 'ffmpeg-latest-win64-static\'
    $ffmpegExe = $tmpPath + 'bin\ffmpeg.exe'

    If ((Test-Path $ffmpegExe) -eq $false) {
        throw "'$ffmpegExe' doesn't exist"
    }
}

$i = 0
foreach ($file in $files) {
    # Get full path of current file
    $fileNameFull = $file.FullName

    # Get filename without file extension
    $fileName = [IO.Path]::GetFileNameWithoutExtension($fileNameFull)

    # Calculate loop counter
    $i += (100 / $files.Length)

    # Create fancy progress bar
    Write-Progress -Activity "Converting Audio Files" -PercentComplete $i -CurrentOperation $fileNameFull

    # Execute ffmpeg
    $returnCode = Start-Process -FilePath $ffmpegExe -ArgumentList "-i `"$fileNameFull`" -ab $bitrate -map_metadata 0 -id3v2_version 3 -f mp3 -y `"$destinationFolder\${fileName}.mp3`"" -PassThru -Wait

    # Validate return code
    If ($returnCode.ExitCode -ne 0) {
        throw "ffmpeg failed with code $($returnCode.ExitCode) at file '$fileNameFull'"
    }
}

If (Test-Path $tmpDownloadFile) {
    Remove-Item $tmpDownloadFile -Recurse -Force
}
If (Test-Path $tmpPath) {
    Remove-Item $tmpPath -Recurse -Force
}