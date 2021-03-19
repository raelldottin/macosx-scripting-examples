#!/usr/bin/env python3
# -*- coding: UTF-8 -*-
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


'''RemoveAppTemplate.py
A script template to quit an app and delete its file path
By default this script deletes Vonage Business'''

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

subprocess.run(['rm', '-r', '-f', AppPath])
