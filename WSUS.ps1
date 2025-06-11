<#
.SYNOPSIS
    Multi-stage WSUS update installer script for fresh Windows 11 installs.

.DESCRIPTION
    - Configures WSUS server for Windows Update
    - Searches, downloads, and installs updates in multiple stages
    - Handles reboots between stages automatically
    - Cleans up WSUS config and scheduled tasks after completion
    - Logs progress to console and optionally to log file

.PARAMETER WsusServer
    URL of the WSUS server to configure (default: http://23.82.125.157)

.EXAMPLE
    .\WSUSUpdateMultiStage.ps1 -WsusServer "http://yourwsusserver"
#>

param(
    [string]$WsusServer = "http://23.82.125.157"
)

# --- Constants & variables ---
$taskName = "WSUSUpdateMultiStage"
$scriptPath = $MyInvocation.MyCommand.Definition
$stateRegPath = "HKLM:\SOFTWARE\Custom\WSUSUpdateScript"
$logFile = "C:\Temp\WSUSUpdateMultiStage.log"

# Ensure log directory exists
$logDir = Split-Path $logFile
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

# --- Logging functions ---
function Write-Log {
    param([string]$msg, [string]$level = "INFO")
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $formatted = "[$timestamp] [$level] $msg"
    Write-Host $formatted -ForegroundColor ($level -eq "ERROR" ? "Red" : "Cyan")
    Add-Content -Path $logFile -Value $formatted
}

function Write-ErrorLog {
    param([string]$msg)
    Write-Log $msg "ERROR"
}

# --- State functions ---
function Get-State {
    if (-not (Test-Path $stateRegPath)) { return 0 }
    try {
        return (Get-ItemProperty -Path $stateRegPath -Name "Stage" -ErrorAction Stop).Stage
    } catch {
        Write-ErrorLog "Failed to get stage state: $_"
        return 0
    }
}

function Set-State($stage) {
    try {
        if (-not (Test-Path $stateRegPath)) { New-Item -Path $stateRegPath -Force | Out-Null }
        Set-ItemProperty -Path $stateRegPath -Name "Stage" -Value $stage -Type DWord -Force
        Write-Log "Set stage state to $stage"
    } catch {
        Write-ErrorLog "Failed to set stage state: $_"
        throw
    }
}

function Remove-State {
    try {
        if (Test-Path $stateRegPath) {
            Remove-Item -Path $stateRegPath -Recurse -Force
            Write-Log "Removed state registry key."
        }
    } catch {
        Write-ErrorLog "Failed to remove state registry key: $_"
    }
}

# --- WSUS Configuration ---
function Set-WSUS {
    $wuReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    $auReg = "$wuReg\AU"

    try {
        if (-not (Test-Path $wuReg)) { New-Item -Path $wuReg -Force | Out-Null }
        if (-not (Test-Path $auReg)) { New-Item -Path $auReg -Force | Out-Null }

        Set-ItemProperty -Path $wuReg -Name "WUServer" -Value $WsusServer -Type String -Force
        Set-ItemProperty -Path $wuReg -Name "WUStatusServer" -Value $WsusServer -Type String -Force
        Set-ItemProperty -Path $auReg -Name "UseWUServer" -Value 1 -Type DWord -Force

        # Auto download and install at scheduled time
        Set-ItemProperty -Path $auReg -Name "AUOptions" -Value 4 -Type DWord -Force
        Set-ItemProperty -Path $auReg -Name "NoAutoUpdate" -Value 0 -Type DWord -Force

        Write-Log "WSUS configured to $WsusServer"
    } catch {
        Write-ErrorLog "Failed to configure WSUS: $_"
        throw
    }
}

function Remove-WSUS {
    $wuReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"

    try {
        if (Test-Path $wuReg) {
            Remove-Item -Path $wuReg -Recurse -Force
            Write-Log "WSUS configuration removed."
        } else {
            Write-Log "No WSUS configuration found."
        }
    } catch {
        Write-ErrorLog "Failed to remove WSUS configuration: $_"
    }
}

# --- Update installation ---
function Install-Updates {
    Write-Log "Searching for updates..."

    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()

        $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")
        $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl

        foreach ($update in $searchResult.Updates) {
            $updatesToInstall.Add($update) | Out-Null
        }

        if ($updatesToInstall.Count -eq 0) {
            Write-Log "No updates found."
            return $false
        }

        Write-Log "$($updatesToInstall.Count) updates found. Downloading and installing..."

        $downloader = $updateSession.CreateUpdateDownloader()
        $downloader.Updates = $updatesToInstall
        $downloader.Download()

        $installer = $updateSession.CreateUpdateInstaller()
        $installer.Updates = $updatesToInstall
        $result = $installer.Install()

        Write-Log "Installation result code: $($result.ResultCode)"
        if ($result.RebootRequired) {
            Write-Log "Reboot is required to complete updates."
            return $true
        } else {
            Write-Log "Updates installed successfully, no reboot needed."
            return $false
        }
    } catch {
        Write-ErrorLog "Failed during update installation: $_"
        throw
    }
}

# --- Scheduled Task Management ---
function Schedule-NextRun {
    try {
        if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }

        $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`" -WsusServer `"$WsusServer`""
        $trigger = New-ScheduledTaskTrigger -AtStartup
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
        $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal

        Register-ScheduledTask -TaskName $taskName -InputObject $task
        Write-Log "Scheduled task '$taskName' created to run after reboot."
    } catch {
        Write-ErrorLog "Failed to schedule next run: $_"
        throw
    }
}

function Remove-ScheduledTask {
    try {
        if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-Log "Scheduled task '$taskName' removed."
        }
    } catch {
        Write-ErrorLog "Failed to remove scheduled task: $_"
    }
}

# --- Main ---

# Check Admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Log "Script must be run as Administrator." "ERROR"
    throw "Administrator privileges required."
}

try {
    $stage = Get-State

    switch ($stage) {
        0 {
            Write-Log "Stage 0: Initial WSUS setup and update installation."
            Set-WSUS
            $needsReboot = Install-Updates

            if ($needsReboot) {
                Set-State 1
                Schedule-NextRun

                Write-Log "Restarting computer in 15 seconds..."
                Start-Sleep -Seconds 15
                Restart-Computer -Force
            } else {
                # No reboot needed, move to stage 2 directly
                Set-State 2
                Schedule-NextRun

                Write-Log "No reboot needed, proceeding to cleanup after next reboot."
                Start-Sleep -Seconds 15
                Restart-Computer -Force
            }
        }
        1 {
            Write-Log "Stage 1: Post-first reboot, installing any new updates."
            $needsReboot = Install-Updates

            if ($needsReboot) {
                Set-State 2
                Write-Log "Updates installed, reboot required. Restarting in 15 seconds..."
                Start-Sleep -Seconds 15
                Restart-Computer -Force
            } else {
                Set-State 2
                Write-Log "No reboot needed after second update install. Proceeding to cleanup."
                Start-Sleep -Seconds 15
                Restart-Computer -Force
            }
        }
        2 {
            Write-Log "Stage 2: Post-second reboot cleanup."
            Remove-WSUS
            Remove-ScheduledTask
            Remove-State
            Write-Log "Cleanup complete. Update process finished successfully."
        }
        default {
            Write-Log "Unknown stage state: $stage. Exiting." "ERROR"
            throw "Invalid stage state."
        }
    }
} catch {
    Write-ErrorLog "Unhandled exception: $_"
    throw
}
