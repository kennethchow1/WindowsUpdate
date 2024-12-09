#For Intel 11th Gen and newer CPUs
$Url = "https://downloadmirror.intel.com/833975/gfx_win_101.5978.exe"
Invoke-WebRequest -Uri "https://downloadmirror.intel.com/827043/gfx_win_101.5762.exe" -OutFile $env:TEMP\gfx_win_101.5978.exe -TimeoutSec 30
Start-Process -FilePath $env:TEMP\gfx_win_101.5762.exe
