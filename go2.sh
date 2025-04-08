#!/bin/bash 
INTERNAL_VOLUME_NAME="Mac hd"

# Get the internal disk
get_internal_disk() {
    echo "Detecting internal disks..."
    INTERNAL_DISKS=($(diskutil list internal physical | awk '/^\/dev\// && !/disk[0-9]s[0-9]/ {print $1}'))

    if [ ${#INTERNAL_DISKS[@]} -eq 0 ]; then
        echo "No internal disks found! Exiting..."
        exit 1
    elif [ ${#INTERNAL_DISKS[@]} -eq 1 ]; then
        INTERNAL_DISK=${INTERNAL_DISKS[0]}
    else
        echo "Multiple internal disks detected:"
        for i in "${!INTERNAL_DISKS[@]}"; do
            echo "$((i+1)). ${INTERNAL_DISKS[i]}"
        done
        read -p "Select a disk number to format: " disk_choice
        while ! [[ "$disk_choice" =~ ^[1-${#INTERNAL_DISKS[@]}]$ ]]; do
            echo "Invalid selection. Choose a number between 1 and ${#INTERNAL_DISKS[@]}."
            read -p "Select a disk number to format: " disk_choice
        done
        INTERNAL_DISK=${INTERNAL_DISKS[disk_choice-1]}
    fi

    echo "Selected disk: $INTERNAL_DISK"
}


# Format the disk
format_disk() {
    diskutil unmountDisk force "$INTERNAL_DISK"
    diskutil eraseDisk APFS "$INTERNAL_VOLUME_NAME" "$INTERNAL_DISK"
}

# Check for an internet connection
check_internet() {
    echo "Checking for internet connection..."
    while ! ping -c 1 -t 5 1.1.1.1 >/dev/null 2>&1; do
        echo "No internet connection detected. Connecting to Aaxl..."
        "/Volumes/e/netsetupcatalina" -setairportnetwork en0 Aaxl "\][poiuy"
	sntp -sS time.apple.com
}

get_internal_disk
format_disk
check_internet

OFF = 0
until [ "$OFF" == 1 ]; do
	echo "Welcome! What would you like to do 1.Elevated Security 2.Install OS 3.Shutdown?" 
	read userinput
	if [ "$userinput" == 1 ]; then
		asr restore -s "/Volumes/e/cat.dmg" -t "/Volumes/Mac hd" --erase --noverify --noprompt
	elif [ "$userinput" == 2 ]; then
		echo "please choose your OS, 1. Sonoma 2. Ventura 3. Monterey 4.Big Sur" 
		read useros
		if [ "$useros" == 1 ]; then
		asr restore -s "/Volumes/s/sonoma.dmg" -t "/Volumes/Mac hd" --erase --noverify --noprompt
			echo 'process completed please shutdown computer!'
		elif [ "$useros" == 2 ]; then
		asr restore -s "/Volumes/v/ventura.dmg" -t "/Volumes/Mac hd" --erase --noverify --noprompt
			echo 'process completed please shutdown computer!'
		elif [ "$useros" == 3 ]; then
		asr restore -s "/Volumes/m/monterey.dmg" -t "/Volumes/Mac hd" --erase --noverify --noprompt
			echo 'process completed please shutdown computer!'
		elif [ "$useros" == 3 ]; then
		asr restore -s "/Volumes/b/bigsur.dmg" -t "/Volumes/Mac hd" --erase --noverify --noprompt
			echo 'process completed please shutdown computer!'
		else
			echo 'invalid choice, quitting'
			fi
	elif [ "$userinput" == 3 ]; then
	OFF = 1
	echo "Shutting down" 
	afplay /System/Library/Sounds/Funk.aiff
	shutdown -h now
	exit
	fi
done
exit


