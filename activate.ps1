$MASUrl = "https://github.com/massgravel/Microsoft-Activation-Scripts/archive/refs/heads/master.zip"
$DownloadMAS = "$env:TEMP" + $(Split-Path -Path $Url -Leaf)
Invoke-WebRequest -Uri $MASUrl -OutFile "$env:HOMEPATH\MAS.zip"
Expand-Archive -LiteralPath "$env:HOMEPATH\MAS.zip" -DestinationPath "$env:HOMEPATH\" -Force
cmd.exe /c "$env:HOMEPATH\MAS_AIO.cmd"
