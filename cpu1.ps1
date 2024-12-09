#For Intel 11th Gen and newer CPUs
Invoke-WebRequest -Uri "https://downloadmirror.intel.com/842305/gfx_win_101.6319.exe" -OutFile $env:TEMP\gfx_win_101.6319.exe -TimeoutSec 30
Start-Process -FilePath $env:TEMP\gfx_win_101.6319.exe
