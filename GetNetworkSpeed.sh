#!/bin/bash

echo
date
dscl . read /Users/$(/usr/bin/python -c 'from SystemConfiguration import SCDynamicStoreCopyConsoleUser; import sys; username = (SCDynamicStoreCopyConsoleUser(None, None, None) or [None])[0]; username = [username,""][username in [u"loginwindow", None, u""]]; sys.stdout.write(username + "\n");') RealName | tail -1
echo
echo
scutil --get ComputerName
sw_vers | awk -F':\t' '{print $2}' | paste -d ' ' - - -
sysctl -n hw.memsize | awk '{print $0/1073741824" GB RAM"}'
sysctl -n machdep.cpu.brand_string
echo
echo

DOWNLAODA_SPEED=0
EXIT_STATUS=0

if [[ ! -f /usr/local/bin/speedtest ]]
then
    if [[ ! -f /usr/local/bin/pip ]]
    then
        curl https://bootstrap.pypa.io/pip/2.7/get-pip.py -o /tmp/get-pip.py
        python /tmp/get-pip.py --force-reinstall
    fi
    pip install speedtest-cli
fi

/usr/local/bin/speedtest > /tmp/speedtest_results.txt
if [[ -r /tmp/speedtest_results.txt ]]
then
	DOWNLOAD_SPEED=$(grep "Download:" /tmp/speedtest_results.txt | awk '{ print $2 }')
	if (( $(echo "$DOWNLOAD_SPEED < 150" | bc -l) ))
    then
        EXIT_STATUS=1
    fi
	cat /tmp/speedtest_results.txt
	rm /tmp/speedtest_results.txt
else
    EXIT_STATUS=1
fi
system_profiler SPNetworkDataType SPAirPortDataType

exit $EXIT_STATUS