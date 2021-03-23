#!/bin/bash

# A quick prototype for automating overflow software installs on macOS

# Or we can use overflow cask in Homebrew
# brew install --cask protoio-overflow
# https://raw.githubusercontent.com/Homebrew/install/master/install.sh -- we can use this script for inspiration

# Todo List:
# Figure out how to determine the download link dynamically
# Add error checking for each command with failbacks or clean up routines
# Include logging of the installation process

# Script Requirements: bash, curl, hdiutil, pkill, rm, cp, chown, xattr, python (no specific version required), (root privileges)
# we can write a routine to make sure the target system has the required utilities before beginning

# Global variables
mountPoints=()

PrintLog()
{
    local message=$1
# We can use logger to log to syslog then output the same message to standard out with UTC Timestamps.
# logger only outputs at current timezone.

    logger -i "$message"
    echo "$(date -u):$whoami[$$] $message" 
}

DetachVolumes()
{
    for ((i = 0; $i < ${#mountPoints[@]}; i++)); do
        if hdiutil detach $(echo ${mountPoints[$i]}|sed -r 's#([^/].*[^/])/[^/].*#\1#'); then
            PrintLog "Detaching mount point: $(echo ${mountPoints[$i]}|sed -r 's#([^/].*[^/])/[^/].*#\1#')"
        else
            PrintLog "Failed to detach mount point : $(echo ${mountPoints[$i]}|sed -r 's#([^/].*[^/])/[^/].*#\1#')"
        fi
    done
}

CleanUpExit ()
{
    DetachVolumes
    PrintLog "We should do something interesting here."
    PrintLog "Goodbye."
    exit 1

}

# /private/etc/rc.common has a function to check if a network is up, I would like to reuse it here
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

    PrintLog "Searching for mountpoints."

    while IFS=  read -r -d $'\0'; do
        mountPoints+=("$REPLY"); 
    done < <(find /Volumes -name "Overflow.app" -print0)

    for ((i = 0; $i < ${#mountPoints[@]}; i++)); do
            PrintLog "Mount point: ${mountPoints[$i]}"
    done

    if [[ ${#mountPoints[@]} -gt 1 ]]; then
        PrintLog "Multiple versions of Overflow.app mount points detected."
    fi
    # This only check if the app version is already installed. We should perform a regex against the version numbers to determine if the download app is newer than the installed version.

    if [[ -d /Applications/Overflow.app ]]; then
        PrintLog "Installed App Version: $(defaults read /Applications/Overflow.app/Contents/Info.plist CFBundleVersion)"
        for ((i = 0; $i < ${#mountPoints[@]}; i++)); do
            PrintLog "Downloaded App Version: $(defaults read "${mountPoints[$i]}/Contents/Info.plist" CFBundleVersion)"
            if [[ $(defaults read "${mountPoints[$i]}/Contents/Info.plist" CFBundleVersion) == $(defaults read /Applications/Overflow.app/Contents/Info.plist CFBundleVersion) ]]; then
                PrintLog "Overflow app version $(defaults read /Applications/Overflow.app/Contents/Info.plist CFBundleVersion) is already installed."
                PrintLog "Unsetting element ${mountPoints[$i]}"
                unset 'mountPoints[$i]'
                # maybe it's a better idea to unset the variable
            fi
        done

        if [[ ${#mountPoints[@]} -eq 0 ]]; then
            CleanUpExit
        fi

        # Lets have some fun, let's pop item from the array if it's a lower version
    fi
    IFS=$OLDIFS
}


whoami=$(stat -f %Su /dev/console)

# Create a log function that handles messages for logger
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
# How do we know where the dmg file is attached, will the volume always have the same name?
if hdiutil attach /tmp/download.dmg -nobrowse -quiet; then
    PrintLog "Attach the Overflow dmg file."
else
    PrintLog "Failed to attached dmg file"
    CleanUpExit
fi



# Perform a check to see if the version of the app inside the dmg matches the installed app, then clean up and exit if it does
LocateMountedApp

# Let's check if the application is still running before terminating it
# If we are performing a fresh install, are user preferences or licensing preferences stored in the application file?
# Let's confirm that the application actually quits
while [[ $(pgrep "Overflow") ]]; do
    PrintLog "Terminating pid $(pgrep Overflow)"
    pkill "Overflow"
done

# Check if the app is already install, delete the previous version before installation
# Should place the application name as a variable
# Should we consider different error codes for each exit status?

if [[ -d "/Applications/Overflow.app" ]]; then
    PrintLog "Removing previous application installation."  
    if rm -fr /Applications/Overflow.app; then
        PrintLog "Successfully removed the prevous installation."
    else
        PrintLog "Failed to remove previous installation."
        CleanUpExit
    fi
fi

# Copy the new app version to the Application folder
# Overflow will prompt you to install it in the /Applications folder if you install it elsewhere
# should we use rsync, so we can resume if the file copy get interrupted?

if cp -R ${mountPoints[0]} /Applications/; then
    PrintLog "Copied Overflow.app to /Applications folder."
else
    PrintLog "Failed to copy Overflow.app from ${mountPoints[0]} /Applications folder."
    PrintLog "Please run this script as root."
    CleanUpExit
fi

# Detach the Volume
DetachVolumes

# Change permissions on the app bundle -- Note, the installation still need root access to install the app into the application folder.
if chown -R $whoami:staff /Applications/Overflow.app; then
    PrintLog "Providing $whoami with access to /Applications/Overflow.app"
else
    PrintLog "Failed to provide $whoami with access to /Applications/Overflow.app"
fi
# Remove quarantine flag, this might randomly return an error
if xattr -r -d com.apple.quarantine /Applications/Overflow.app; then
    PrintLog "Removed quarantine flag on Overflow.app"
else
    PrintLog "Unable to remove the quarantine flag on Overflow.app"
fi

PrintLog "Installation Successful."