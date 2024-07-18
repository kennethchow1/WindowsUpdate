echo "Finishing updates..."
Invoke-WebRequest -Uri "https://getupdates.me/Intel_11th_Gen_Drivers.lnk" -OutFile "$env:HOMEPATH\Desktop\Intel 11th Gen+ Drivers.lnk"
Invoke-WebRequest -Uri "https://getupdates.me/Intel_7th-10th_Gen_Drivers.lnk" -OutFile "$env:HOMEPATH\Desktop\Intel 7th-10th Gen Drivers.lnk"
Invoke-WebRequest -Uri "https://getupdates.me/Intel_4th-6th_Gen_Drivers.lnk" -OutFile "$env:HOMEPATH\Desktop\Intel 4th-6th Gen Drivers.lnk"
Install-Module PSWindowsUpdate -Confirm:$false -force
Add-WUServiceManager -MicrosoftUpdate -Confirm:$false
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot
Start-Sleep -Seconds 15
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
echo "If you are missing Intel Integrated GPU Drivers, please use the corresponding desktop shortcut for your CPU Generation."
$Url = "https://www.nirsoft.net/utils/batteryinfoview.zip"
$DownloadZipFile = "$env:TEMP" + $(Split-Path -Path $Url -Leaf)
Invoke-WebRequest -Uri $Url -OutFile $DownloadZipFile -TimeoutSec 30
Start-Process -FilePath $DownloadZipFile\BatteryInfoView.exe
Start msedge https://retest.us/laptop-no-keypad, https://testmyscreen.com, https://getupdates.me/drivers
# If running in the console, wait for input before closing.
if ($Host.Name -eq "ConsoleHost")
{
    Write-Host "Press any key to exit."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}
