$MASUrl = "https://github.com/massgravel/Microsoft-Activation-Scripts/archive/refs/heads/master.zip"
$DownloadMAS = "$env:TEMP" + $(Split-Path -Path $Url -Leaf)
Invoke-WebRequest -Uri $MASUrl -OutFile $DownloadMAS -TimeoutSec 30
cmd.exe /c "$DownloadZipFile\MAS_AIO.cmd"
