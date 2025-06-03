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
$taskName = "RunMyShortcut"
$shortcutPath = "$env:HOMEPATH\Desktop\Finalize.lnk"
$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c start `"`" `"$shortcutPath`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -RunLevel Highest -User "SYSTEM"
