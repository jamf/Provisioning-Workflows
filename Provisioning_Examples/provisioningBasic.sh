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
# - Provisioning based on policy
# HISTORY
#   Version: 1.0
#   - Created by Jonathan Yuresko June 17, 2018
# 
####################################################################################################

echo "Beginning provisioning process"

# Configures Location services
/usr/local/jamf/bin/jamf policy -trigger provision_locationservices

# Installs Google Chrome
/usr/local/jamf/bin/jamf policy -trigger provision_googlechrome

# Configures Google Chrome Settings
/usr/local/jamf/bin/jamf policy -trigger provision_settings_googlechrome

# Installs Adobe Flash Player
/usr/local/jamf/bin/jamf policy -trigger provision_flash

# Installs Java
/usr/local/jamf/bin/jamf policy -trigger provision_java

# Installs Firefox
/usr/local/jamf/bin/jamf policy -trigger provision_firefox

# Installs Firefox Homepage
/usr/local/jamf/bin/jamf policy -trigger provision_settings_firefox_homepage

# Installs Slack
/usr/local/jamf/bin/jamf policy -trigger provision_slack

# Installs Office for Mac
/usr/local/jamf/bin/jamf policy -trigger provision_msoffice

# Installs Adobe Photoshop
/usr/local/jamf/bin/jamf policy -trigger provision_photoshop

echo "Provisioning complete"