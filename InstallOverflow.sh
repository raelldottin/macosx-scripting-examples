#!/bin/bash

# A quick prototype for automating overflow software installs on macos
# I need to figure out how to determine the download link dynamically
# Add error checking for each command with failbacks or clean up routines
# Then include logging of the installation process
# Requirements: bash, curl, hdiutil, pkill, rm, cp, chown, xattr, (root priviledges)


curl -s 'https://app-updates.overflow.io/packages/updates/osx_64/01800abc7f858990a2f4267e811d430c48f9469b/Overflow-1.16.2.dmg' -o /tmp/download.dmg

hdiutil attach /tmp/download.dmg --nobrowse -quiet

pkill "Overflow"

rm -fr /Applications/Overflow.app

cp -R /Volumes/Overflow/Overflow.app /Applications/

chown -R root:wheel /Applications/Overflow.app

xattr -r -d com.apple.quarantine /Applications/Overflow.app