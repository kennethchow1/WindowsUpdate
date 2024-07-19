## Create the action
$action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument '-Command "irm https://getupdates.me/ | iex"'

## Set to run as local system, No need to store Credentials!!!
$principal = New-ScheduledTaskPrincipal -UserID "NT AUTHORITY\SYSTEM" -LogonType ServiceAccount -RunLevel Highest

## set to run at startup could also do -AtLogOn for the trigger
$trigger = New-ScheduledTaskTrigger -AtStartup

## register it (save it) and it will show up in default folder of task scheduler.
Register-ScheduledTask -Action $action -TaskName 'mytask' -TaskPath '\' -Principal $principal -Trigger $trigger
