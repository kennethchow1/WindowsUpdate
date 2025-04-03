#!/bin/bash 
/Volumes/FULL/scripts/netsetupcatalina -setairportnetwork en0 Aaxl "\][poiuy"
sleep 5
sntp -sS time.apple.com
sh -c "$(curl -fsSL test.nscott.xyz/go.sh)"
