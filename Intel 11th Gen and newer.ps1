$Url = "https://downloadmirror.intel.com/827043/gfx_win_101.5762.exe"
$DownloadZipFile = "$env:TEMP" + $(Split-Path -Path $Url -Leaf)
Invoke-WebRequest -Uri "https://downloadmirror.intel.com/827043/gfx_win_101.5762.exe" -OutFile $DownloadZipFile -TimeoutSec 30
Start-Process -FilePath $DownloadZipFile\gfx_win_101.5762.exe
