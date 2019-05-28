<#
.SYNOPSIS
    Optimizes the given input file for HTTP Streaming and allows Audio/Video format conversion.
.DESCRIPTION
    Optimizes the given input file for HTTP Streaming and allows Audio/Video format conversion.
.PARAMETER sourceFolder
    Path to source folder in which the media files are stored
.PARAMETER destinationFolder
    Path to the destination folder
.PARAMETER ffmpegExe
    Path to the ffmpeg.exe. If not specified, the script will download the latest version.
.PARAMETER ffmpegDownloadUrl
    Download URL of ffmpeg.
.PARAMETER audioCodec
    Specify the Audio Codec. (Default value will be copied from source)
.PARAMETER audioBitrate
    Specify the Audio Bitrate. (Default value will be copied from source)
.PARAMETER videoCodec
    Specify the Audio Codec. (Default value will be copied from source)
.NOTES
    Name:      Optimize-Video4Streaming.ps1
    Modified:  2017-04-29
    Author:    @SimonDettling
    Version:   3.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, HelpMessage='Path to source folder')]
    [string] $sourceFolder = 'C:\Temp',

    [Parameter(Mandatory=$false, HelpMessage='Path to the destination folder')]
    [string] $destinationFolder = '\\NAS01\PlexMedia\',

    [Parameter(Mandatory=$false, HelpMessage='Path to the ffmpeg.exe. If not specified, the script will download the latest version.')]
    [string] $ffmpegExe = '',

    [Parameter(Mandatory=$false, HelpMessage='Download URL of ffmpeg.')]
    [string] $ffmpegDownloadUrl = 'https://ffmpeg.zeranoe.com/builds/win64/static/ffmpeg-latest-win64-static.zip',

    [Parameter(Mandatory=$false, HelpMessage='Specify the Audio Codec (Default value: ac3)')]
    [ValidateSet('copy','aac','ac3','ac3_fixed','eac3','flac','libfaac','libfdk_aac','libmp3lame','libopencore-amrnb','libshine','libtwolame','libvo-amrwbenc','libopus','libvorbis','libwavpack','wavpack')]
    [string] $audioCodec = 'ac3',

    [Parameter(Mandatory=$false, HelpMessage='Specify the Audio Bitrate (Default value will be copied from source)')]
    [int] $audioBitrate = 0,

    [Parameter(Mandatory=$false, HelpMessage='Specify the Video Codec (Default value will be copied from source)')]
    [ValidateSet('copy','libopenh264','jpeg2000','snow','libtheora','libvpx','libwebp','libx264','libx264rgb','libx265','libxvid','mpeg2','png','ProRes','libkvazaar','vc2')] 
    [string] $videoCodec = 'copy'
)

# Get all movie files from source folder
$files = Get-ChildItem -Path $sourceFolder -Recurse -Force -Include '*.3g2','*.3gp','*.3gpp','*.asf','*.avi','*.divx','*.f4v','*.flv','*.h264','*.ifo','*.m2ts','*.m4v','*.mkv','*.mod','*.mov','*.mp4','*.mpeg','*.mpg','*.mswmm','*.mts','*.mxf','*.ogv','*.rm','*.swf','*.ts','*.vep','*.vob','*.webm','*.wlmp','*.wmv'

# Check if there are any media files
If (!($files.Length)) {
    throw 'Source folder does not contain any video files'
}

If ($ffmpegExe -eq '') {
    # Get Temporary Path
    $tmpFile = 'ffmpeg-latest-win64-static.zip'
    $tmpPath = [System.IO.Path]::GetTempPath()
    $tmpDownloadFile = $tmpPath + $tmpFile

    # Download ffmpeg to temp path
    Write-Progress -Activity "Downloading ffmpeg"
    Invoke-WebRequest -Uri $ffmpegDownloadUrl -OutFile $tmpDownloadFile

    # Extract downloaded ffmpeg archive
    Expand-Archive -LiteralPath $tmpDownloadFile -DestinationPath $tmpPath -Force

    # Assign ffmpeg.exe
    $tmpPath = $tmpPath + 'ffmpeg-latest-win64-static\'
    $ffmpegExe = $tmpPath + 'bin\ffmpeg.exe'

    If ((Test-Path $ffmpegExe) -eq $false) {
        throw "'$ffmpegExe' doesn't exist"
    }
}

$i = 1
foreach ($file in $files) {
    # Get full path of current file
    $fileNameFull = $file.FullName

    # Get filename without file extension
    $fileName = [IO.Path]::GetFileNameWithoutExtension($fileNameFull)

    $extensionAttributes = ''
    
    # Define bitrate
    If ($audioBitrate -gt 0) {
        $extensionAttributes += "-b:a ${audioBitrate}k"
    }

    # Build ffmpeg export filename
    Write-Progress -Activity "Converting file '$fileName'" -Status "$i / $($files.Count)"
    $ffmpegOutFile = $destinationFolder + "${fileName}.mp4"

    # Execute ffmpeg using -sn to remove the subtitle stream if present
    # -map 0:v:0 -map 0:m:language:eng
   $returnCode = Start-Process -FilePath $ffmpegExe -ArgumentList "-i `"$fileNameFull`" -y -movflags faststart -c:a $audioCodec $extensionAttributes -c:v $videoCodec -sn `"$ffmpegOutFile`"" -PassThru -Wait

    # Validate return code
    If ($returnCode.ExitCode -ne 0) {
        throw "ffmpeg failed with code $($returnCode.ExitCode) at file '$fileNameFull'"
    }

    $i++
}

Write-Progress "Cleaning up temp data"
If (Test-Path $tmpDownloadFile) {
    Remove-Item $tmpDownloadFile -Recurse -Force
}
If (Test-Path $tmpPath) {
    Remove-Item $tmpPath -Recurse -Force
}

# Open Destination Folder in explorer
Invoke-Item $destinationFolder