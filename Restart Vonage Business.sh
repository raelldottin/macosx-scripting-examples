#!/bin/zsh

loggedInUser=$(stat -f%Su /dev/console)
loggedInUID=$(id -u "$loggedInUser")
processName="Vonage Business"
appPath="/Applications/Vonage Business.app"
pidPath="/tmp/$processName.pid"

while [[ $(pgrep "$processName") ]]
do
	if [[ ! -e "$pidPath" ]]
	then
		touch "$pidPath"
	fi
	pkill "$processName"
done

sleep 5
xattr -d -r com.apple.quarantine "$appPath"

if [[ "$loggedInUser" != "root" ]] || [[ "$loggedInUID" -ne 0 ]]
then
 	if [[ -e "$pidPath" ]]
    then 
		/bin/launchctl asuser "$loggedInUID" sudo -iu "$loggedInUser" open -a "$processName"
		rm -f "$pidPath"
	fi
fi
