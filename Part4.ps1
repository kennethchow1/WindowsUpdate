echo "Finishing updates..."
Install-Module PSWindowsUpdate -Confirm:$false -force
Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
Start-Sleep -Seconds 15
$Url = "https://www.nirsoft.net/utils/batteryinfoview.zip"
$DownloadZipFile = "$env:TEMP" + $(Split-Path -Path $Url -Leaf)
Invoke-WebRequest -Uri $Url -OutFile $DownloadZipFile -TimeoutSec 30
Start-Process -FilePath $DownloadZipFile\BatteryInfoView.exe
Start msedge https://retest.us/laptop-no-keypad
Start-Sleep -Seconds 15
