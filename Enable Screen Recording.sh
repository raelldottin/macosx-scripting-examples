#!/bin/bash

loggedInUser=$(stat -f%Su /dev/console)
loggedInUID=$(id -u "$loggedInUser")

if [[ "$loggedInUser" != "root" ]] || [[ "$loggedInUID" -ne 0 ]]
then
	if [[ -e "/Library/PrivilegedHelperTools/scthostp" ]] && [[ -e "/System/Volumes/Data/Library/PrivilegedHelperTools/scthost.app/Contents/Resources/scthostp" ]]
    then
	tccutil reset AppleEvents
	fi
    /bin/launchctl asuser "$loggedInUID" sudo -iu "$loggedInUser" /usr/bin/osascript -s o <<EOF
tell application "System Preferences"
	activate
	reveal anchor "Privacy" of pane id "com.apple.preference.security"
end tell

tell application "System Events"
	get visible of process "System Preferences"
	repeat until visible of process "System Preferences" is true
		set visible of process "System Preferences" to false
	end repeat
end tell


tell application "System Events"
	tell application process "System Preferences"
		repeat while not (window 1 exists)
		end repeat
		tell window 1
			repeat while not (rows of table 1 of scroll area 1 of tab group 1 exists)
			end repeat
			select row 13 of table 1 of scroll area 1 of tab group 1
			repeat with UIElement in (rows of table 1 of scroll area of group 1 of tab group 1)
				set UICheckbox to value of checkbox 1 of UI element of UIElement
				tell UICheckbox
					if UICheckbox ≤ 0 then click checkbox 1 of UI element of UIElement
				end tell
			end repeat
			repeat while (button "Later" of sheet 1 exists)
				try
					-- click the Quit Now button for macOS Catalina
					click button "Quit Now" of sheet 1
				on error errStr number errrorNumber
					-- click the Quit & Reopen button for macOS Big Sur
					click button "Quit & Reopen" of sheet 1
				end try
			end repeat
		end tell
	end tell
end tell

tell application "System Preferences"
	quit
end tell
EOF
fi