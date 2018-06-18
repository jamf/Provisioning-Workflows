#!/bin/sh
########################################################################################################
#
# Copyright (c) 2018, JAMF Software, LLC.  All rights reserved.
#
#       Redistribution and use in source and binary forms, with or without
#       modification, are permitted provided that the following conditions are met:
#               * Redistributions of source code must retain the above copyright
#                 notice, this list of conditions and the following disclaimer.
#               * Redistributions in binary form must reproduce the above copyright
#                 notice, this list of conditions and the following disclaimer in the
#                 documentation and/or other materials provided with the distribution.
#               * Neither the name of the JAMF Software, LLC nor the
#                 names of its contributors may be used to endorse or promote products
#                 derived from this software without specific prior written permission.
#
#       THIS SOFTWARE IS PROVIDED BY JAMF SOFTWARE, LLC "AS IS" AND ANY
#       EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#       DISCLAIMED. IN NO EVENT SHALL JAMF SOFTWARE, LLC BE LIABLE FOR ANY
#       DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
#       ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#       (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#       SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
####################################################################################################
# PURPOSE
# - Ensure computers maintain proper naming conventions, prompts for computer name
# - Provisioning based on policy
# HISTORY
#   Version: 1.0
#   - Created by Jonathan Yuresko June 17, 2018
# 
####################################################################################################

#################################
# Creates Provisioning Log File #
#################################
log=~/Desktop/log.txt
touch $log

#################################
# Promts User For Computer Name #
#################################
user=$(ls -l /dev/console | awk '/ / { print $3 }')
computerName=$(sudo -u $user /usr/bin/osascript <<ENDofOSAscript
set T to text returned of (display dialog "Please enter the name of the computer." buttons {"OK"} default button "OK" default answer "")
ENDofOSAscript
)

####################################
# Makes all characters capitalized #
####################################
compName=$(echo $compName | tr [a-z] [A-Z]); 
new_hostname=$compName 
echo "Changed computer names to: $new_hostname"

##############################
# Jamf Helper Popup Window 1 #
##############################
/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -other_options foo -startlaunchd -windowType hud -description "Step 1/3: Running first recon" -icon /Applications/Self\ Service.app/Contents/Resources/Self\ Service.icns &

###################################
# Sets local computer to new name #
###################################
scutil --set HostName $new_hostname
scutil --set ComputerName $new_hostname
scutil --set LocalHostName $new_hostname

####################################
# First Recon to set Computer Name #
####################################
echo "Running recon"
jamf recon

#####################
# Stops Jamf Helper #
#####################
killAll jamfHelper

/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -other_options foo -startlaunchd -windowType hud -description "Step 2/3: Now Imaging" -icon /Applications/Self\ Service.app/Contents/Resources/Self\ Service.icns &

###################################
# Writes data to provisioning log #
###################################
echo "
Build 1a" >> $log
dateStamp=$( date "+%a %b %d %H:%M:%S" )
echo "
Imaging started at $dateStamp
" >> $log

###################################
# Custom triggered policies begin #
###################################

echo "Installing Google Chrome"
/usr/local/jamf/bin/jamf policy -trigger provision_googlechrome -verbose
chrome_version=$(mdls -name kMDItemVersion /Applications/Google\ Chrome.app | cut -c 19- | rev | cut -c 2- | rev)
if [[ $chrome_version == *"could not find"* ]]; then
	# App is not installed
	echo "Google Chrome install FAILED" >> $log
else
	# App is installed
	echo "Google Chrome $chrome_version Installed Successfully" >> $log
fi

echo "Installing Firefox"
/usr/local/jamf/bin/jamf policy -trigger provision_firefox -verbose
firefox_version=$(mdls -name kMDItemVersion /Applications/Firefox.app | cut -c 19- | rev | cut -c 2- | rev)
if [[ $firefox_version == *"could not find"* ]]; then
	# App is not installed
	echo "Firefox install FAILED" >> $log
else
	# App is installed
	echo "Firefox $firefox_version Installed Successfully" >> $log
fi

echo "Installing BlueCoat"
/usr/local/jamf/bin/jamf policy -trigger bluecoat -verbose
bluecoat_version=$(sudo launchctl list | grep -i com.bluecoat.ua)
echo $bluecoat_version
if [[ $bluecoat_version == "" ]]; then
	# App is not installed
	echo "BlueCoat install FAILED" >> $log
else
	# App is installed
	echo "BlueCoat Installed Successfully" >> $log
fi

##############################
# Completes imaging log file #
##############################
dateStamp=$( date "+%a %b %d %H:%M:%S" )
echo "
Provisioning completed at $dateStamp
" >> $log

#####################
# Stops Jamf Helper #
#####################
killAll jamfHelper

########################################
# Imaging Complete, Jamf Helper Prompt #
########################################
userChoice=$(/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper -windowType hud -description "Step 3/3 : Imaging Complete" -button2 "Done" -icon /Applications/Self\ Service.app/Contents/Resources/Self\ Service.icns &)
if [ "$userChoice" == "2" ]; then
    open ~/Desktop/log.txt
    killall Terminal
    exit
else
    exit 0
fi

