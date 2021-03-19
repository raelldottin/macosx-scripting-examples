#!/bin/zsh

download_os_installer () {
	if [[ -d "/Install macOS Catalina.app" ]] || [[ -d "/Applications/Install macOS Catalina.app" ]] || [[ -d "/Users/Shared/Previously Relocated Items/Security/Install macOS Catalina.app" ]]
	then
		logger -is "Installer macOS Catalina.app found."
	else
		logger -is "Attemping to download the macOS installer from Apple Software Servers: /usr/sbin/softwareupdate --fetch-full-installer --full-installer-version 10.15.3 2>/dev/null"
		/usr/sbin/softwareupdate --fetch-full-installer --full-installer-version 10.15.3 2>/dev/null
		sleep 30
		if [[ -d "/Install macOS Catalina.app" ]] || [[ -d "/Applications/Install macOS Catalina.app" ]] || [[ -d "/Users/Shared/Previously Relocated Items/Security/Install macOS Catalina.app" ]]
		then
			logger -is "Installer macOS Catalina.app found."
   		else 
			logger -is "Fail downloading installer using softwareupdate: /usr/sbin/softwareupdate --fetch-full-installer --full-installer-version 10.15.3 2>/dev/null"
        		logger -is "Attempting to download the installer from Jamf Cloud."
        		/usr/local/jamf/bin/jamf policy -event osinstaller
			until [[ $? == 0 ]]
			do
           			sleep 30
        			logger -is "Attempting to download the installer from Jamf Cloud."
				/usr/local/jamf/bin/jamf policy -event osinstaller
        		done
		fi
	fi
}

erase_install_os () {
	if [[ "$(diskutil info / | grep Personality | awk -F':' '{print $NF }' | sed -e 's/^[[:space:]]*//')" == "APFS" ]] && (( $(sw_vers -productVersion |sed -n -e 's/^...\(..\)../\1/p') >= 13 ))
	then
		while [[ $(pgrep "Install macOS Catalina") ]]
		do
			logger -is "Attempting to quit \"Install macOS Catalina.app\" if it's currently running."
			pkill -9 "Install macOS Catalina"
		done
		logger -is "Attempting to find and execute the startosinstall binary"
		if [[ -d "/Install macOS Catalina.app" ]]
		then
			/Install\ macOS\ Catalina.app/Contents/Resources/startosinstall --agreetolicense --eraseinstall --forcequitapps
		elif [[ -d "/Applications/Install macOS Catalina.app" ]]
		then
			/Applications/Install\ macOS\ Catalina.app/Contents/Resources/startosinstall --agreetolicense --eraseinstall --forcequitapps
		elif [[ -d "/Users/Shared/Previously Relocated Items/Security/Install macOS Catalina.app" ]]
		then
			/Users/Shared/Previously\ Relocated\ Items/Security/Install\ macOS\ Catalina.app/Contents/Resources/startosinstall --agreetolicense --eraseinstall --forcequitapps
		else
			logger -is "Files system: $(diskutil info / | grep Personality | awk -F':' '{print $NF }' | sed -e 's/^[[:space:]]*//')"
			logger -is "Operating System: $(sw_vers -productVersion)"
			logger -is "Attempting to call jamf policy -event osupgrade"
			/usr/local/jamf/bin/jamf policy -event osupgrade
			until [[ $? == 0 ]]
			do
				sleep 30
				/usr/local/jamf/bin/jamf policy -event osupgrade
			done
		fi
	fi
}

if [[ ! "$(scutil --get ComputerName)" =~ UPGRADE* ]]
then
        logger -is "This computer should not get upgraded"
        for i in {1..3}
        do
                /usr/local/jamf/bin/jamf recon
        done
        exit 1
fi

download_os_installer
erase_install_os
