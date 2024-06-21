echo "Initializing.."
Invoke-WebRequest -Uri "https://github.com/PowerShell/PowerShell/releases/download/v7.4.2/PowerShell-7.4.2-win-x64.msi" -OutFile "$env:HOMEPATH\AppData\Local\Temp\Pwsh.msi"
echo "Powershell 7 Installing, Please Wait."
msiexec.exe /package "$env:HOMEPATH\AppData\Local\Temp\Pwsh.msi" /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1 ADD_PATH=1
Start-Sleep -Seconds 15
echo "Downloading files for Part 2"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/kennethchow1/WindowsUpdate/main/Part2.ps1" -OutFile "$env:HOMEPATH\AppData\Local\Temp\Part2.ps1"
Start-Process pwsh “$env:HOMEPATH\AppData\Local\Temp\Part2.ps1”
