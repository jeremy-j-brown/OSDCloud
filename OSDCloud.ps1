#================================================
#   [PreOS] Update Module
#================================================
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host  -ForegroundColor Green "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}

Write-Host -ForegroundColor Green "Updating OSD PowerShell Module"
Install-Module OSD -Force -SkipPublisherCheck

Write-Host  -ForegroundColor Green "Importing OSD PowerShell Module"
Import-Module OSD -Force   

#================================================
#   [PreOS] Menu Selection
#================================================

Write-Host "================ Main Menu ==================" -ForegroundColor Yellow
Write-Host " " -ForegroundColor Yellow
Write-Host "=============================================`n" -ForegroundColor Yellow
Write-Host "1: Win10 22H2 | Enterprise (Windows Update ESD file)" -ForegroundColor Yellow
Write-Host "2: Win11 23H2 | Enterprise (Windows Update ESD file)" -ForegroundColor Yellow
Write-Host "3: Win10 22H2 | Enterprise (Boston Server ESD file)" -ForegroundColor Yellow
Write-Host "4: Win11 23H2 | Enterprise (Boston Server ESD file)" -ForegroundColor Yellow
Write-Host "5: Win10 22H2 | Enterprise (Philadelphia Server ESD file)" -ForegroundColor Yellow
Write-Host "6: Win11 23H2 | Enterprise (Philadelphia Server ESD file)" -ForegroundColor Yellow
Write-Host "7: Start the graphical OSDCloud" -ForegroundColor Yellow
Write-Host "8: Start the graphical OSDCloud (No Autopilot)" -ForegroundColor Yellow

function New-OOBEConfig {
    Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json"
    $OOBEDeployJson = @'
    {
        "Autopilot":  {"IsPresent":  false},
        "AddNetFX3":  {"IsPresent":  false},                     
        "RemoveAppx":  [
                            "Microsoft.549981C3F5F10",
                            "Microsoft.BingWeather",
                            "Microsoft.GetHelp",
                            "Microsoft.Getstarted",
                            "Microsoft.Microsoft3DViewer",
                            "Microsoft.MicrosoftOfficeHub",
                            "Microsoft.MicrosoftSolitaireCollection",
                            "Microsoft.MixedReality.Portal",
                            "Microsoft.People",
                            "Microsoft.SkypeApp",
                            "Microsoft.Wallet",
                            "Microsoft.WindowsCamera",
                            "microsoft.windowscommunicationsapps",
                            "Microsoft.WindowsFeedbackHub",
                            "Microsoft.WindowsMaps",
                            "Microsoft.Xbox.TCUI",
                            "Microsoft.XboxApp",
                            "Microsoft.XboxGameOverlay",
                            "Microsoft.XboxGamingOverlay",
                            "Microsoft.XboxIdentityProvider",
                            "Microsoft.XboxSpeechToTextOverlay",
                            "Microsoft.YourPhone",
                            "Microsoft.ZuneMusic",
                            "Microsoft.ZuneVideo"
                       ],
        "UpdateDrivers":  {"IsPresent": false},
        "UpdateWindows":  {"IsPresent": true}
    }
'@
    If (!(Test-Path "C:\ProgramData\OSDeploy")) {
        New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
    }
    $OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force
}

function New-AutopilotConfig {
    Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json"
    $AutopilotOOBEJson = @'
    {
        "Assign": { "IsPresent": true},
        "GroupTag":  "PHL-IA",
        "GroupTagOptions":  ["BOS-A","BOS-IA","BOS-IS","BOS-S","PHL-A","PHL-IA","PHL-IS","PHL-S"],
        "Hidden": ["AssignedComputerName","AssignedUser","PostAction","Assign","AddToGroup"],
        "PostAction": "Quit",
        "Run": "Powershell",
        "Docs": "https://google.com/",
        "Title": "Intune Autopilot Registration"
    }
'@
    If (!(Test-Path "C:\ProgramData\OSDeploy")) {
        New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
    }
    $AutopilotOOBEJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json" -Encoding ascii -Force
}

function New-OOBECommand {
    Write-Host -ForegroundColor Green "Create C:\Windows\System32\OOBE.cmd"
    $OOBECMD = @'
    PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
    Set Path = %PATH%;C:\Program Files\WindowsPowerShell\Scripts
    Start /Wait PowerShell -NoL -C Install-Module AutopilotOOBE -Force -Verbose
    Start /Wait PowerShell -NoL -C Install-Module OSD -Force -Verbose
    Start /Wait PowerShell -NoL -C Start-AutopilotOOBE
    Start /Wait PowerShell -NoL -C Start-OOBEDeploy
    Start /Wait PowerShell -NoL -C Restart-Computer -Force
'@
    $OOBECMD | Out-File -FilePath 'C:\Windows\System32\OOBE.cmd' -Encoding ascii -Force
}

function New-OOBECommandNoAutopilot {
    Write-Host -ForegroundColor Green "Create C:\Windows\System32\OOBE.cmd"
    $OOBECMD = @'
    PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
    Set Path = %PATH%;C:\Program Files\WindowsPowerShell\Scripts
    Start /Wait PowerShell -NoL -C Install-Module OSD -Force -Verbose
    Start /Wait PowerShell -NoL -C Start-OOBEDeploy
    Start /Wait PowerShell -NoL -C Restart-Computer -Force
'@
    $OOBECMD | Out-File -FilePath 'C:\Windows\System32\OOBE.cmd' -Encoding ascii -Force
}

function New-CleanupCommand {
    Write-Host -ForegroundColor Green "Create C:\Windows\Setup\Scripts\SetupComplete.cmd"
    $SetupCompleteCMD = @'
    RD C:\OSDCloud\OS /S /Q
    RD C:\Drivers /S /Q
'@
    $SetupCompleteCMD | Out-File -FilePath 'C:\Windows\Setup\Scripts\SetupComplete.cmd' -Encoding ascii -Force
}

switch ($input) {
    '1' { Start-OSDCloud -OSLanguage en-us -OSVersion 'Windows 10' -OSBuild 22H2 -OSEdition Enterprise -OSLicense = "Volume" -ZTI } 
    '2' { Start-OSDCloud -OSLanguage en-us -OSVersion 'Windows 11' -OSBuild 23H2 -OSEdition Enterprise -OSLicense = "Volume" -ZTI } 
    '3' { Start-OSDCloud -ImageFileUrl https://osd.bos.server.org/Windows10.esd -ImageIndex 1 -ZTI } 
    '4' { Start-OSDCloud -ImageFileUrl https://osd.bos.server.org/Windows11.esd -ImageIndex 1 -ZTI }
    '5' { Start-OSDCloud -ImageFileUrl https://osd.phl.server.org/Windows10.esd -ImageIndex 1 -ZTI } 
    '6' { Start-OSDCloud -ImageFileUrl https://osd.phl.server.org/Windows11.esd -ImageIndex 1 -ZTI }
    '7' { Start-OSDCloudGUI }
    '8' { Start-OSDCloudGUI }  
}

# If input is equal to 1-7, then create OOBEDeploy.json and AutopilotOOBE.json
if ($input -eq '1' -or $input -eq '2' -or $input -eq '3' -or $input -eq '4' -or $input -eq '5' -or $input -eq '6' -or $input -eq '7') {
    New-OOBEConfig
    New-AutopilotConfig
    New-OOBECommand
    New-CleanupCommand
}
elseif ($input -eq '8') {
    New-OOBEConfig
    New-OOBECommandNoAutopilot
    New-CleanupCommand
}
else {
    Write-Host "Invalid selection, starting over" -ForegroundColor Red
    Start-Sleep -Seconds 3
    Invoke-WebPSScript "https://raw.githubusercontent.com/jjblab/OSDCloud/main/OSDCloud.ps1"
}

Write-Host  -ForegroundColor Green "Restarting in 20 seconds!"
Start-Sleep -Seconds 20
wpeutil reboot
