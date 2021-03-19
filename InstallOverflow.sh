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


# Do we re-attempt file download if the download fails or give up one try and declare failure?
curl -s 'https://app-updates.overflow.io/packages/updates/osx_64/01800abc7f858990a2f4267e811d430c48f9469b/Overflow-1.16.2.dmg' -o /tmp/download.dmg

# How do when know where the dmg file is attached, will the volume always have the same name?
hdiutil attach /tmp/download.dmg --nobrowse --quiet

# Perform a check to see if the version of the app inside the dmg matches the installed app, then clean up and exit if it does


# Let's check if the application is still running before terminatign it
# If we are performing a fresh install are user preferences or licensing preferences stored in the application file?
# Let's confirm that the application actually quits
pkill "Overflow"

# Check if the app is already install, delete the previous version prior to installation
rm -fr /Applications/Overflow.app

# Copy the new app version to the Application folder
cp -R /Volumes/Overflow/Overflow.app /Applications/

# Detach the Volume
hdiutil detach /Volumes/Overflow

# Change permissions on the app bundle
chown -R root:wheel /Applications/Overflow.app

# Remove quarantine flag
xattr -r -d com.apple.quarantine /Applications/Overflow.app