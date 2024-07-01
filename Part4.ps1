echo "Finishing updates..."
Install-Module PSWindowsUpdate -Confirm:$false -force
Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
echo "Activating Windows..."
$key=(Get-CimInstance -Class SoftwareLicensingService).OA3xOriginalProductKey
iex "cscript /b C:\windows\system32\slmgr.vbs /upk"
iex "cscript /b C:\windows\system32\slmgr.vbs /ipk $key"
iex "cscript /b C:\windows\system32\slmgr.vbs /ato"
echo "Checking if Windows is Activated"
$ActivationStatus = Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" | Where-Object { $_.PartialProductKey } | Select-Object LicenseStatus       

    $LicenseResult = switch($ActivationStatus.LicenseStatus){
      0	{"Unlicensed"}
      1	{"Licensed"}
      2	{"OOBGrace"}
      3	{"OOTGrace"}
      4	{"NonGenuineGrace"}
      5	{"Not Activated"}
      6	{"ExtendedGrace"}
      default {"unknown"}
    }
$LicenseResult
echo "If it doesn't show as Licensed, you will have to manually activate Windows."
Start-Sleep -Seconds 15
$Url = "https://www.nirsoft.net/utils/batteryinfoview.zip"
$DownloadZipFile = "$env:TEMP" + $(Split-Path -Path $Url -Leaf)
Invoke-WebRequest -Uri $Url -OutFile $DownloadZipFile -TimeoutSec 30
Start-Process -FilePath $DownloadZipFile\BatteryInfoView.exe
Start msedge https://retest.us/laptop-no-keypad

