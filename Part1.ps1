echo "Initializing.."
Invoke-WebRequest -Uri "https://github.com/PowerShell/PowerShell/releases/download/v7.4.2/PowerShell-7.4.2-win-x64.msi" -OutFile Pwsh.msi
echo "Powershell 7 Installing, Please Wait."
msiexec.exe /package Pwsh.msi /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1 ADD_PATH=1
Start-Sleep -Seconds 30
Invoke-WebRequest -Uri "https://getupdates.me/Final.lnk" -OutFile "$env:HOMEPATH\Desktop\Finalize.lnk"
Start-Process -FilePath "C:\Program Files\Powershell\7\pwsh.exe" -ArgumentList "-ExecutionPolicy Unrestricted -C irm https://getupdates.me/Part2.ps1 | iex"
Invoke-WebRequest -Uri "https://downloadmirror.intel.com/30195/a08/win64_15.45.5174.exe" -OutFile "$env:HOMEPATH\Desktop\Intel 4th-6th Gen Drivers.exe"
Invoke-WebRequest -Uri "https://downloadmirror.intel.com/824226/gfx_win_101.2128.exe" -OutFile "$env:HOMEPATH\Desktop\Intel 7th-10th Gen Drivers.exe"
Invoke-WebRequest -Uri "https://downloadmirror.intel.com/827043/gfx_win_101.5762.exe" -OutFile "$env:HOMEPATH\Desktop\Intel 11th Gen and Newer Drivers.exe"
