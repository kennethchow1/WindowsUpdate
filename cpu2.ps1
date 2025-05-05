#For 7th to 10th Gen CPUs
$Url = "https://downloadmirror.intel.com/850983/gfx_win_101.2135.exe"
Invoke-WebRequest -Uri $Url -OutFile $env:TEMP\gfx_win_101.2135.exe -TimeoutSec 30
Start-Process -FilePath $env:TEMP\gfx_win_101.2135.exe
