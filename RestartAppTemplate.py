#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
#
# Copyright 2020 Raell Dottin.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use thise file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/Licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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