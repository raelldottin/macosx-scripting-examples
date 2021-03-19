#!/bin/zsh

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
if [[ -d "$appPath" ]]
then
	rm -r -f "$appPath"
fi