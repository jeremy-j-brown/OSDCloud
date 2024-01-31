$Path = "C:\OSD\OSDownloader"
$OSVersions = @("Windows10", "Windows11")

Function Get-PathExists {
    param (
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        Write-Host "Path does not exist. Creating: $Path"
        New-Item -ItemType Directory -Path $Path | Out-Null
        Write-Host "Path created."
    } else {
        Write-Host "Path already exists: $Path"
    }
}

Function Get-RedirectedUrl {
    Param(
        $URL
    )

    $Request = [System.Net.WebRequest]::Create($URL)
    $Request.AllowAutoRedirect = $false
    $Request.Timeout = 3000
    $Response = $Request.GetResponse()

    If ($Response.ResponseUri) {
        $Response.GetResponseHeader("Location")
    }
    $Response.Close()
}

Function Get-WindowsESD {
    Param(
        $OSVersion
    )

    If ($OSVersion -eq "Windows10") {
        $URL = "https://go.microsoft.com/fwlink/?LinkId=841361"
        $Path = $Path + "\Windows10"
    }
    ElseIf ($OSVersion -eq "Windows11") {
        $URL = "https://go.microsoft.com/fwlink/?LinkId=2156292"
        $Path = $Path + "\Windows11"
    }
    
    Get-PathExists -Path $Path
    $ActualURL = Get-RedirectedUrl -URL "$URL" -ErrorAction Continue -WarningAction Continue
    $FileName = $ActualURL.Substring($ActualURL.LastIndexOf("/") + 1)
    $FileToDownload = "$Path\$Filename"
    Write-Host "Downloading $ActualURL to $FileToDownload"
    Start-BitsTransfer -Source $ActualURL -Destination "$FileToDownload" -Priority Foreground -RetryTimeout 60 -RetryInterval 120
    $ExpandExe = "$env:WINDIR\System32\expand.exe"
    $ExtractedFilePath = $Path + "\products.xml"
    $argumentList = '-F:*' + " " + $FileToDownload + " " + $ExtractedFilePath
    Write-Host "Extracting $FileToDownload to $ExtractedFilePath"
    Start-Process -FilePath $ExpandExe -ArgumentList $argumentList -Wait -WindowStyle Hidden
    $XmlFile = Get-Item -Path "$ExtractedFilePath"
    [xml]$Xml = Get-Content -Path $XmlFile
    $Files = $Xml.MCT.Catalogs.Catalog.PublishedMedia.Files.File
    $ESDPath = "$Path\$OSVersion.esd"
    ForEach ($File in $Files) {
        If (($File.FileName -like "*VOL*en-us.esd*") -and ($File.Architecture -like "x64") -and ($File.Edition -notlike "*N")) {
            Write-Host "Downloading $ESDPath"
            Start-BitsTransfer -Source $File.FilePath -Destination $ESDPath -Priority Foreground -RetryTimeout 60 -RetryInterval 120
        }
    }
}

ForEach ($OSVersion in $OSVersions) { 
    Get-WindowsESD -OSVersion $OSVersion 
}