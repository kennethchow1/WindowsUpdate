$LASTCHANGE_URL="https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Win_x64%2FLAST_CHANGE?alt=media"
$REVISION=$(curl -s -S $LASTCHANGE_URL)
$DOWNLOAD_CHROMIUM_URL="https://commondatastorage.googleapis.com/chromium-browser-snapshots/Win_x64/$REVISION/chrome-win.zip"
Invoke-WebRequest $DOWNLOAD_CHROMIUM_URL -OutFile "$env:HOMEPATH\chrome-win.zip"
Start-Process -FilePath "$env:HOMEPATH\chrome-win\chrome.exe" -ArgumentList "-no-default-browser-check https://retest.us/laptop-no-keypad https://testmyscreen.com https://getupdates.me/drivers"
