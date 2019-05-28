<#
.SYNOPSIS
    Matches the AITRSP Sound files to any AI Aircraft
.DESCRIPTION
    Matches the AITRSP Sound files to any AI Aircraft
.NOTES
    Script name:   AITRSP_Matcher.ps1
    Author:        @SimonDettling
    Date modified: 2019-01-01
    Version:       0.1
#>
$aitrspBasePath = 'D:\FlightSim\AI Traffic Sound Pack\sound\AI Sound'
$aiAircraftBasePath = 'D:\FlightSim\AIGAIM - OCI\SimObjects'

$aiSoundTable = @{
    'A380' = @{
        'aitrspFolder' = 'Airbus-A 380'
        'nameInclude' = @('A380')
        'nameExclude' = @()
    }
    'A350' = @{
        'aitrspFolder' = 'Airbus-C 350'
        'nameInclude' = @('A350')
        'nameExclude' = @()
    }
    'A340-600' = @{
        'aitrspFolder' = 'Airbus-D 346'
        'nameInclude' = @('A340-600')
        'nameExclude' = @()
    }
    'A340-300' = @{
        'aitrspFolder' = 'Airbus-E 343'
        'nameInclude' = @('A340-300')
        'nameExclude' = @()
    }
    'A330 PW' = @{
        'aitrspFolder' = 'Airbus-F 330PW'
        'nameInclude' = @('A330', 'PW')
        'nameExclude' = @()
    }
    'A330 RR' = @{
        'aitrspFolder' = 'Airbus-G 330RR'
        'nameInclude' = @('A330', 'RR')
        'nameExclude' = @()
    }
    'A330 GE' = @{
        'aitrspFolder' = 'Airbus-H 330GE'
        'nameInclude' = @('A330', 'GE')
        'nameExclude' = @()
    }
    'A310 GE' = @{
        'aitrspFolder' = 'Airbus-J 310GE'
        'nameInclude' = @('A310', 'GE')
        'nameExclude' = @()
    }
    'A320 Neo' = @{
        'aitrspFolder' = 'Airbus-L 320NEO'
        'nameInclude' = @('A32', 'neo')
        'nameExclude' = @()
    }
    'A321 CFM' = @{
        'aitrspFolder' = 'Airbus-M 321CFM'
        'nameInclude' = @('A321', 'CFM')
        'nameExclude' = @('neo')
    }
    'A320 CFM' = @{
        'aitrspFolder' = 'Airbus-N 320CFM'
        'nameInclude' = @('A320', 'CFM')
        'nameExclude' = @('neo')
    }
    'A320 IAE' = @{
        'aitrspFolder' = 'Airbus-O 320IAE'
        'nameInclude' = @('A320', 'IAE')
        'nameExclude' = @('neo')
    }
    'A321 IAE' = @{
        'aitrspFolder' = 'Airbus-P 321IAE'
        'nameInclude' = @('A321', 'IAE')
        'nameExclude' = @('neo')
    }
    'A319 CFM' = @{
        'aitrspFolder' = 'Airbus-Q 319CFM'
        'nameInclude' = @('A319', 'CFM')
        'nameExclude' = @('neo')
    }
    'A319 IAE' = @{
        'aitrspFolder' = 'Airbus-R A319IAE'
        'nameInclude' = @('A319', 'IAE')
        'nameExclude' = @('neo')
    }
    'A318' = @{
        'aitrspFolder' = 'Airbus-S 318'
        'nameInclude' = @('A318')
        'nameExclude' = @('neo')
    }
    'B747 GE' = @{
        'aitrspFolder' = 'Boeing-A 747GE'
        'nameInclude' = @('B747', 'GE')
        'nameExclude' = @('B747-8')
    }
    'B747 PW' = @{
        'aitrspFolder' = 'Boeing-B 747PW'
        'nameInclude' = @('B747', 'PW')
        'nameExclude' = @('B747-8')
    }
    'B747 RR' = @{
        'aitrspFolder' = 'Boeing-C 747RR'
        'nameInclude' = @('B747', 'RR')
        'nameExclude' = @('B747-8')
    }
    'B787 GE' = @{
        'aitrspFolder' = 'Boeing-D 787GE'
        'nameInclude' = @('B787', 'GE')
        'nameExclude' = @()
    }
    'B777 GE' = @{
        'aitrspFolder' = 'Boeing-E 777GE'
        'nameInclude' = @('B777', 'GE')
        'nameExclude' = @()
    }
    'B777 RR' = @{
        'aitrspFolder' = 'Boeing-F 777RR'
        'nameInclude' = @('B777', 'RR')
        'nameExclude' = @()
    }
    'B777 PW' = @{
        'aitrspFolder' = 'Boeing-G 777PW'
        'nameInclude' = @('B777', 'PW')
        'nameExclude' = @()
    }
    'B747-8 GE' = @{
        'aitrspFolder' = 'Boeing-H 748GE'
        'nameInclude' = @('B747-8')
        'nameExclude' = @()
    }
    'B787 RR' = @{
        'aitrspFolder' = 'Boeing-I 787RR'
        'nameInclude' = @('B787', 'RR')
        'nameExclude' = @()
    }
    'B767 PW' = @{
        'aitrspFolder' = 'Boeing-J 767PW'
        'nameInclude' = @('B767', 'PW')
        'nameExclude' = @()
    }
    'B767 GE' = @{
        'aitrspFolder' = 'Boeing-K 767GE'
        'nameInclude' = @('B767', 'GE')
        'nameExclude' = @()
    }
    'B767 RR' = @{
        'aitrspFolder' = 'Boeing-K 767GE'
        'nameInclude' = @('B767', 'RR')
        'nameExclude' = @()
    }
    'B757 RR' = @{
        'aitrspFolder' = 'Boeing-L 757RR'
        'nameInclude' = @('B757', 'RR')
        'nameExclude' = @()
    }
    'B757 PW' = @{
        'aitrspFolder' = 'Boeing-M 757PW'
        'nameInclude' = @('B757', 'PW')
        'nameExclude' = @()
    }
    'B737' = @{
        'aitrspFolder' = 'Boeing-O 738'
        'nameInclude' = @('B737')
        'nameExclude' = @()
    }
    'CRJ' = @{
        'aitrspFolder' = 'CRJ'
        'nameInclude' = @('CRJ')
        'nameExclude' = @()
    }
    'EMB' = @{
        'aitrspFolder' = 'EMB-ERJ'
        'nameInclude' = @('EMB')
        'nameExclude' = @()
    }
    'ERJ' = @{
        'aitrspFolder' = 'EMB-ERJ'
        'nameInclude' = @('ERJ')
        'nameExclude' = @()
    }
    'CS' = @{
        'aitrspFolder' = 'EMB-ERJ'
        'nameInclude' = @('CS')
        'nameExclude' = @()
    }
    'MD' = @{
        'aitrspFolder' = 'McD'
        'nameInclude' = @('MD')
        'nameExclude' = @()
    }
    'DHC' = @{
        'aitrspFolder' = 'Prop-A DHC8'
        'nameInclude' = @('DHC')
        'nameExclude' = @()
    }
    'Dash8' = @{
        'aitrspFolder' = 'Prop-A DHC8'
        'nameInclude' = @('Dash8')
        'nameExclude' = @()
    }
    'ATR' = @{
        'aitrspFolder' = 'Prop-B ATR'
        'nameInclude' = @('ATR')
        'nameExclude' = @()
    }
    'Avro' = @{
        'aitrspFolder' = 'RJ-BAE'
        'nameInclude' = @('Avro')
        'nameExclude' = @()
    }
    'Bae146' = @{
        'aitrspFolder' = 'RJ-BAE'
        'nameInclude' = @('Bae146')
        'nameExclude' = @()
    }
    'F70' = @{
        'aitrspFolder' = 'McD'
        'nameInclude' = @('F-70')
        'nameExclude' = @()
    }
    'F100' = @{
        'aitrspFolder' = 'McD'
        'nameInclude' = @('F-100')
        'nameExclude' = @()
    }
    'A300' = @{
        'aitrspFolder' = 'Airbus-J 310GE'
        'nameInclude' = @('A300')
        'nameExclude' = @()
    }
    'B777F' = @{
        'aitrspFolder' = 'Boeing-E 777GE'
        'nameInclude' = @('B777-200F')
        'nameExclude' = @()
    }
    'B777-200 LR' = @{
        'aitrspFolder' = 'Boeing-E 777GE'
        'nameInclude' = @('B777-200LR')
        'nameExclude' = @()
    }
    'B777-300 ER' = @{
        'aitrspFolder' = 'Boeing-E 777GE'
        'nameInclude' = @('B777-300ER')
        'nameExclude' = @()
    }
}

$replacementCounter = 0
foreach ($aiSoundEntry in $aiSoundTable.GetEnumerator()) {
    $nameInclude = $aiSoundEntry.Value.nameInclude -join '*'
    $nameExclude = $aiSoundEntry.Value.nameExclude -join '*'
    Write-Output '-----------'
    Write-Output "Processing '$($aiSoundEntry.Name)'"

    If ($nameExclude -eq "") {
        $aiFolders = Get-ChildItem -Path $aiAircraftBasePath | Where-Object {$_.Name -like "*$nameInclude*"}
    }
    Else {
        $aiFolders = Get-ChildItem -Path $aiAircraftBasePath | Where-Object {$_.Name -like "*$nameInclude*" -and $_.Name -notlike "*$nameExclude*"}
    }

    foreach ($folder in $aiFolders) {
        $soundaicfg = "$($folder.FullName)\soundai\soundai.cfg"
        $soundaiFolder = "$aitrspBasePath\$($aiSoundEntry.Value.aitrspFolder)\soundai"

        Write-Output "- Pointing soundai.cfg in folder '$folder' to '$soundaiFolder'"

        # Check for existing soundai.cfg
        If (Test-Path ($soundaicfg)) {
            # Delete existing soundai.cfg
            Remove-Item $soundaicfg -Force

            # Check new path
            If (!(Test-Path $soundaiFolder)) {
                throw "Path '$soundaiFolder' not found"
            }
            
            # Create new soundai.cfg with new Path to AITRSP
            "[FLTSIM]
alias = $soundaiFolder" | Out-File $soundaicfg
        }

        $replacementCounter = $replacementCounter + 1
    }
}

Write-Output ''
Write-Host "Replaced $replacementCounter soundai.cfg files" -ForegroundColor Green