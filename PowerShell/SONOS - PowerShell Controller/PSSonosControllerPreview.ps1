#########################################################################
#
#        Name:   PSSonosControlerPreview.ps1
#    Modified:   2015-01-08
#      Author:   @SimonDettling <http://msitproblog.com>
#     Version:	 1.0.0
#  Disclaimer:   This Script is not extensively tested and is a Preview
#                of what's coming. Use at your own risk!
#
#########################################################################


# Enter the IP Adress of your Sonos Component, that is connect via Ethernt. (e.g. Playbar)
$sonosIP = "192.168.1.55"

# Port that is used for communication (Default = 1400)
$port = 1400

# Hash table containing SOAP Commands
$soapCommandTable = @{
    "Pause" = @{
        "path" = "/MediaRenderer/AVTransport/Control"
        "soapAction" = "urn:schemas-upnp-org:service:AVTransport:1#Pause"
        "message" =  '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:Pause xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID></u:Pause></s:Body></s:Envelope>'
    }
    "Play" = @{
        "path" = "/MediaRenderer/AVTransport/Control"
        "soapAction" = "urn:schemas-upnp-org:service:AVTransport:1#Play"
        "message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:Play xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID><Speed>1</Speed></u:Play></s:Body></s:Envelope>'
    }
    "Next" = @{
        "path" = "/MediaRenderer/AVTransport/Control"
        "soapAction" = "urn:schemas-upnp-org:service:AVTransport:1#Next"
        "message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:Next xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID></u:Next></s:Body></s:Envelope>'
    }
    "Previous" = @{
        "path" = "/MediaRenderer/AVTransport/Control"
        "soapAction" = "urn:schemas-upnp-org:service:AVTransport:1#Previous"
        "message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:Previous xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID></u:Previous></s:Body></s:Envelope>'
    }
    "Rewind" = @{
        "path" = "/MediaRenderer/AVTransport/Control"
        "soapAction" = "urn:schemas-upnp-org:service:AVTransport:1#Seek"
        "message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:Seek xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID><Unit>REL_TIME</Unit><Target>00:00:00</Target></u:Seek></s:Body></s:Envelope>'
    }
    "RepeatAll" = @{
        "path" = "/MediaRenderer/AVTransport/Control"
        "soapAction" = "urn:schemas-upnp-org:service:AVTransport:1#SetPlayMode"
        "message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:SetPlayMode xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID><NewPlayMode>REPEAT_ALL</NewPlayMode></u:SetPlayMode></s:Body></s:Envelope>'
    }
    "RepeatOne" = @{
        "path" = "/MediaRenderer/AVTransport/Control"
        "soapAction" = "urn:schemas-upnp-org:service:AVTransport:1#SetPlayMode"
        "message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:SetPlayMode xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID><NewPlayMode>REPEAT_ONE</NewPlayMode></u:SetPlayMode></s:Body></s:Envelope>'
    }
    "RepeatOff" = @{
        "path" = "/MediaRenderer/AVTransport/Control"
        "soapAction" = "urn:schemas-upnp-org:service:AVTransport:1#SetPlayMode"
        "message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:SetPlayMode xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"><InstanceID>0</InstanceID><NewPlayMode>NORMAL</NewPlayMode></u:SetPlayMode></s:Body></s:Envelope>'
    }
    "SetVolume" = @{
        "path" = "/MediaRenderer/RenderingControl/Control"
        "soapAction" = "urn:schemas-upnp-org:service:RenderingControl:1#SetVolume"
        "message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:SetVolume xmlns:u="urn:schemas-upnp-org:service:RenderingControl:1"><InstanceID>0</InstanceID><Channel>Master</Channel><DesiredVolume>###DESIRED_VOLUME###</DesiredVolume></u:SetVolume></s:Body></s:Envelope>'
    }
    "Mute" = @{
        "path" = "/MediaRenderer/RenderingControl/Control"
        "soapAction" = "urn:schemas-upnp-org:service:RenderingControl:1#SetMute"
        "message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:SetMute xmlns:u="urn:schemas-upnp-org:service:RenderingControl:1"><InstanceID>0</InstanceID><Channel>Master</Channel><DesiredMute>1</DesiredMute></u:SetMute></s:Body></s:Envelope>'
    }
    "Unmute" = @{
        "path" = "/MediaRenderer/RenderingControl/Control"
        "soapAction" = "urn:schemas-upnp-org:service:RenderingControl:1#SetMute"
        "message" = '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body><u:SetMute xmlns:u="urn:schemas-upnp-org:service:RenderingControl:1"><InstanceID>0</InstanceID><Channel>Master</Channel><DesiredMute>0</DesiredMute></u:SetMute></s:Body></s:Envelope>'
    }        
}

Function Set-SonosController {
    # Get Parameters
    Param(
        [Parameter(Mandatory=$true,Position=0,valueFromPipeline=$true)]
        [string]
        $action,

        [Parameter(Mandatory=$false,Position=1,valueFromPipeline=$true)]
        [int]
        $volume
    )

    # Get action from Hash Table, and throw error if it does not exist
    $actionHandler = $soapCommandTable.GetEnumerator() | Where-Object {$_.Key -eq $action}
    If (!$actionHandler) {
        throw "Action '$action' can not be found in Hash Table."
    }
    
    # Assign values from Hash Table
    $uri = "http://${sonosIP}:$port$($actionHandler.Value.path)"
    $soapAction = $actionHandler.Value.soapAction
    $soapMessage = $actionHandler.Value.message

    # Section for special Actions
    Switch ($action) {
        'setVolume' {
            If ($volume -gt 60) {
                # Your neighbors will be thankful ;-)
                $volume = 60
            }
            $soapMessage = $soapMessage.Replace("###DESIRED_VOLUME###", $volume)
        }
    }

    # Setting Header for WebRequest
    $headers = @{
        'Accept-Encoding' = 'gzip'
        'SOAPACTION' = $soapAction
    }

    # Creating a temporary file
    $tmpFile = [System.IO.Path]::GetTempFileName()

    # Sending WebRequest
    # NOTE: Without the -OutFile Parameter, Invoke-WebRequest throws a ArgumentNullExecption, probably because it can't parse the Response.
    Try {
        Invoke-WebRequest -Uri $uri -Headers $headers -ContentType 'text/xml;' -DisableKeepAlive -Method Post -Body $soapMessage -OutFile $tmpFile
    } Catch {
        Write-Warning -Message $_.Exception.Message
    }
    
    # Get content from temporary file and create XML Object
    If (Test-Path $tmpFile) {
        $responseXml = ConvertTo-Xml -InputObject (Get-Content -Path $tmpFile)
    } Else {
        $responseXml = $false
        Write-Warning -Message "Unable to locate '$tmpFile'"
    }

    # Remove temporary file
    Remove-Item $tmpFile -Force

    Return $responseXml
}

Write-Output "###############################################################"
Write-Output "#                                                             #"
Write-Output "#            SONOS PowerShell Controller (Preview)            #"
Write-Output "#                       msitproblog.com                       #"
Write-Output "#                                                             #"
Write-Output "###############################################################"
Write-Output ""
Write-Output ""
Write-Output "[1] Play"
Write-Output "[2] Pause"
Write-Output "[3] Previous Track"
Write-Output "[4] Next Track"
Write-Output "[5] Rewind Track"
Write-Output "[6] Mute"
Write-Output "[7] Unmute"
Write-Output "[8] Repeat All"
Write-Output "[9] Repeat One"
Write-Output "[10] Repeat Off"
Write-Output "[11] Set Volume"
Write-Output "----------------"
Write-Output "[99] Exit"
Write-Output "----------------"
Write-Output ""

While (1) {
    Switch (Read-Host "Please select an Action") {
     1 {Set-SonosController "Play" | Out-Null}
     2 {Set-SonosController "Pause" | Out-Null}
     3 {Set-SonosController "Previous" | Out-Null}
     4 {Set-SonosController "Next"}
     5 {Set-SonosController "Rewind" | Out-Null}
     6 {Set-SonosController "Mute" | Out-Null}
     7 {Set-SonosController "Unmute" | Out-Null}
     8 {Set-SonosController "RepeatAll" | Out-Null}
     9 {Set-SonosController "RepeatOne" | Out-Null}
     10 {Set-SonosController "RepeatOff" | Out-Null}
     11 {
        $volume = Read-Host "Enter Volume (1-50)"
        Set-SonosController "SetVolume" $volume | Out-Null
    }
     99 {Exit}
    }
}