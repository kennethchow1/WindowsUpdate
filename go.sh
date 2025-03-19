#!/bin/bash 


# macOS Installation and Elevated Security Removal Tool
# v2.1-beta
# https://github.com/nkerschner/macOSDrives

cd /
userQuit=0

# declare default paths
ASR_IMAGE_PATH="/Volumes/ASR/"
INSTALLER_VOLUME_PATH="/Volumes/FULL/Applications/"
ES_SOURCE_PATH="/Volumes/ASR/cat.dmg"
INTERNAL_VOLUME_NAME="Macintosh HD"
INTERNAL_VOLUME_PATH="/Volumes/Macintosh HD"


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
        echo "No internet connection detected."
        read -n 1 -s -r -p "Please connect to the internet then press enter: "
    done
    echo "Internet connection detected."
}

# Perform ASR restore
run_asr_restore() {
    local source_image=$1
    if asr restore -s "$source_image" -t "$INTERNAL_VOLUME_PATH" --erase --noverify --noprompt; then
        echo "ASR restore successful. Restarting..."
        restart_system
    else
        echo "ASR restore failed! Please check the source image and try again."
    fi
}

# Perform install through application
run_manual_install() {
    local installer_path="$1"
    echo "Starting manual install"
    "$INSTALLER_VOLUME_PATH$installer_path/Contents/Resources/startosinstall" --agreetolicense --volume "$INTERNAL_VOLUME_PATH"
}

# Elevated Security
elevated_security() {
    check_internet
    run_asr_restore "$ES_SOURCE_PATH"
}

# Prompt for OS selection
select_os() {
    
    echo 
    echo "Please choose your OS:"
    for key in $(echo ${!os_names[@]} | tr ' ' '\n' | sort -n); do
        echo "$key: ${os_names[$key]}"
    done
    read userOS
    
    while ! [[ "$userOS" =~ ^[1-7]$ ]]; do
        echo "Invalid selection. Please enter a number from 1 to ${#os_names[@]}."
        read userOS
    done
}

# Prompt for installation method
select_install_method() {
    
    if [ $userOS -le 5 ] ; then
        echo
        echo "Choose installation method: 1. ASR 2. Manual install"
        read userMethod
        while ! [[ "$userMethod" =~ ^[1-2]$ ]]; do
            echo "Invalid selection. Please enter 1 for ASR or 2 for Manual install."
            read userMethod
        done
    else 
        userMethod=2
    fi
}

# Install macOS
install_os() {
    # Create associative arrays for file paths
    declare -a asr_images
    asr_images[1]="sequoia.dmg"
    asr_images[2]="sonoma.dmg"
    asr_images[3]="ventura.dmg"
    asr_images[4]="monterey.dmg"
    asr_images[5]="bigsur.dmg"
    
    declare -a installers
    installers[1]="Install macOS Sequoia.app"
    installers[2]="Install macOS Sonoma.app"
    installers[3]="Install macOS Ventura.app"
    installers[4]="Install macOS Monterey.app"
    installers[5]="Install macOS Big Sur.app"
    installers[6]="Install macOS Catalina.app"
    installers[7]="Install macOS High Sierra.app"

    
    declare -a os_names
    os_names[1]="Sequoia"
    os_names[2]="Sonoma"
    os_names[3]="Ventura"
    os_names[4]="Monterey"
    os_names[5]="Big Sur"
    os_names[6]="Catalina"
    os_names[7]="High Sierra"  

    select_os
    select_install_method

    
    echo "==== starting OS installation ===="    


    # For Sequoia installation, check internet connection first
    if [[ "$userOS" == 1 ]]; then
        check_internet
    fi
    
    if [[ "$userMethod" == 1 ]]; then
        echo "${os_names[$userOS]} ASR install"
        run_asr_restore "$ASR_IMAGE_PATH${asr_images[$userOS]}"
    elif [[ "$userMethod" == 2 ]]; then
        echo "selected ${os_names[$userOS]} manual install"
        run_manual_install "${installers[$userOS]}"
    fi
}

# Restart system after resetting SMC and clearing NVRAM
restart_system() {
    echo "Restarting..."
    pmset -a restoredefaults && nvram -c
    reboot
    
    #try harder if didn't restart after 30 seconds
    sleep 30
    echo "Attempting restart again"
    reboot -q

    exit
}

# Quit the script
quit_script() {
    echo "Exiting script..."
    userQuit=1  # Ensures the loop in main_menu exits cleanly
}

# Main Menu Function
main_menu() {
    until [ "$userQuit" = 1 ]; do
        echo 
        echo "===== macOS Installation and Recovery Tool ====="
        echo "1. Elevated Security"
        echo "2. Install OS"
        echo "3. Restart System"
        echo "4. Quit"
        echo "================================================"
        read -p "Enter your choice (1-4): " userinput

        case $userinput in
            1) elevated_security ;;
            2) install_os ;;
            3) restart_system ;;
            4) quit_script ;;
            *) echo "Invalid choice. Please enter 1, 2, 3, or 4." ;;
        esac
    done
}

# Run the script
get_internal_disk
format_disk
main_menu

