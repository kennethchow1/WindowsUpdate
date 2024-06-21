﻿echo "Starting Final Stage"
Install-Module PSWindowsUpdate -Confirm:$false -force
Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
Powercfg /batteryreport
Start msedge "$env:HOMEPATH/battery-report.html"
Start msedge https://retest.us/laptop-no-keypad
Start calc
