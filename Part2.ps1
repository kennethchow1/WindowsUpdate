$startTime = Get-Date
Install-Module PSWindowsUpdate -Confirm:$false -force
Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
echo "Starting Updates"
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot
$endTime = Get-Date
$logFile = "$env:HOMEPATH\Documents\timestamp.txt"
"Update Part 1 started at: $startTime" | Out-File -FilePath $logFile
"Update Part 1 completed at: $endTime" | Out-File -FilePath $logFile -Append
