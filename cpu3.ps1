#For 4th to 6th Gen CPUs
$Url = "https://downloadmirror.intel.com/30195/a08/win64_15.45.5174.exe"
$DownloadZipFile = "$env:TEMP" + $(Split-Path -Path $Url -Leaf)
Invoke-WebRequest -Uri $Url -OutFile $DownloadZipFile -TimeoutSec 30
Start-Process -FilePath $DownloadZipFile\win64_15.45.5174.exe
