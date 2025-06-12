# Reset-WUComponents.ps1
# Resets Windows Update services and related folders

function Write-Log {
    param($Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

function Reset-WUComponents {
    Write-Log "Resetting Windows Update components..."

    $services = @(
        "wuauserv",          # Windows Update
        "bits",              # Background Intelligent Transfer
        "cryptsvc",          # Cryptographic Services
        "msiserver",         # Windows Installer (optional)
        "trustedinstaller"   # Windows Modules Installer
    )

    foreach ($svc in $services) {
        Write-Log "Stopping service: $svc"
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    }

    Write-Log "Deleting SoftwareDistribution and CatRoot2..."
    Remove-Item -Path "C:\Windows\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\System32\catroot2" -Recurse -Force -ErrorAction SilentlyContinue

    Write-Log "Resetting BITS and WinHTTP proxy..."
    netsh winsock reset | Out-Null
    netsh winhttp reset proxy | Out-Null
    bitsadmin /reset /allusers | Out-Null

    foreach ($svc in $services) {
        Write-Log "Starting service: $svc"
        Start-Service -Name $svc -ErrorAction SilentlyContinue
    }

    Write-Log "Windows Update components reset complete."
}

# --- Run the function ---
Reset-WUComponents
