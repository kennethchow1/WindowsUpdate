#!/bin/bash
dscl . -passwd /Users/open open OPEN
sleep 5
sudo nvram recovery-boot-mode=unused
shutdown -r now
