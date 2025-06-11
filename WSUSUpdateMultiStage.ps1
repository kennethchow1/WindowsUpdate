# --- Self-bootstrap: download and relaunch from correct path if needed ---
$fullHomePath = Join-Path -Path $env:SystemDrive -ChildPath $env:HOMEPATH
$logRoot = "$env:HOMEPATH\WSUSLogs"
$scriptPath = "$logRoot\WSUSUpdateMultiStage.ps1"

if ($MyInvocation.MyCommand.Path -ne $scriptPath) {
    if (-not (Test-Path $logRoot)) {
        New-Item -ItemType Directory -Path $logRoot | Out-Null
    }
    Write-Host "Downloading script to $scriptPath ..."
    Invoke-RestMethod -Uri "https://getupdates.me/WSUSUpdateMultiStage.ps1" -OutFile $scriptPath -UseBasicParsing
    Write-Host "Re-launching script from $scriptPath ..."
    Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy unrestricted -File `"$scriptPath`"" -Verb RunAs
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

    Write-Log "WSUS configured to $wsusServer with Microsoft Update fallback."
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
    Write-Log "Installing PSWindowsUpdate module..."

    try {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers -ErrorAction Stop
        Install-Module -Name PSWindowsUpdate -Force -Confirm:$false -Scope AllUsers -ErrorAction Stop
        Import-Module PSWindowsUpdate -Force
        Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
    } catch {
        Write-Log "Error setting up PSWindowsUpdate: $_"
        return $false
    }

    Write-Log "Starting update check at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    try {
        do {
            # Run once per boot — don’t keep looping
            $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -Confirm:$false

            if ($updates.Count -gt 0) {
                Write-Log "Installing $($updates.Count) updates..."
                Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -Confirm:$false
                Write-Log "Updates installed, rebooting if required..."
                Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -Confirm:$false
            } else {
                Write-Log "No updates left to install. Proceeding to cleanup."
                Set-State 2
                Restart-Computer -Force
            }
        } while ($updates.Count -gt 0)

        Write-Log "Final update with AutoReboot if needed..."
        Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -Confirm:$false
    } catch {
        Write-Log "Update error: $_"
        return $false
    }

    Write-Log "Update finished at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    return $false
}

function Schedule-NextRun {
    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    $username = "$env:COMPUTERNAME\Administrator"
    $psPath = "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe"
    $action = New-ScheduledTaskAction -Execute $psPath -Argument "-ExecutionPolicy unrestricted -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $principal = New-ScheduledTaskPrincipal -UserId $username -LogonType Interactive -RunLevel Highest
    $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal

    Register-ScheduledTask -TaskName $taskName -InputObject $task -Force
    Write-Log "Task scheduled to run at Administrator logon."
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
        Write-Log "Stage 0: Configuring WSUS and starting update process."
        Set-WSUS
        Set-State 1
        Schedule-NextRun

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

        Write-Log "Stage 1 update start: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Install-Updates
        Write-Log "Stage 1 update finished: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

        Write-Log "Rebooting in 15 seconds..."
        Start-Sleep -Seconds 15
        Restart-Computer -Force
    }
    2 {
        Write-Log "Stage 2: Final cleanup phase."
        Remove-WSUS
        Remove-ScheduledTask
        Remove-State

        Write-Log "All updates applied. Cleanup complete."
        Write-Host "`nPress ENTER to close this window."
        Read-Host
    }
    default {
        Write-Warning "Unknown stage. Exiting."
        exit
    }
}
