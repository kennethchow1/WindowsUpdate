$Url = "https://www.nirsoft.net/utils/batteryinfoview.zip"
$DownloadZipFile = "$env:TEMP" + $(Split-Path -Path $Url -Leaf)
Invoke-WebRequest -Uri $Url -OutFile $DownloadZipFile -TimeoutSec 30
Start-Process -FilePath $DownloadZipFile\BatteryInfoView.exe
