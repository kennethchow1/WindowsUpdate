Install-Module PSWindowsUpdate -Confirm:$false -force
Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
echo "Starting Updates"
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot
