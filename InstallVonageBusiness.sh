#!/bin/zsh

downloadURL="https://vbc-downloads.vonage.com/mac/VonageBusinessSetup.dmg"
loggedInUser=$(stat -f %Su "/dev/console")
loggedInUID=$(id -u "$loggedInUser")
PRODUCT="Vonage Business"
appName="/Applications/Vonage Business.app"

if [[ ! -e "$appName" ]]
then
    version=$(defaults read "$appName/Contents/Info.plist" CFBundleVersion)
    echo "$PRODUCT is installed running version: $version"
else
    echo "$appName is not installed."
    echo "`date`: Installing $PRODUCT for $loggedInUser"
    dmgFile="vbimage.dmg"
    volName="Vonage Business 2.8.4"
    echo "`date`: Downloading $PRODUCT."
    curl -k -o /tmp/$dmgfile $downloadURL
    echo "`date`: Mounting installer disk image."
    hdiutil attach /tmp/$dmgfile -nobrowse -quiet
    echo "`date`: Installing $PRODUCT"
    while [[ $(pgrep "$PRODUCT") ]]
    do
        pkill "$PRODUCT"
    done
    if [[ -d "$appName" ]]
    then
        rm -r -f "$appName"
    fi
    cp -R "/Volumes/$volName/`basename $appName`" /Applications/
    sleep 3
    echo "`date`: Unmounting installer disk image"
    hdiutil detach $(/bin/df | /usr/bin/grep "${volName}" | awk '{print $1}') -quiet
    sleep 3
    while [[ $(pgrep "$PRODUCT") ]]
    do
        pkill "$PRODUCT"
    done
    xattr -r -d com.apple.quarantine "$appName"
    sleep 3
    launchctl asuser "$loggedInUID" sudo -iu "$loggedInUser" open "$appName"
fi