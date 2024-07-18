#For 4th to 6th Gen CPUs
$Url = "https://downloadmirror.intel.com/30195/a08/win64_15.45.5174.exe"
Invoke-WebRequest -Uri $Url -OutFile $env:TEMP\win64_15.45.5174.exe -TimeoutSec 30
Start-Process -FilePath $env:TEMP\win64_15.45.5174.exe
