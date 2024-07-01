echo "Activating Windows..."
$key=(Get-WmiObject -Class SoftwareLicensingService).OA3xOriginalProductKey
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
# If running in the console, wait for input before closing.
if ($Host.Name -eq "ConsoleHost")
{
    Write-Host "Press any key to close Powershell."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}
