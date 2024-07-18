#For 4th to 6th Gen CPUs
$Url = "https://gitlab.com/api/v4/projects/44042130/packages/generic/librewolf/128.0-2/librewolf-128.0-2-windows-x86_64-setup.exe"
$DownloadZipFile = "$env:TEMP" + $(Split-Path -Path $Url -Leaf)
Invoke-WebRequest -Uri $Url -OutFile $DownloadZipFile -TimeoutSec 30
Start-Process -FilePath $DownloadZipFile\librewolf-128.0-2-windows-x86_64-setup.exe
