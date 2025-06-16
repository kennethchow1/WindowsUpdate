# Define both paths
$primaryPath = "$env:HOMEPATH\chrome\chrome.exe"
$fallbackPath = "$env:HOMEPATH\chrome\chrome\chrome.exe"

# Define URLs to open
$urls = "https://retest.us/laptop-no-keypad https://testmyscreen.com https://monkeytype.com"

# Try primary path
if (Test-Path $primaryPath) {
    try {
        Start-Process -FilePath $primaryPath -ArgumentList "-no-default-browser-check $urls"
        Write-Output "Launched Chrome from primary path."
    }
    catch {
        Write-Output "Failed to launch Chrome from primary path: $_"
        # Try fallback path
        if (Test-Path $fallbackPath) {
            try {
                Start-Process -FilePath $fallbackPath -ArgumentList "-no-default-browser-check $urls"
                Write-Output "Launched Chrome from fallback path."
            }
            catch {
                Write-Output "Failed to launch Chrome from fallback path: $_"
            }
        } else {
            Write-Output "Fallback Chrome path not found."
        }
    }
}
elseif (Test-Path $fallbackPath) {
    try {
        Start-Process -FilePath $fallbackPath -ArgumentList "-no-default-browser-check $urls"
        Write-Output "Launched Chrome from fallback path."
    }
    catch {
        Write-Output "Failed to launch Chrome from fallback path: $_"
    }
}
else {
    Write-Output "Neither Chrome path exists."
}
