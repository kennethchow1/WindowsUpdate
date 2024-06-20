echo "Initializing Final Updates.."
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/kennethchow1/WindowsUpdate/main/Part4.ps1" -OutFile "$env:HOMEPATH\AppData\Local\Temp\Part4.ps1"
pwsh "$env:HOMEPATH\AppData\Local\Temp\Part4.ps1"