# --- Variables ---
$wsusServer = "http://your-wsus-server"
$taskName = "WSUSUpdateMultiStage"
$scriptPath = $MyInvocation.MyCommand.Definition
$stateRegPath = "HKLM:\SOFTWARE\Custom\WSUSUpdateScript"

# --- Helper functions ---

function Write-Log {
    param ($msg)
    Write-Host $msg
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

    # Auto download and install at scheduled time
    Set-ItemProperty -Path $auReg -Name "AUOptions" -Value 4 -Type DWord
    Set-ItemProperty -Path $auReg -Name "NoAutoUpdate" -Value 0 -Type DWord

    Write-Log "WSUS configured to $wsusServer"
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

function Install-Updates {
    Write-Log "Searching for updates..."

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
}

function Schedule-NextRun {
    # Remove existing task if exists
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    # Create scheduled task to run this script at system startup with highest privileges
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal

    Register-ScheduledTask -TaskName $taskName -InputObject $task

    Write-Log "Scheduled task '$taskName' created to run after reboot."
}

function Remove-ScheduledTask {
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Log "Scheduled task '$taskName' removed."
    }
}

# --- Main logic ---

# Check for Admin rights
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Warning "You must run this script as Administrator!"
    exit
}

# Read current stage
$stage = Get-State

switch ($stage) {
    0 {
        # Stage 0 = initial run: configure WSUS, install updates, reboot if needed
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
            # No reboot needed, move to stage 2 directly to clean up
            Set-State 2
            Schedule-NextRun
            Write-Log "No reboot needed, proceeding to cleanup after next reboot."
            Start-Sleep -Seconds 15
            Restart-Computer -Force
        }
    }
    1 {
        # Stage 1 = after first reboot: install updates again (in case new ones appeared), reboot if needed
        Write-Log "Stage 1: Post-first reboot, installing any new updates."

        $needsReboot = Install-Updates

        if ($needsReboot) {
            Set-State 2
            Write-Log "Updates installed, reboot required. Restarting in 15 seconds..."
            Start-Sleep -Seconds 15
            Restart-Computer -Force
        } else {
            # No reboot needed, proceed to cleanup
            Set-State 2
            Write-Log "No reboot needed after second update install. Proceeding to cleanup."
            Start-Sleep -Seconds 15
            Restart-Computer -Force
        }
    }
    2 {
        # Stage 2 = after second reboot: cleanup WSUS and scheduled task
        Write-Log "Stage 2: Post-second reboot cleanup."

        Remove-WSUS
        Remove-ScheduledTask
        Remove-State

        Write-Log "Cleanup complete. Updates process finished successfully."
    }
    default {
        Write-Warning "Unknown stage state. Exiting."
        exit
    }
}
