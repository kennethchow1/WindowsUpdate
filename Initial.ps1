while (-not (Get-Process explorer -ErrorAction SilentlyContinue)) {
    Start-Sleep -Seconds 15
}
$fullHomePath = Join-Path -Path $env:SystemDrive -ChildPath $env:HOMEPATH
$logRoot = "$fullHomePath\WSUSLogs"
$scriptPath = "$logRoot\WSUSUpdateMultiStage.ps1"
powershell.exe -NoExit -ExecutionPolicy unrestricted -File "$scriptPath"
