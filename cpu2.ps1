#For 7th to 10th Gen CPUs
$Url = "https://downloadmirror.intel.com/824226/gfx_win_101.2128.exe"
$DownloadZipFile = "$env:TEMP" + $(Split-Path -Path $Url -Leaf)
Invoke-WebRequest -Uri $Url -OutFile $DownloadZipFile -TimeoutSec 30
Start-Process -FilePath $DownloadZipFile\gfx_win_101.2128.exe
