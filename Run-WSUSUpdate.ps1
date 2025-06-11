# Ensure running as Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator."
    exit
}

# Download the main update script
$scriptUrl = "https://getupdates.me/WSUS.ps1"
$localPath = "$env:TEMP\WSUSUpdateMultiStage.ps1"

try {
    Invoke-WebRequest -Uri $scriptUrl -OutFile $localPath -UseBasicParsing -ErrorAction Stop
    Write-Host "Downloaded update script to $localPath"
} catch {
    Write-Error "Failed to download script: $_"
    exit 1
}

# Execute the script
powershell.exe -ExecutionPolicy Bypass -File $localPath
