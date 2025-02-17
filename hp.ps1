Start-Process -FilePath "C:\Program Files\Powershell\7\pwsh.exe" -ArgumentList "-ExecutionPolicy Unrestricted -C irm https://raw.githubusercontent.com/ConfigJon/Firmware-Management/refs/heads/master/HP/Install-HPCMSL.ps1 | iex"
Get-HPBIOSSetting -Name "Absolute Persistence Module Current State"
Set-HPBIOSSettingValue -Name "Permanent Disable Absolute Persistence Module Set Once" -Value "Yes"
