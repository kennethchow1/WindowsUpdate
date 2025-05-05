#For Intel 11th Gen and newer CPUs
Invoke-WebRequest -Uri "https://downloadmirror.intel.com/853993/gfx_win_101.6790.exe" -OutFile $env:TEMP\gfx_win_101.6790.exe -TimeoutSec 30
Start-Process -FilePath $env:TEMP\gfx_win_101.6790.exe

