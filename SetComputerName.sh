#!/bin/bash

JAMF_URL=""
# ***Please use $(printf "username:password" | iconv -t ISO-8859-1 | base64 -i -) to generate your credentials***
JAMF_CREDENTIALS=""
# ***Please add computer name prefix***
JAMF_COMPNAME_PREFIX=""

# retrieve all computer names from Jamf server
echo "Retrieve computers names from Jamf Server."

# ***I would like to change the regex from a single quote to double quotes, then use a variable for the company name prefix.***
curl -s -X GET $JAMF_URL/JSSResource/computers --header 'authorization: Basic $JAMF_CREDENTIALS'|grep -Eo '[^CENTOS]\d{3}'|grep X|sed -e 's/X//'|sort > /tmp/computernames.txt

# generate a list of usable computer names
echo "Generating a list of usable computer names."
seq -f '%03g' $(tail -1 <(sort /tmp/computernames.txt)) > /tmp/availablecomputernames.txt

# ***Also, I will like to add the computer name prefixs here too***
# get the next usable computer name
echo "Getting the next usable computer name."
name=CENTOSX$(join -a 1 -o "1.1 2.1" -e missed  /tmp/availablecomputernames.txt /tmp/computernames.txt |grep missed|head -1| awk '{print $1}')

# remove the temporary files
echo "Removing temporary files /tmp/availablecomputernames.txt /tmp/computernames.txt."
rm -f /tmp/availablecomputernames.txt /tmp/computernames.txt

# set the computer names
echo "Setting computer name to $name."
/usr/local/jamf/bin/jamf setcomputername -name $name
flags=(ComputerName LocalHostName HostName)
for flag in $flags
do
	scutil --set $flag $name
done

# update the computer name on the Jamf server
for (( i=0; i <= 9; i++ ))
do
	/usr/local/bin/jamf recon
	if [[ $? -eq 0 ]]
	then
		break
	fi
done
