#!/bin/bash 
cd ../../
OFF = 0

#format drive
diskutil  unmountDisk force disk0
diskutil eraseDisk APFS Macintosh\ HD disk0

until [ "$OFF" == 1 ]; do
	echo "Welcome! What would you like to do 1.Elevated Security 2.Install OS 3.Restart?" 
	read userinput
	
	#Elevated Security
	if [ "$userinput" == 1 ]; then
		echo "Elevated Security"
		echo "Checking for internet connection"
		while !( ping 1.1.1.1 -c 1 >/dev/null ); do
			echo "no internet connection detected"
			read -n 1 -s -r -p "Please connect to the internet then press enter:   "
		done
		echo "Internet connection detected"
		echo "Running ASR"
		
		if asr restore -s "/Volumes/ASR/cat.dmg" -t "/Volumes/Macintosh HD" --erase --noverify --noprompt; then
			echo "restarting"
			pmset -a restoredefaults && nvram -c && reboot
		fi
	
	#Install OS
	elif [ "$userinput" == 2 ]; then
		userOS=0
		userMethod=0
		echo "Please choose your OS: 1. Sequoia 2. Sonoma 3. Ventura 4. Monterey 5.Big Sur" 
		read userOS
		echo "Please choose your installation method: 1. ASR 2. Manual install"
		read userMethod

		#Sequoia
		if (( "$userOS" == 1 &&  "$userMethod" == 1 )); then
			echo "Sequoia ASR install"
			echo "Checking for internet connection"
			while !( ping 1.1.1.1 -c 1 >/dev/null ); do
				echo "no internet connection detected"
				read -n 1 -s -r -p "Please connect to the internet then press enter:   "
			done
			echo "Internet connection detected"
			echo "Running ASR"
			if asr restore -s "/Volumes/ASR/sequoia.dmg" -t "/Volumes/Macintosh HD" --erase --noverify --noprompt; then
				echo "restarting"
				pmset -a restoredefaults && nvram -c && reboot
			fi
		elif (( "$userOS" == 1  &&  "$userMethod" == 2 )); then
			echo "Sequoia manual install"
			./Volumes/FULL/Applications/Install\ macOS\ Sequoia.app/Contents/MacOS/InstallAssistant

		#Sonoma
		elif (( "$userOS" == 2 && "$userMethod" == 1 )); then
			echo "Sonoma ASR install"
			if asr restore -s "/Volumes/ASR/sonoma.dmg" -t "/Volumes/Macintosh HD" --erase --noverify --noprompt; then
				echo "restarting"
				pmset -a restoredefaults && nvram -c && reboot
			fi
		elif (( "$userOS" == 2 & "$userMethod" == 2 )); then
			echo "Sonoma manual install"
			./Volumes/FULL/Applications/Install\ macOS\ Sonoma.app/Contents/MacOS/InstallAssistant
			
		#Ventura
		elif (( "$userOS" == 3 & "$userMethod" == 1 )); then
			echo "Ventura ASR install"
			if asr restore -s "/Volumes/ASR/ventura.dmg" -t "/Volumes/Macintosh HD" --erase --noverify --noprompt; then
				echo "restarting"
				pmset -a restoredefaults && nvram -c && reboot
			fi
		elif (( "$userOS" == 3 & "$userMethod" == 2 )); then
			echo "Ventura manual install"
			./Volumes/FULL/Applications/Install\ macOS\ Ventura.app/Contents/MacOS/InstallAssistant
			
		#Moneterey
		elif (( "$userOS" == 4 & "$userMethod" == 1 )); then
			echo "Monterey ASR install"
			if asr restore -s "/Volumes/ASR/monterey.dmg" -t "/Volumes/Macintosh HD" --erase --noverify --noprompt; then
				echo "restarting"
				pmset -a restoredefaults && nvram -c && reboot
			fi
		elif (( "$userOS" == 4 & "$userMethod" == 2 )); then
			echo "Monterey manual install"
			./Volumes/FULL/Applications/Install\ macOS\ Monterey.app/Contents/MacOS/InstallAssistant
		
		#Big Sur
		elif (( "$userOS" == 5 & "$userMethod" == 1 )); then
			echo "Big Sur ASR install"
			if asr restore -s "/Volumes/ASR/bigsur.dmg" -t "/Volumes/Macintosh HD" --erase --noverify --noprompt; then
				echo "restarting"
				pmset -a restoredefaults && nvram -c && reboot
			fi
		elif (( "$userOS" == 5 & "$userMethod" == 2 )); then
			echo "Big Sur manual install"
			./Volumes/FULL/Applications/Install\ macOS\ Big\ Sur.app/Contents/MacOS/InstallAssistant

		else
			echo "invalid choice"
			
		fi


	#Shutdown
	elif [ "$userinput" == 3 ]; then
	OFF = 1
	
	echo "Restarting" 
	pmset -a restoredefaults && nvram -c && reboot	

	exit
	fi
done
exit
