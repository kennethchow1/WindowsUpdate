Invoke-WebRequest -Uri "https://hpia.hpcloud.hp.com/downloads/cmsl/hp-cmsl-1.8.1.exe" -OutFile hp-cmsl.exe
Start-Process -Wait -FilePath hp-cmsl.exe -Argument "/VERYSILENT" -PassThru
Get-HPBIOSSetting -Name "Absolute Persistence Module Current State"
Set-HPBIOSSettingValue -Name "Permanent Disable Absolute Persistence Module Set Once" -Value "Yes"
