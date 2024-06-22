Invoke-WebRequest -Uri "https://raw.githubusercontent.com/kennethchow1/WindowsUpdate/main/Part4.ps1" -OutFile "$env:HOMEPATH\AppData\Local\Temp\Part4.ps1"
Start-Process -FilePath "C:\Program Files\Powershell\7\pwsh.exe" -ArgumentList "-ExecutionPolicy Unrestricted -C irm https://raw.githubusercontent.com/kennethchow1/WindowsUpdate/main/Part4.ps1 | iex"
