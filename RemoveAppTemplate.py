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