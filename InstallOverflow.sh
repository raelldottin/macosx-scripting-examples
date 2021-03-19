#!/bin/bash

# A quick prototype for automating overflow software installs on macos

# Or we can use overflow cask in homebrew
# First install Homebrew if it's not already installed
# Security considers must be consider if HomeBrew is not already being used.
# brew install --cask protoio-overflow
#

# Todo List:
# Figure out how to determine the download link dynamically
# Add error checking for each command with failbacks or clean up routines
# Include logging of the installation process

# Script Requirements: bash, curl, hdiutil, pkill, rm, cp, chown, xattr, python (no specific version required), (root priviledges)
# we can write a routine to make sure the target system has the required utilities before beginning


#We can automated the file download using Google Chrome using Puppeteer
#https://tutorialzine.com/2017/08/automating-google-chrome-with-node-js
#https://developers.google.com/web/tools/puppeteer

# /private/etc/rc.common has a function to check if network is up, I would like to reuse it here

PrintLog()
{
    local message=$1
# We can use logger to log to syslog then output the same message to standard out with UTC Timestamps.
# logger only output at current timezone.

    logger -i "$message"
    echo "$(date -u):$whoami[$$] $message" 
}

CleanUpExit ()
{
    PrintLog "We should do something interesting here."
    PrintLog "Good bye."
    exit 1

}

CheckForNetwork()
{
    local test

    if [[ -z "${NETWORKUP:=}" ]]; then
        test=$(ifconfig -a inet 2>/dev/null | sed -n -e '/127.0.0.1/d' -e '/0.0.0.0/d' -e '/inet/p' | wc -l)
        if [[ "${test}" -gt 0 ]]; then
           PrintLog "Network is up."
        else
            PrintLog "Network is down."
            CleanUpExit
        fi
    fi
}

LocateMountedApp()
{
    OLDIFS=$IFS
    set +m
    shopt -s lastpipe
    mountPoints=()
    find /Volumes -name "Overflow.app" -print0 | while IFS=  read -r -d $'\0'; do
        mountPoints+=("$REPLY")
    done

    if [[ ${#mountPoints[@]} -gt 1 ]]; then
        PrintLog "Mutliple versions of Overflow.app detected."
    fi
    # Should we perform a check in here against each Volume found with the app to see if version is greater than the app is installed and go with the higher version?
    # We should perform a regex against the version numbers to determine if download app is newer than the installed version (if the app is installed)

    if [[ -d /Applications/Overflow.app ]]; then
        PrintLog "Installed App Version: $(defaults read /Applications/Overflow.app/Contents/Info.plist CFBundleVersion)"
        for ((i = 0; $i < ${#mountPoints[@]}; i++)); do
            PrintLog "Downloaded App Version: $(defaults read "${mountPoints[$i]}/Contents/Info.plist" CFBundleVersion)"
            if [[ $(defaults read "${mountPoints[$i]}/Contents/Info.plist" CFBundleVersion) == $(defaults read /Applications/Overflow.app/Contents/Info.plist CFBundleVersion) ]]; then
                PrintLog "Overflow app version $(defaults read /Applications/Overflow.app/Contents/Info.plist CFBundleVersion) is already installed."
                local delete=${mountPoints[$i]}
                mountPoints=( "${mountPoints[@]/$delete}" )
            fi
        done

        if [[ ${#mountPoints[@]} -eq 0 ]]; then
            CleanUpExit
        fi

        # Lets have some fun, let's pop item from the array if it's a lower version
    fi
    IFS=$OLDIFS
}


whoami=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')

# Create a log function that handle messages for logger
PrintLog "$whoami is currently logged in."

# Do we re-attempt file download if the download fails or give up one try and declare failure?

CheckForNetwork

PrintLog "Downloading file to /tmp/download.dmg"
if curl -s 'https://app-updates.overflow.io/packages/updates/osx_64/01800abc7f858990a2f4267e811d430c48f9469b/Overflow-1.16.2.dmg' -o /tmp/download.dmg; then
    PrintLog "Overflow dmg file downloaded successfully."
else
    PrintLog "Failed to download dmg file."
    CleanUpExit
fi

PrintLog "Attaching downloaded file."
# How do when know where the dmg file is attached, will the volume always have the same name?
if hdiutil attach /tmp/download.dmg --nobrowse --quiet; then
    PrintLog "Attach the Overflow dmg file."
else
    PrintLog "Failed to attached dmg file"
    CleanUpExit
fi



# Perform a check to see if the version of the app inside the dmg matches the installed app, then clean up and exit if it does
LocateMountedApp

# Let's check if the application is still running before terminating it
# If we are performing a fresh install are user preferences or licensing preferences stored in the application file?
# Let's confirm that the application actually quits
echo "$(date -u): closing application "
pkill "Overflow"

# Check if the app is already install, delete the previous version prior to installation
echo "$(date -u): removing application "
rm -fr /Applications/Overflow.app

# Copy the new app version to the Application folder
# Overflow will prompt you to install it in the /Applications folder if you install it else where
echo "$(date -u): copying application"
cp -R $mountPOints/Overflow.app /Applications/

# Detach the Volume
echo "$(date -u): detaching downloaded file"
hdiutil detach /Volumes/Overflow

# Change permissions on the app bundle -- Note, the installation still need root access to install the app into the application folder.
echo "$(date -u): providing $whoami with access to /Applications/Overflow.app"
chown -R $whoami:staff /Applications/Overflow.app

# Remove quarantine flag
echo "$(date -u): removing quarantine flg on Overflow.app if its set"
xattr -r -d com.apple.quarantine /Applications/Overflow.app