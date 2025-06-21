# Define both possible Chrome paths
$primaryPath = "$env:HOMEPATH\chrome\chrome.exe"
$fallbackPath = "$env:HOMEPATH\chrome\chrome\chrome.exe"

# Define download URL and target extraction directory
$downloadUrl = "https://files.getupdates.me/chrome.zip"
$zipPath = "$env:HOMEPATH\Downloads\chrome.zip"
$extractPath = "$env:HOMEPATH\chrome"

# Define URLs to open in Chrome
$urls = "https://retest.us/laptop-no-keypad https://testmyscreen.com https://monkeytype.com"

# Function to launch Chrome
function Launch-Chrome {
    param([string]$exePath)
    try {
        Start-Process -FilePath $exePath -ArgumentList "-no-default-browser-check $urls"
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
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
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

    # Retry after extraction
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
