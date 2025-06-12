$fullHomePath = Join-Path -Path $env:SystemDrive -ChildPath $env:HOMEPATH
$logRoot = "$fullHomePath\WSUSLogs"
$scriptPath = "$logRoot\WSUSUpdateMultiStage.ps1"
powershell.exe -NoExit -ExecutionPolicy unrestricted -File "$scriptPath"
