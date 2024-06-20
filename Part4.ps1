echo "Starting Final Stage"
Install-Module PSWindowsUpdate -Confirm:$false -force
Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
Powercfg /batteryreport
Start msedge –no-first-run ./battery-report.html
Start msedge –no-first-run https://retest.us/laptop-no-keypad
Start calc