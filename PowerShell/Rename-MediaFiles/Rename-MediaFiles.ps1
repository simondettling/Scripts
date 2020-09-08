<#
.SYNOPSIS
    Renames Image and Video Files to a certain pattern, based on Exif data (Image) and Create date (Videos).
.DESCRIPTION
    Renames Image and Video Files to a certain pattern, based on Exif data (Image) and Create date (Videos).
.PARAMETER path
    Path to the Media Files
.PARAMETER namingPattern
    Naming pattern to which the files should be renamed.
.NOTES
    Name:      Rename-Medias.ps1
    Modified:  2018-06-01
    Author:    @SimonDettling
    Version:   1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false, HelpMessage='Path to the Media Files')]
    [string] $path = 'C:\Users\Administrator\Desktop\Files',

    [Parameter(Mandatory=$false, HelpMessage='Naming pattern to which the files should be renamed.')]
    [string] $namingPattern = '%Y-%m-%d_%H-%M-%S'


)
$pictureFileType = @("*.jpg","*.jpeg")
$videoFileType = @("*.mp4","*.mov")

Add-Type -AssemblyName System.Drawing

# Process Pictures
Get-ChildItem -Path $path -Recurse -Force -Include $pictureFileType | ForEach-Object {
    $fullPath = $_.FullName
    $fileType = [IO.Path]::GetExtension($fullPath)
    
    # Create new Image Object from picture
    $image = New-Object System.Drawing.Bitmap -ArgumentList $fullPath

    # Get Date Taken Exif data
    $takenDataAscii = $image.GetPropertyItem(36867).Value

    # Close file handle
    $image.Dispose()

    # Convert Date Taken from ASCII
    $takenValue = [System.Text.Encoding]::ASCII.GetString($takenDataAscii)
    
    # Convert  Date Taken into Date Object
    $date = [datetime]::ParseExact($takenValue,"yyyy:MM:dd HH:mm:ss`0",$Null)

    # Convert Date into new pattern
    $newTitle = Get-Date $date -UFormat $namingPattern
    $newFullPath = $path + "\" + $newTitle + $fileType

    # Check if there is already a picture with this new. If there is, increment file name
    If (Test-Path $newFullPath) {
        $newTitle = $newTitle + "-2"
        $newFullPath = $path + "\" + $newTitle + $fileType
    }

    # Add file type to new title
    $newTitle += $fileType

    # Rename original file
    Rename-Item -Path $fullPath -NewName $newTitle
}

# Process Videos
Get-ChildItem -Path $path -Recurse -Force -Include $videoFileType | ForEach-Object {
    $fullPath = $_.FullName
    $fileType = [IO.Path]::GetExtension($fullPath)

    $fullPath
}
