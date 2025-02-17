Invoke-WebRequest -Uri "https://hpia.hpcloud.hp.com/downloads/cmsl/hp-cmsl-1.8.1.exe" -OutFile "$env:HOMEPATH\hp-cmsl.exe"
Start-Process -Wait -FilePath "$env:HOMEPATH\hp-cmsl.exe" -Argument "/VERYSILENT" -PassThru
Get-HPBIOSSetting -Name "Absolute Persistence Module Current State"
Set-HPBIOSSettingValue -Name "Permanent Disable Absolute Persistence Module Set Once" -Value "Yes"
echo "Rebooting to apply changes..."
Start-Sleep -Seconds 15
shutdown /r
