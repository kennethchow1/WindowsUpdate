Invoke-WebRequest -Uri "https://raw.githubusercontent.com/kennethchow1/WindowsUpdate/main/Part4.ps1" -OutFile "$env:HOMEPATH\AppData\Local\Temp\Part4.ps1"
Start pwsh "$env:HOMEPATH\AppData\Local\Temp\Part4.ps1"
