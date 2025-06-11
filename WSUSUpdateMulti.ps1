Invoke-WebRequest -Uri "https://getupdates.me/WSUSUpdateMulti.ps1" -OutFile $scriptPath

# --- Variables ---
$wsusServer = "http://23.82.125.157"
$taskName = "WSUSUpdateMultiStage"
$scriptPath = "$env:HOMEPATH\WSUSUpdateMulti.ps1"
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
    Write-Log "Installing PSWindowsUpdate module and starting update process..."
    
    try {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers
        Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -Scope AllUsers
        Import-Module PSWindowsUpdate -Force

        Add-WUServiceManager -MicrosoftUpdate -Confirm:$false

        Write-Log "Starting Updates (non-rebooting passes)..."
        Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -Confirm:$false
        Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -Confirm:$false

        Write-Log "Final Update pass (AutoReboot)..."
        Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -Confirm:$false

        return $false  # Reboot is handled automatically
    } catch {
        Write-Log "Update installation failed: $_"
        return $false
    }
}

function Schedule-NextRun {
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

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

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Warning "You must run this script as Administrator!"
    exit
}

$stage = Get-State

switch ($stage) {
    0 {
        Write-Log "Stage 0: Initial WSUS setup and update installation."

        Set-WSUS
        $needsReboot = Install-Updates

        Set-State 1
        Schedule-NextRun
        Write-Log "Rebooting in 15 seconds..."
        Start-Sleep -Seconds 15
        Restart-Computer -Force
    }
    1 {
        Write-Log "Stage 1: Post-first reboot, installing any new updates."

        $needsReboot = Install-Updates

        Set-State 2
        Write-Log "Rebooting again in 15 seconds..."
        Start-Sleep -Seconds 15
        Restart-Computer -Force
    }
    2 {
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
