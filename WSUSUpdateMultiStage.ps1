# --- Self-bootstrap: download and relaunch from correct path if needed ---
$fullHomePath = Join-Path -Path $env:SystemDrive -ChildPath $env:HOMEPATH
$logRoot = "$fullHomePath\WSUSLogs"
$scriptPath = "$logRoot\WSUSUpdateMultiStage.ps1"
$notscript = "$logRoot\Initial.ps1"

if ($MyInvocation.MyCommand.Path -ne $scriptPath) {
    if (-not (Test-Path $logRoot)) {
        New-Item -ItemType Directory -Path $logRoot | Out-Null
    }
    Write-Host "Downloading script to $scriptPath ..."
    Invoke-RestMethod -Uri "https://getupdates.me/WSUSUpdateMultiStage.ps1" -OutFile $scriptPath -UseBasicParsing
    Invoke-WebRequest -Uri "https://getupdates.me/Initial.ps1" -OutFile "$notscript"
    Write-Host "Re-launching script from $scriptPath ..."
    Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy unrestricted -NoProfile -File `"$scriptPath`"" -Verb RunAs
    exit
}
# Set execution policy to bypass for this session
Set-ExecutionPolicy unrestricted -Scope Process -Force

# --- Variables ---
$wsusServer = "http://23.82.125.157"
$taskName = "WSUSUpdateMultiStage"
$logFile = "$logRoot\WSUSUpdateLog.txt"
$stateRegPath = "HKLM:\SOFTWARE\Custom\WSUSUpdateScript"

# --- Helper functions ---
function Write-Log {
    param ($msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp - $msg"
    Write-Host $entry
    Add-Content -Path $logFile -Value $entry
}

function Get-State {
    if (-not (Test-Path $stateRegPath)) { return 0 }
    try {
        return (Get-ItemProperty -Path $stateRegPath -Name "Stage").Stage
    } catch {
        return 0
    }
}

function Set-State($stage) {
    if (-not (Test-Path $stateRegPath)) { New-Item -Path $stateRegPath -Force | Out-Null }
    Set-ItemProperty -Path $stateRegPath -Name "Stage" -Value $stage -Type DWord
}

function Remove-State {
    if (Test-Path $stateRegPath) { Remove-Item -Path $stateRegPath -Recurse -Force }
}

function Set-WSUS {
    $wuReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    $auReg = "$wuReg\AU"

    if (-not (Test-Path $wuReg)) { New-Item -Path $wuReg -Force | Out-Null }
    if (-not (Test-Path $auReg)) { New-Item -Path $auReg -Force | Out-Null }

    Set-ItemProperty -Path $wuReg -Name "WUServer" -Value $wsusServer -Type String
    Set-ItemProperty -Path $wuReg -Name "WUStatusServer" -Value $wsusServer -Type String
    Set-ItemProperty -Path $auReg -Name "UseWUServer" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $auReg -Name "AUOptions" -Value 4 -Type DWord
    Set-ItemProperty -Path $auReg -Name "NoAutoUpdate" -Value 0 -Type DWord

    # Allow fallback to Microsoft Update
    Remove-ItemProperty -Path $wuReg -Name "DoNotConnectToWindowsUpdateInternetLocations" -ErrorAction SilentlyContinue

    Write-Log "WSUS configured with Microsoft Update fallback."
}

function Remove-WSUS {
    $wuReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    if (Test-Path $wuReg) {
        Remove-Item -Path $wuReg -Recurse -Force
        Write-Log "WSUS configuration removed."
    } else {
        Write-Log "No WSUS configuration found."
    }
}

function Reset-WUComponents {
    Write-Log "Resetting Windows Update components..."

    $services = @(
        "wuauserv",   # Windows Update
        "bits",       # Background Intelligent Transfer
        "cryptsvc",   # Cryptographic services
        "msiserver",  # Windows Installer (optional)
        "trustedinstaller" # Windows Modules Installer
    )

    foreach ($svc in $services) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    }

    
    Remove-Item -Recurse -Force "C:\Windows\SoftwareDistribution" -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force "C:\Windows\System32\catroot2" -ErrorAction SilentlyContinue

    netsh winsock reset | Out-Null
    netsh winhttp reset proxy | Out-Null
    bitsadmin /reset /allusers | Out-Null

    foreach ($svc in $services) {
        Start-Service -Name $svc -ErrorAction SilentlyContinue
    }

    Write-Log "Windows Update components have been reset."
}

function Wait-ForInternet {
    param (
        [string]$TestUrl = "https://www.microsoft.com",
        [int]$MaxRetries = 8,
        [int]$DelaySeconds = 5
    )

    Write-Log "Waiting for internet connectivity ($TestUrl)..."

    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            $res = Invoke-WebRequest -Uri $TestUrl -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
            if ($res.StatusCode -eq 200) {
                Write-Log "Internet check passed on attempt $i."
                return
            }
        } catch {
            Write-Log "Internet check failed (attempt $i). Retrying in $DelaySeconds seconds..."
            Start-Sleep -Seconds $DelaySeconds
        }
    }

    throw "Internet did not recover after $MaxRetries attempts."
}

function Restart-NetworkAdapter {
    Write-Log "Restarting all active network adapters..."

    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }

    foreach ($adapter in $adapters) {
        try {
            Write-Log "Disabling adapter: $($adapter.Name)"
            Disable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
            Start-Sleep -Seconds 5
            Write-Log "Enabling adapter: $($adapter.Name)"
            Enable-NetAdapter -Name $adapter.Name -Confirm:$false -ErrorAction Stop
        } catch {
            Write-Log "Failed to restart adapter $($adapter.Name): $_"
        }
    }

    Write-Log "Network adapters restarted."
}

function Install-Updates {
    Write-Log "========== Starting Windows Update Check: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') =========="

    $failedUpdatesPath = "$env:USERPROFILE\Desktop\FailedUpdates.txt"
    $existingFailures = @()
    if (Test-Path $failedUpdatesPath) {
        $existingFailures = Get-Content $failedUpdatesPath
    }

    try {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers -ErrorAction Stop
        Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -Scope AllUsers -ErrorAction Stop
        Import-Module PSWindowsUpdate -Force
        Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
    } catch {
        Write-Log "Error setting up PSWindowsUpdate: $_"
        return $false
    }

    $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -Confirm:$false
    if ($updates.Count -eq 0) {
        Write-Log "No updates found."
        return $true
    }

    Write-Log "Found $($updates.Count) updates. Beginning individual installation..."

    foreach ($update in $updates) {
        $updateTitle = $update.Title
        if ($existingFailures -contains $updateTitle) {
            Write-Log "SKIPPING previously failed update: $updateTitle"
            continue
        }

        Write-Log "Installing update: $updateTitle"
        try {
            Install-WindowsUpdate -Title $updateTitle -AcceptAll -IgnoreReboot -Confirm:$false -ErrorAction Stop | Out-Null
            Write-Log "Successfully installed: $updateTitle"
        } catch {
            $errMsg = $_.Exception.Message
            Write-Log "ERROR installing $(updateTitle): $errMsg"
            "$((Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) - $updateTitle - $errMsg" | Out-File -FilePath $failedUpdatesPath -Append -Encoding UTF8
        }
    }

    Write-Log "Final update pass to catch anything else (auto-reboot if needed)..."
    try {
        Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -Confirm:$false | Out-Null
    } catch {
        Write-Log "AutoReboot stage error: $_"
    }

    Write-Log "========== Update Process Finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') =========="
    return $true
}



function Schedule-NextRun {
    $runOnceKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    $entryName = "WSUSUpdateMultiStage"

    # Use cmd.exe to launch PowerShell visibly but non-blocking
    $command = "cmd.exe /c start powershell.exe -ExecutionPolicy Bypass -NoProfile -File `"$notscript`""

    Set-ItemProperty -Path $runOnceKey -Name $entryName -Value $command -Force
    Write-Log "RunOnce entry added to launch PowerShell after reboot"
}

function Remove-ScheduledTask {
    $runOnceKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    $entryName = "WSUSUpdateMultiStage"

    Remove-ItemProperty -Path $runOnceKey -Name $entryName -ErrorAction SilentlyContinue
    Write-Log "RunOnce entry '$entryName' removed (if present)."
}

function Set-DNS {
    Write-Log "Setting DNS server to 10.0.6.21"

    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    foreach ($adapter in $adapters) {
        try {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses "10.0.6.21"
            Write-Log "DNS set on adapter $($adapter.Name)"
        } catch {
            Write-Log "Failed to set DNS on adapter $($adapter.Name): $_"
        }
    }
}

function Reset-DNS {
    Write-Log "Resetting DNS to automatic (DHCP)"

    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
    foreach ($adapter in $adapters) {
        try {
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ResetServerAddresses
            Write-Log "DNS reset on adapter $($adapter.Name)"
        } catch {
            Write-Log "Failed to reset DNS on adapter $($adapter.Name): $_"
        }
    }
}

function Wait-ForDNS {
    param (
        [string]$TestHost = "www.microsoft.com",
        [int]$MaxRetries = 30,
        [int]$DelaySeconds = 5
    )

    Write-Log "Checking DNS resolution for $TestHost..."

    for ($i = 1; $i -le $MaxRetries; $i++) {
        try {
            $dnsResult = Resolve-DnsName -Name $TestHost -ErrorAction Stop
            if ($dnsResult) {
                Write-Log "DNS resolution succeeded on attempt $i."
                return
            }
        } catch {
            Write-Log "Attempt $($i): DNS resolution failed. Retrying in $DelaySeconds seconds..."
            Start-Sleep -Seconds $DelaySeconds
        }
    }

    Write-Log "DNS did not resolve after $MaxRetries attempts. Exiting script."
    exit 1
}

# Function to launch Chrome
function Launch-Chrome {
    param([string]$exePath)
    try {
        if (-not (Test-Path $exePath)) {
            Write-Output "Executable path not found: $exePath"
            return
        }
        $urls = @(
            "https://retest.us/laptop-no-keypad",
            "https://testmyscreen.com",
            "https://monkeytype.com"
        )
        $argList = @("-no-default-browser-check") + $urls
        Start-Process -FilePath $exePath -ArgumentList $argList
        Write-Output "Launched Chrome from: $exePath"
    }
    catch {
        Write-Output "Failed to launch Chrome from ${exePath}: $_"
    }
}

# Function to download and extract Chrome
function Download-And-Extract-Chrome {
    $downloadUrl = "https://files.getupdates.me/chrome.zip"
    $zipPath = "$env:USERPROFILE\Downloads\chrome.zip"
    $basePath = "$env:USERPROFILE\chrome"

    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
        Expand-Archive -Path $zipPath -DestinationPath $basePath -Force
        Remove-Item $zipPath -Force
        Write-Output "Downloaded and extracted Chrome."
    }
    catch {
        Write-Output "Failed to download or extract Chrome: $_"
    }
}


# --- Main logic ---

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Warning "You must run this script as Administrator!"
    exit
}

$stage = Get-State

switch ($stage) {
    0 {
        Write-Log "Stage 0: Configuring and starting update process."

        $downloadUrl = "https://files.getupdates.me/chrome.zip"
        $zipPath = "$env:USERPROFILE\chrome.zip"
        $extractPath = "$env:USERPROFILE\chrome"
        $logFile = "$env:USERPROFILE\WSUSLogs\WSUSUpdateLog.txt"

        if (-not (Test-Path $zipPath)) {
            Write-Log "Starting background download and extraction of Chrome..."

            Start-Job -ScriptBlock {
                param (
                    $url, $zip, $dest, $logFilePath
                )

                function Log {
                    param ($msg)
                    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $entry = "$timestamp - $msg"
                    Add-Content -Path $logFilePath -Value $entry
                }

                try {
                    Log "Downloading Chrome from $url ..."
                    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop

                    if (Test-Path $dest) {
                        Log "Removing existing extracted folder: $dest"
                        Remove-Item -Path $dest -Recurse -Force -ErrorAction SilentlyContinue
                    }

                    Log "Extracting Chrome to $dest"
                    Expand-Archive -Path $zip -DestinationPath $dest -Force

                    Log "Chrome download and extraction completed successfully."
                } catch {
                    Log "ERROR during Chrome background job: $($_.Exception.Message)"
                }

            } -ArgumentList $downloadUrl, $zipPath, $extractPath, $logFile | Out-Null

        } else {
            Write-Log "Chrome archive already exists at $zipPath, skipping download."
        }
        $CN = (Get-WmiObject -class win32_bios).SerialNumber
        Rename-Computer -NewName "PC-$CN" -WarningAction silentlyContinue
        #Set-WSUS
        Set-State 1
        Schedule-NextRun

        Write-Log "Resetting WindowsUpdate Module to ensure it works properly"
        Reset-WUComponents
        #Set-DNS
        Write-Log "Stage 0 update start: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Install-Updates
        Write-Log "Stage 0 update finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Write-Log "Rebooting in 15 seconds..."
        Start-Sleep -Seconds 15
        Restart-Computer -Force
    }
    1 {
        Write-Log "Stage 1: Post-reboot update run."
        Set-State 2
        Schedule-NextRun
        Wait-ForInternet
        Reset-WUComponents
        Write-Log "Stage 1 update start: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Install-Updates
        Write-Log "Stage 1 update finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Write-Log "Rebooting in 15 seconds..."
        Start-Sleep -Seconds 15
        Restart-Computer -Force
    }
    2 {
        Write-Log "Stage 2: Second post-reboot update run."
        Set-State 3
        Schedule-NextRun
        Wait-ForInternet
        Reset-WUComponents
        Write-Log "Stage 2 update start: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Install-Updates
        Write-Log "Stage 2 update finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Write-Log "Rebooting in 15 seconds..."
        Start-Sleep -Seconds 15
        Restart-Computer -Force
    }
    3 {
        Write-Log "Stage 3: Final update and cleanup phase."
        #Remove-WSUS
        Wait-ForInternet
        Reset-WUComponents
        Install-Updates
        Remove-ScheduledTask
        Remove-State
        #Reset-DNS
        Wait-ForDNS
        Write-Log "All updates applied. Cleanup complete."
        Invoke-WebRequest -Uri "https://getupdates.me/BatteryInfo.lnk" -OutFile "$env:HOMEPATH\Desktop\View Battery Info.lnk"
        Invoke-WebRequest -Uri "https://getupdates.me/Intel_11th_Gen+_Drivers.lnk" -OutFile "$env:HOMEPATH\Desktop\Intel 11th Gen+ Drivers.lnk"
        Invoke-WebRequest -Uri "https://getupdates.me/Intel_6th-10th_Gen_Drivers.lnk" -OutFile "$env:HOMEPATH\Desktop\Intel 6th-10th Gen Drivers.lnk"
        Invoke-WebRequest -Uri "https://getupdates.me/Intel_4th-5th_Gen_Drivers.lnk" -OutFile "$env:HOMEPATH\Desktop\Intel 4th-5th Gen Drivers.lnk"
        Invoke-WebRequest -Uri "https://getupdates.me/DisableAbsoluteHP.lnk" -OutFile "$env:HOMEPATH\Desktop\Disable HP Absolute.lnk"
        Invoke-WebRequest -Uri "https://getupdates.me/MASActivateWindows.lnk" -OutFile "$env:HOMEPATH\Desktop\MAS - Activate Windows.lnk"
        Invoke-WebRequest -Uri "https://getupdates.me/Chrome.lnk" -OutFile "$env:HOMEPATH\Desktop\Chrome.lnk"
        echo "Activating Windows..."
        $key=(Get-CimInstance -Class SoftwareLicensingService).OA3xOriginalProductKey
        iex "cscript /b C:\windows\system32\slmgr.vbs /upk"
        iex "cscript /b C:\windows\system32\slmgr.vbs /ipk $key"
        iex "cscript /b C:\windows\system32\slmgr.vbs /ato"
        echo "Verifying if Windows is Activated... If it doesn't show as Licensed, you will have to manually activate Windows."
        $ActivationStatus = Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" | Where-Object { $_.PartialProductKey } | Select-Object LicenseStatus       

            $LicenseResult = switch($ActivationStatus.LicenseStatus){
              0	{"Unlicensed"}
              1	{"Licensed"}
              2	{"OOBGrace"}
              3	{"OOTGrace"}
              4	{"NonGenuineGrace"}
              5	{"Not Activated"}
              6	{"ExtendedGrace"}
              default {"unknown"}
            }
        $LicenseResult
        echo "If you are missing Intel Integrated GPU Drivers, please use the corresponding desktop shortcut for your CPU Generation."
        $Url = "https://raw.githubusercontent.com/kennethchow1/WindowsUpdate/refs/heads/main/batteryinfoview.zip"
        $DownloadZipFile = Join-Path $env:TEMP "batteryinfoview.zip"
        $ExtractFolder = Join-Path $env:TEMP "batteryinfoview_extracted"

        # Download the zip
        Invoke-WebRequest -Uri $Url -OutFile $DownloadZipFile -TimeoutSec 30

        # Create extract folder if it doesn't exist
        if (-not (Test-Path $ExtractFolder)) {
            New-Item -ItemType Directory -Path $ExtractFolder | Out-Null
        }

        # Extract it
        Expand-Archive -LiteralPath $DownloadZipFile -DestinationPath $ExtractFolder -Force

        # Launch the .exe
        $exePath = Join-Path $ExtractFolder "BatteryInfoView.exe"
        if (Test-Path $exePath) {
            Start-Process -FilePath $exePath
        } else {
            Write-Host "BatteryInfoView.exe not found after extraction!"
        }
        try {
            $desktopPath = [Environment]::GetFolderPath('MyDocuments')
            $logFilePath = "$logRoot\WSUSUpdateLog.txt"
            $destLogFile = Join-Path -Path $desktopPath -ChildPath "WSUSUpdateLog.txt"

            if (Test-Path $logFilePath) {
                Copy-Item -Path $logFilePath -Destination $destLogFile -Force
                Write-Log "Copied log file to $destLogFile"
            } else {
                Write-Log "Log file not found: $logFilePath"
            }
        } catch {
            Write-Log "Failed to copy log file to desktop: $_"
        }
        # === Upload log to Cloudflare R2 via Worker ===
        try {
            $logFilePath = "$logRoot\WSUSUpdateLog.txt"

            if (Test-Path $logFilePath) {
                # Get device serial number and sanitize it
                $serial = (Get-WmiObject -Class Win32_BIOS).SerialNumber -replace '[^a-zA-Z0-9\-]', ''

        # Format timestamp as yyyyMMdd-HHmmss
                $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

                # Create filename: SERIAL-TIMESTAMP.txt or TIMESTAMP.txt if serial is empty
                if ([string]::IsNullOrEmpty($serial)) {
                    $fileName = "$timestamp.txt"
                } else {
                    $fileName = "$serial-$timestamp.txt"
                }

        # Construct upload URL
                $uploadUrl = "https://logs.getupdates.me/$fileName"

                # Upload the log file as binary
                $logBytes = [System.IO.File]::ReadAllBytes($logFilePath)
                $response = Invoke-RestMethod -Uri $uploadUrl -Method Put -Body $logBytes -ContentType "application/octet-stream"

                Write-Log "Successfully uploaded log file: $response"
            } else {
                Write-Log "Log file not found at $logFilePath. Upload skipped."
            }
        } catch {
            Write-Log "Failed to upload log file: $_"
        }
        # Launch Chrome from correct path
        $primaryPath = "$env:USERPROFILE\chrome\chrome.exe"
        $fallbackPath = "$env:USERPROFILE\chrome\chrome\chrome.exe"

        if (Test-Path $primaryPath) {
            Launch-Chrome -exePath $primaryPath
        }
        elseif (Test-Path $fallbackPath) {
            Launch-Chrome -exePath $fallbackPath
        }
        else {
            Write-Output "Chrome not found. Attempting download..."
            Download-And-Extract-Chrome
            Start-Sleep -Seconds 2
            if (Test-Path $primaryPath) {
                Launch-Chrome -exePath $primaryPath
            }
            elseif (Test-Path $fallbackPath) {
                Launch-Chrome -exePath $fallbackPath
            }
            else {
                Write-Output "Failed to find Chrome after download."
            }
        }
    }
    default {
        Write-Warning "Unknown stage. Exiting."
        exit
    }
}
