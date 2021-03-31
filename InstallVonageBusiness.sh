#!/bin/bash

# A quick prototype for automating software installs on macOS

# Usage: ./InstallVonageBusiness.sh


# Todo List:
# Figure out how to determine the download link dynamically [x]
# Add error checking for each command with fallback or clean up routines [x]
# Include logging of the installation process [x]

# Script Requirements: bash, curl, hdiutil, pkill, rm, cp, chown, xattr, (root or admin privileges to copy the app bundle into the Application folder)

#Set command search path
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/libexec:/System/Library/CoreServices; export PATH
CURL_BIN=/usr/bin/curl
HDIUTIL_BIN=/usr/bin/hdiutil
PKILL_BIN=/usr/bin/pkill
RM_BIN=/bin/rm
CP_BIN=/bin/cp
CHOWN_BIN=/usr/sbin/chown
XATTR_BIN=/usr/bin/xattr
LOGGER_BIN=/usr/bin/logger
SED_BIN=/usr/bin/sed

#Set sed options for BSD sed vs GNU sed
if echo ""|$SED_BIN -r "s/.*//" 2>/dev/null 1>&2; then
    SED_OPTS="-r"
else
    SED_OPTS="-E"
fi

# Global variables
mountPoints=()
appName="Vonage Business.app"
installPath="/Applications"
downloadFile="/tmp/download.dmg"
downloadURL="https://m.vona.ge/getMAC"

PrintLog()
{
    local message=$1
# We can use logger to log to syslog then output the same message to standard out with UTC Timestamps.
# logger only outputs at current timezone.

    $LOGGER_BIN -i "$message"
    echo "$(date -u):$whoami[$$] $message" 
}

DetachVolumes()
{
    # Evaluate a better way to perform this check.
    if [[ ! -z $1 ]]; then
        if $HDIUTIL_BIN detach "$(echo $1|$SED_BIN $SED_OPTS 's#([^/].*[^/])/[^/].*#\1#')" -quiet; then
            PrintLog "Detaching mount point: $(echo $1|$SED_BIN $SED_OPTS 's#([^/].*[^/])/[^/].*#\1#')"
        else
            PrintLog "Failed to detach mount point : $(echo ${mountPoints[$i]}|$SED_BIN $SED_OPTS 's#([^/].*[^/])/[^/].*#\1#')"
        fi
    else
        for ((i = 0; $i < ${#mountPoints[@]}; i++)); do
            if $HDIUTIL_BIN detach "$(echo ${mountPoints[$i]}|$SED_BIN $SED_OPTS 's#([^/].*[^/])/[^/].*#\1#')" -quiet; then
                PrintLog "Detaching mount point: $(echo ${mountPoints[$i]}|$SED_BIN $SED_OPTS 's#([^/].*[^/])/[^/].*#\1#')"
            else
                PrintLog "Failed to detach mount point : $(echo ${mountPoints[$i]}|$SED_BIN $SED_OPTS 's#([^/].*[^/])/[^/].*#\1#')"
            fi
        done
    fi
}

CleanUpExit ()
{
    DetachVolumes
    if [[ -f $downloadFile ]]; then
        $RM_BIN $downloadFile
    fi
    PrintLog "Rolling back installation."
    PrintLog "Exiting..."
    exit 1

}

CheckForNetwork()
{
    local test

    if [[ -z "${NETWORKUP:=}" ]]; then
        test=$(/sbin/ifconfig -a inet 2>/dev/null | $SED_BIN -n -e '/127.0.0.1/d' -e '/0.0.0.0/d' -e '/inet/p' | wc -l)
        if [[ "${test}" -gt 0 ]]; then
            PrintLog "Network is up."
        else
            PrintLog "Network is down."
            CleanUpExit
        fi
        test=$(/usr/bin/dig +short $(echo "$downloadURL"| $SED_BIN -e 's|^[^/]*//||' -e 's|/.*$||') | wc -l)
        if [[ "${test}" -gt 0 ]]; then
            PrintLog "DNS is up."
        else
            PrintLog "DNS is down."
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
    done < <(find /Volumes -name "$appName" -print0)

    # Added a debug flag and execute the for loop below if its set.
    #for ((i = 0; $i < ${#mountPoints[@]}; i++)); do
    #        PrintLog "Mount point: ${mountPoints[$i]}"
    #done

    if [[ ${#mountPoints[@]} -gt 1 ]]; then
        PrintLog "Multiple versions of $appName mount points detected."
    fi
    # This only check if the app version is already installed. We should perform a regex against the version numbers to determine if the download app is newer than the installed version.

    if [[ -d "$installPath/$appName" ]]; then
        PrintLog "Installed App Version: $(defaults read "$installPath/$appName/Contents/Info.plist" CFBundleVersion)"
        for ((i = 0; $i < ${#mountPoints[@]}; i++)); do
            PrintLog "Downloaded App Version: $(defaults read "${mountPoints[$i]}/Contents/Info.plist" CFBundleVersion)"
            if [[ $(defaults read "${mountPoints[$i]}/Contents/Info.plist" CFBundleVersion) == $(defaults read "$installPath/$appName/Contents/Info.plist" CFBundleVersion) ]]; then
                PrintLog "$appName version $(defaults read "$installPath/$appName/Contents/Info.plist" CFBundleVersion) is already installed."
                DetachVolumes "${mountPoints[$i]}"
                unset 'mountPoints[$i]'
            fi
        done

        if [[ ${#mountPoints[@]} -eq 0 ]]; then
            CleanUpExit
        fi

    fi
    IFS=$OLDIFS
}

whoami=$(/usr/bin/stat -f %Su /dev/console)
PrintLog "$whoami is currently logged in."
PrintLog "$(whoami) is currently executing $0"

if [[ $(whoami) != "root" ]]; then
    if groups $(whoami) | grep -q -w admin; then
        PrintLog "$(whoami) has administrative rights. Proceeding with installation."
    else
        PrintLog "$(whoami) does not have administrative privileges Proceeding with installation."
        CleanUpExit
    fi
fi

# Do we re-attempt file download if the download fails or give up one try and declare failure?

CheckForNetwork

PrintLog "Downloading file to $downloadFile"
if  $CURL_BIN -sL "$downloadURL" -o $downloadFile; then
    PrintLog "$appName dmg file downloaded successfully."
else
    PrintLog "Failed to download the $appName dmg file."
    CleanUpExit
fi

if [[ $(file $downloadFile) =~ "gzip" ]]; then
    if mv $downloadFile $downloadFile.gz; then
        if gunzip "$downloadFile.gz"; then
            PrintLog "Decompressed the $downloadFile.gz file."
        else
            PrintLog "Failed to decompress the $downloadFile.gz file."
            CleanUpExit
        fi
    fi
fi

PrintLog "Attaching the $appName dmg file."
# How do we know where the dmg file is attached, will the volume always have the same name?
if $HDIUTIL_BIN attach "$downloadFile" -nobrowse -quiet; then
    PrintLog "Attached the $appName dmg file."
else
    PrintLog "Failed to attached the $appName dmg file"
    CleanUpExit
fi

# Perform a check to see if the version of the app inside the dmg matches the installed app, then clean up and exit if it does
LocateMountedApp

# Let's check if the application is still running before terminating it
# If we are performing a fresh install, are user preferences or licensing preferences stored in the application file?
# Let's confirm that the application actually quits
while [[ $(pgrep "$appName") ]]; do
    if $PKILL_BIN "$appName"; then
        PrintLog "Successfully terminated $appName."
    else
        PrintLog "Failed to terminate $appName"
    fi
    sleep 1
done

# Check if the app is already install, delete the previous version before installation
# Should place the application name as a variable
# Should we consider different error codes for each exit status?

if [[ -d "$installPath/$appName" ]]; then
    PrintLog "Removing previous application installation."
    # Let's reconsider removing directories and copy the file over to /tmp in a timestamp directory  
    if $RM_BIN -fr "$installPath/$appName"; then
        PrintLog "Successfully removed the prevous installation."
    else
        PrintLog "Failed to remove previous installation."
        CleanUpExit
    fi
fi

# Copy the new app version to the Application folder
# should we use rsync, so we can resume if the file copy get interrupted?

#if $CP_BIN -R "${mountPoints[0]}" "$installPath/"; then
if rsync -azq "${mountPoints[0]}" "$installPath/"; then
    PrintLog "Copied $appName to $installPath folder."
else
    PrintLog "Failed to copy $appName from ${mountPoints[0]} /Applications folder."
    PrintLog "Please run this script as root or user in the admin group."
    CleanUpExit
fi

# Detach the Volume
DetachVolumes

# Change permissions on the app bundle -- Note, the installation still need root access to install the app into the application folder.
if $CHOWN_BIN -R $whoami:staff "$installPath/$appName"; then
    PrintLog "Providing $whoami with access to $installPath/$appName"
else
    PrintLog "Failed to provide $whoami with access to $installPath/$appName"
fi
# Remove quarantine flag, this might randomly return an error
if $XATTR_BIN -r -d com.apple.quarantine "$installPath/$appName"; then
    PrintLog "Removed quarantine flag on $appName"
else
    PrintLog "Unable to remove the quarantine flag on $appName"
fi

PrintLog "Installation Successful."