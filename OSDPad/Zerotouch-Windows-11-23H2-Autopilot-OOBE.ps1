#================================================
#   OSDCloud Build Sequence
#   WARNING: Will wipe hard drive without prompt!!
#   Windows 11 23H2 Enterprise en-us Volume
#   Deploys OS
#   Updates OS
#   Removes AppX Packages from OS
#   Creates post deployment scripts for Autopilot
#================================================
#   PreOS
#   Set VM Display Resolution
if ((Get-MyComputerModel) -match 'Virtual') {
    Write-Host  -ForegroundColor Cyan "Setting Display Resolution to 1600x"
    Set-DisRes 1600
}
#================================================
#   PreOS
# Set TLS to 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
#   Install and Import OSD Module
Install-Module OSD -Force -AllowClobber -SkipPublisherCheck
Import-Module OSD -Force 

#================================================
#   [OS] Start-OSDCloud with Params
#================================================
$Params = @{
    OSName = "Windows 11 23H2 x64"
    OSEdition = "Enterprise"
    OSLanguage = "en-us"
    OSLicense = "Volume"
    SkipAutopilot = $true
    ZTI = $True
}
Start-OSDCloud @Params
#================================================
#   WinPE PostOS Sample
#   AutopilotOOBE Offline Staging
#================================================
Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json"
$AutopilotOOBEJson = @'
{
	"Assign": {
		"IsPresent": true
	},
	"GroupTag":  "PHL-IA",
    "GroupTagOptions":  [
                            "BOS-A",
                            "BOS-IA",
                            "BOS-IS",
                            "BOS-S",
                            "PHL-A",
                            "PHL-IA",
                            "PHL-IS",
                            "PHL-S"
                        ],
	"Hidden": [
		"AssignedComputerName",
		"AssignedUser",
		"PostAction",
		"Assign",
		"AddToGroup"
	],
	"PostAction": "Quit",
	"Run": "NetworkingWireless",
	"Docs": "https://google.com/",
	"Title": "Intune Autopilot Registration"
}
'@
If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$AutopilotOOBEJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json" -Encoding ascii -Force


Install-Module AutopilotOOBE -Force -AllowClobber -SkipPublisherCheck
Import-Module AutopilotOOBE -Force

$Params = @{
    Title = 'Autopilot Registration'
    GroupTagOptions = 'BOS-S','BOS-A','BOS-IA','PHL-S','PHL-A','PHL-IA'
    Hidden = 'AddToGroup','AssignedComputerName','AssignedUser','PostAction'
    Assign = $true
    PostAction = 'Restart'
    Run = 'PowerShell'
    Disabled = 'Assign'
}
AutopilotOOBE @Params
#================================================
#   WinPE PostOS Sample
#   OOBEDeploy Offline Staging
#================================================
Write-Host -ForegroundColor Green "Create C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json"
$OOBEDeployJson = @'
{
    "Autopilot":  {
                      "IsPresent":  true
                  },      
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
    "UpdateDrivers":  {
                          "IsPresent":  true
                      },
    "UpdateWindows":  {
                          "IsPresent":  true
                      }
}
'@
If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}
$OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force

$Params = @{
    Autopilot = $true
    RemoveAppx = "CommunicationsApps","OfficeHub","People","Skype","Solitaire","Xbox","ZuneMusic","ZuneVideo","GetHelp","BingWeather","GamingApp","WindowsMaps","BingNews","MicrosoftTeams"
    UpdateDrivers = $true
    UpdateWindows = $true
}
Start-OOBEDeploy @Params
#================================================
#   WinPE PostOS
#   Set OOBEDeploy CMD.ps1
#================================================
$SetCommand = @'
@echo off

:: Set the PowerShell Execution Policy
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force

:: Add PowerShell Scripts to the Path
set path=%path%;C:\Program Files\WindowsPowerShell\Scripts

:: Open and Minimize a PowerShell instance just in case
start PowerShell -NoL -W Mi

:: Install the latest OSD Module
start "Install-Module OSD" /wait PowerShell -NoL -C Install-Module OSD -Force -Verbose

:: Start-OOBEDeploy
:: The next line assumes that you have a configuration saved in C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json
start "Start-OOBEDeploy" PowerShell -NoL -C Start-OOBEDeploy

exit
'@
$SetCommand | Out-File -FilePath "C:\Windows\System32\OOBEDeploy.cmd" -Encoding ascii -Force
#================================================
#   WinPE PostOS
#   Set AutopilotOOBE CMD.ps1
#================================================
$SetCommand = @'
@echo off

:: Set the PowerShell Execution Policy
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force

:: Add PowerShell Scripts to the Path
set path=%path%;C:\Program Files\WindowsPowerShell\Scripts

:: Open and Minimize a PowerShell instance just in case
start PowerShell -NoL -W Mi

:: Install the latest AutopilotOOBE Module
start "Install-Module AutopilotOOBE" /wait PowerShell -NoL -C Install-Module AutopilotOOBE -Force -Verbose

:: Start-AutopilotOOBE
:: The next line assumes that you have a configuration saved in C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json
start "Start-AutopilotOOBE" PowerShell -NoL -C Start-AutopilotOOBE

exit
'@
$SetCommand | Out-File -FilePath "C:\Windows\System32\Autopilot.cmd" -Encoding ascii -Force

#================================================
#   PostOS
#   Shutdown-Computer & Display Message
#================================================
# Display a banner of asterisks for emphasis
Write-Host -ForegroundColor Yellow "*************************************************************************"

# Display the word "IMPORTANT!" in red and enlarged text
Write-Host -ForegroundColor Red "`n`n`n                  IMPORTANT! IMPORTANT! IMPORTANT!`n`n`n"

# Display another banner of asterisks for emphasis
Write-Host -ForegroundColor Yellow "*************************************************************************"

# Display the instructions in Cyan for better readability
Write-Host -ForegroundColor Cyan -NoNewline "INSTRUCTIONS: "
Write-Host -ForegroundColor White "Ensure to run the C:\Windows\System32\OOBEDeploy.cmd to complete the Autopilot readiness build. The device will now shut down."

# Prompt the user to press the ENTER key to continue
Write-Host -ForegroundColor Green "Press the ENTER key to continue...."
$null = Read-Host
Wpeutil Shutdown