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

# Script Requirements: bash, curl, hdiutil, pkill, rm, cp, chown, xattr, (root priviledges)
# we can write a routine to make sure the target system has the required utilities before beginning


#We can automated the file download using Google Chrome using Puppeteer
#https://tutorialzine.com/2017/08/automating-google-chrome-with-node-js
#https://developers.google.com/web/tools/puppeteer

whoami=$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");')

# Create a log function that handle messages for logger
echo "$(date -u): $whoami is currently logged in"

# Do we re-attempt file download if the download fails or give up one try and declare failure?

echo "$(date -u): downloading file to /tmp/download.dmg"
curl -s 'https://app-updates.overflow.io/packages/updates/osx_64/01800abc7f858990a2f4267e811d430c48f9469b/Overflow-1.16.2.dmg' -o /tmp/download.dmg

echo "$(date -u) attaching downloaded file"
# How do when know where the dmg file is attached, will the volume always have the same name?
hdiutil attach /tmp/download.dmg --nobrowse --quiet

# Perform a check to see if the version of the app inside the dmg matches the installed app, then clean up and exit if it does


# Let's check if the application is still running before terminatign it
# If we are performing a fresh install are user preferences or licensing preferences stored in the application file?
# Let's confirm that the application actually quits
echo "$(date -u): closing application "
pkill "Overflow"

# Check if the app is already install, delete the previous version prior to installation
echo "$(date -u): removing application "
rm -fr /Applications/Overflow.app

# Copy the new app version to the Application folder
echo "$(date -u): copying application"
cp -R /Volumes/Overflow/Overflow.app /Applications/

# Detach the Volume
echo "$(date -u): detaching downloaded file"
hdiutil detach /Volumes/Overflow

# Change permissions on the app bundle -- Note, the installation still need root access to install the app into the application folder.
echo "$(date -u): providing $whoami with access to /Applications/Overflow.app"
chown -R $whoami:staff /Applications/Overflow.app

# Remove quarantine flag
echo "$(date -u): removing quarantine flg on Overflow.app if its set"
xattr -r -d com.apple.quarantine /Applications/Overflow.app