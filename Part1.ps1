echo "Initializing.."
Invoke-WebRequest -Uri "https://getupdates.me/Final.lnk" -OutFile "$env:HOMEPATH\Desktop\Finalize.lnk"
Invoke-WebRequest -Uri "https://getupdates.me/BatteryInfo.lnk" -OutFile "$env:HOMEPATH\Desktop\View Battery Info.lnk"
Invoke-WebRequest -Uri "https://github.com/PowerShell/PowerShell/releases/download/v7.4.2/PowerShell-7.4.2-win-x64.msi" -OutFile Pwsh.msi
echo "Powershell 7 Installing, Please Wait."
msiexec.exe /package Pwsh.msi /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1 ADD_PATH=1
Start-Sleep -Seconds 30
Start-Process -FilePath "C:\Program Files\Powershell\7\pwsh.exe" -ArgumentList "-ExecutionPolicy Unrestricted -C irm https://getupdates.me/Part2.ps1 | iex"
