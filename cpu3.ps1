#For 4th to 6th Gen CPUs
$Url = "https://gitlab.com/api/v4/projects/44042130/packages/generic/librewolf/128.0-2/librewolf-128.0-2-windows-x86_64-setup.exe"
Invoke-WebRequest -Uri $Url -OutFile $env:TEMP\librewolf-128.0-2-windows-x86_64-setup.exe -TimeoutSec 30
Start-Process -FilePath $env:TEMP\librewolf-128.0-2-windows-x86_64-setup.exe
