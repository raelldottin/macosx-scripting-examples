#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
#
#MIT License
#
#Copyright (c) 2021 Raell Dottin
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

'''RestartAppTemplate.py
A script template to restart an app defined by ProcessName, AppName and AppPath
If the script is used in Jamf sys.argv[4] is ProcessName, sys.argv[5] is
AppName, sys.argv[6] is AppPath
By default this script relaunch Vonage Business'''

import subprocess
import sys
import time

# Check for command line arguments
if sys.argv[4:5]:
    ProcessName = sys.argv[4]
else:
    ProcessName = "Vonage Business"

if sys.argv[5:6]:
    AppName = sys.argv[5]
else:
    AppName = "Vonage Business.app"

if sys.argv[6:7]:
    AppPath = sys.argv[6]
else:
    AppPath = "/Applications/Vonage Business.app"

# Check if Vonage Business is running and quit all instances of it
p1 = subprocess.Popen('/usr/bin/pgrep ' + ProcessName, shell=True, stdout=subprocess.PIPE)
p2 = subprocess.Popen('/usr/bin/pkill ' + ProcessName, shell=True, stdin=p1.stdout)
p1.stdout.close()
p2.communicate()[0]

# Wait one seconds after the App closes to proceed
time.sleep(1)

# Remove the com.apple.quarantine metadata from the App
subprocess.run(['/usr/bin/xattr', '-d', '-r', 'com.apple.quarantine', AppPath])

# Discover the currrent logged in user, then relaunch Vonage under their UID
loggedInUser = subprocess.run(['stat', '-f%Su', '/dev/console'], text=True, check=True, stdout=subprocess.PIPE).stdout.strip()
loggedInUID = subprocess.run(['id', '-u', loggedInUser], text=True, check=True, stdout=subprocess.PIPE).stdout
print('Current logged in user UID: ', loggedInUID.strip())

# Check if the current logged in user has been idle for more than 5 minutes
# If not then reluanch the App
p1 = subprocess.Popen('/usr/sbin/ioreg -c IOHIDSystem', shell=True, stdout=subprocess.PIPE)
idleTime = float(subprocess.run(['/usr/bin/awk', r'/HIDIdleTime/ {print $NF/1000000000; exit}'], text=True, check=True, stdin=p1.stdout, stdout=subprocess.PIPE).stdout.strip())
p1.stdout.close()
print(loggedInUser, 'has been idle for', idleTime)

if loggedInUID != 0 and idleTime < 300:
    try:
        subprocess.run(['/bin/launchctl', 'asuser', loggedInUID, 'sudo', '-iu', loggedInUser, 'open', '-a', AppName])
    except -600:
        subprocess.run(['/bin/launchctl', 'asuser', loggedInUID, 'sudo', '-iu', loggedInUser, 'open', '-a', AppName])
