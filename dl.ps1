echo "Finishing updates..."
Install-Module PSWindowsUpdate -Confirm:$false -force
Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
Start-Sleep -Seconds 15
echo "If you are still missing Intel Graphics Drivers, use the following links"
echo "Intel 11th Gen and newer CPUs: https://downloadmirror.intel.com/827043/gfx_win_101.5762.exe"
echo "Intel 7th Gen - 10th Gen CPUs: https://downloadmirror.intel.com/824226/gfx_win_101.2128.exe"
echo "Intel 4th Gen - 6th Gen CPUs: https://downloadmirror.intel.com/30195/a08/win64_15.45.5174.exe"
echo "Activating Windows..."
$key=(Get-CimInstance -Class SoftwareLicensingService).OA3xOriginalProductKey
iex "cscript /b C:\windows\system32\slmgr.vbs /upk"
iex "cscript /b C:\windows\system32\slmgr.vbs /ipk $key"
iex "cscript /b C:\windows\system32\slmgr.vbs /ato"
echo "Checking if Windows is Activated... If it doesn't show as Licensed, you will have to manually activate Windows."
$ActivationStatus = Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" | Where-Object { $_.PartialProductKey } | Select-Object LicenseStatus       

    $LicenseResult = switch($ActivationStatus.LicenseStatus){
      0	{"Unlicensed"}
      1	{"Licensed"}
      2	{"OOBGrace"}
      3	{"OOTGrace"}
      4	{"NonGenuineGrace"}
      5	{"Not Activated"}
      6	{"ExtendedGrace"}
      default {"unknown"}
    }
$LicenseResult
$Url = "https://www.nirsoft.net/utils/batteryinfoview.zip"
$DownloadZipFile = "$env:TEMP" + $(Split-Path -Path $Url -Leaf)
Invoke-WebRequest -Uri $Url -OutFile $DownloadZipFile -TimeoutSec 30
Start-Process -FilePath $DownloadZipFile\BatteryInfoView.exe
Start msedge https://retest.us/laptop-no-keypad, https://testmyscreen.com
# If running in the console, wait for input before closing.
if ($Host.Name -eq "ConsoleHost")
{
    Write-Host "Press any key to exit."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}
