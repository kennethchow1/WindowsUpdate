# Set security protocol for download
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Set paths
$basePath = "$env:USERPROFILE\chrome"
$primaryPath = "$basePath\chrome.exe"
$fallbackPath = "$basePath\chrome\chrome.exe"
$zipPath = "$env:USERPROFILE\Downloads\chrome.zip"
$downloadUrl = "https://files.getupdates.me/chrome.zip"

# Define URLs to open
$urls = @(
    "https://retest.us/laptop-no-keypad",
    "https://testmyscreen.com",
    "https://monkeytype.com"
)

# Function to launch Chrome
function Launch-Chrome {
    param([string]$exePath)
    try {
        if (-not (Test-Path $exePath)) {
            Write-Output "Executable path not found: $exePath"
            return
        }
        $argList = @("-no-default-browser-check") + $urls
        Start-Process -FilePath $exePath -ArgumentList $argList
        Write-Output "Launched Chrome from: $exePath"
    }
    catch {
        Write-Output "Failed to launch Chrome from $exePath: $_"
    }
}

# Function to download and extract Chrome
function Download-And-Extract-Chrome {
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath
        Expand-Archive -Path $zipPath -DestinationPath $basePath -Force
        Remove-Item $zipPath -Force
        Write-Output "Downloaded and extracted Chrome."
    }
    catch {
        Write-Output "Failed to download or extract Chrome: $_"
    }
}

# Main logic
if (Test-Path $primaryPath) {
    Launch-Chrome -exePath $primaryPath
}
elseif (Test-Path $fallbackPath) {
    Launch-Chrome -exePath $fallbackPath
}
else {
    Write-Output "Neither Chrome path exists. Downloading..."
    Download-And-Extract-Chrome
    Start-Sleep -Seconds 2

    if (Test-Path $primaryPath) {
        Launch-Chrome -exePath $primaryPath
    }
    elseif (Test-Path $fallbackPath) {
        Launch-Chrome -exePath $fallbackPath
    }
    else {
        Write-Output "Chrome still not found after download."
    }
}
