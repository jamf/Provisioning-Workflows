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
# From a CSV, it will create:
# - Creates an "{APPNAME} Installed" Smart Group
# - Creates an "{APPNAME} Up-to-date" Smart Group
# - Creates a "Main Policy" Policy
#   *** NOTE ***
#   You will need to add the installation file (script, .pkg, .dmg) to Main Policy after this is run
#   *** NOTE ***
# - Creates a "Self Service Install" Policy
# - Creates a "Self Service Update" Policy
# - Creates a "Provisioning {APPNAME}" Policy
#
# HOW TO USE
# 1. Fill out CSV from Template found on Github
# 2. Fill out variables in this script for Jamf Pro API user and location of CSV
# 3. In terminal run: sudo sh /Path/To/This/File.sh
#
# HISTORY
#   Version: 1.0
#   - Created by Jonathan Yuresko June 17, 2018
# 
####################################################################################################


######################
# Jamf Pro variables #
######################
jssUrl=''
jssUsername=''
jssPassword=''

####################
# CSV File of Apps #
####################
csvFile=''


################################################################################################
################################# DO NOT WRITE BELOW THIS LINE #################################
################################################################################################

###############################
# Finds number of apps in csv #
###############################
csv_lines=()
csv_lines+=$(/bin/cat $csvFile | awk '{n+=1} END {print n}')
let app_count=$csv_lines-1

########################################################
# Loops through csv, creates smart groups and policies #
########################################################
count=1
let app_count=app_count+1
while [  $count -lt $app_count ]; do
	get_fullAppName=()
	get_singleStringAppName=()
	get_category=()
	get_appFileName=()
	get_appVersion=()

	while IFS=',' read -r ApplicationName stringIdentifier Category ApplicationFilename ApplicationVersion; do

		get_fullAppName+=("$ApplicationName")
		get_singleStringAppName+=("$stringIdentifier")
		get_category+=("$Category")
		get_appFileName+=("$ApplicationFilename")
		get_appVersion+=("$ApplicationVersion")        
    
    done < $csvFile

	fullAppName="${get_fullAppName[$count]}"
	singleStringAppName="${get_singleStringAppName[$count]}"
	category="${get_category[$count]}"
	appFileName="${get_appFileName[$count]}"
	appVersion="${get_appVersion[$count]}"
	
	/bin/rm -R ~/Desktop/group.xml
	/bin/rm -R ~/Desktop/policy.xml
	/bin/rm -R ~/Desktop/category.xml
	
	########################################
	# Creates Category if it Doesn't Exist #
	########################################
	/usr/bin/touch ~/Desktop/category.xml
	
	XML="<category><name>"
	XML+=${category}
	XML+="</name></category>"
	/bin/echo "${XML}" | xmllint --format - > ~/Desktop/category.xml

	/usr/bin/curl -k -s  $jssUrl/JSSResource/categories/id/0 --user $jssUsername:$jssPassword -T ~/Desktop/category.xml -X POST

	/bin/rm -R ~/Desktop/category.xml
	
	#################################
	# Creates Installed Smart Group #
	#################################
	/usr/bin/touch ~/Desktop/group.xml

	installedName=${fullAppName}" - Installed"

	XML="<computer_group><name>"
	XML+=${installedName}
	XML+="</name><is_smart>true</is_smart><criteria><size>1</size><criterion><name>Application Title</name><priority>0</priority><and_or>and</and_or><search_type>has</search_type><value>"
	XML+=${appFileName}
	XML+="</value><opening_paren>false</opening_paren><closing_paren>false</closing_paren></criterion></criteria></computer_group>"
	/bin/echo "${XML}" | xmllint --format - > ~/Desktop/group.xml

	/usr/bin/curl -k -s  $jssUrl/JSSResource/computergroups/id/0 --user $jssUsername:$jssPassword -T ~/Desktop/group.xml -X POST

	/bin/rm -R ~/Desktop/group.xml

	##################################
	# Creates Up-to-date Smart Group #
	##################################
	/usr/bin/touch ~/Desktop/group.xml

	latestName=${fullAppName}" - Latest"

	XML="<computer_group><name>"
	XML+=${latestName}
	XML+="</name><is_smart>true</is_smart><criteria><size>2</size><criterion><name>Application Title</name><priority>0</priority><and_or>and</and_or><search_type>has</search_type><value>"
	XML+=${appFileName}
	XML+="</value><opening_paren>false</opening_paren><closing_paren>false</closing_paren></criterion><criterion><name>Application Version</name><priority>1</priority><and_or>and</and_or><search_type>is</search_type><value>"
	XML+=${appVersion}
	XML+="</value><opening_paren>false</opening_paren><closing_paren>false</closing_paren></criterion></criteria></computer_group>"
	/bin/echo "${XML}" | xmllint --format - > ~/Desktop/group.xml

	/usr/bin/curl -k -s  $jssUrl/JSSResource/computergroups/id/0 --user $jssUsername:$jssPassword -T ~/Desktop/group.xml -X POST

	/bin/rm -R ~/Desktop/group.xml

	###########################
	# Creates App Main Policy #
	###########################
	/usr/bin/touch ~/Desktop/policy.xml

	mainPolicyName="Main - "$fullAppName
	formattedAppName=$(/bin/echo $singleStringAppName | tr [A-Z] [a-z])
	mainPolicyTrigger="main_"$formattedAppName

	XML="<policy><general><name>"
	XML+=${mainPolicyName}
	XML+="</name><enabled>true</enabled><trigger>EVENT</trigger><trigger_checkin>false</trigger_checkin><trigger_enrollment_complete>false</trigger_enrollment_complete><trigger_login>false</trigger_login><trigger_logout>false</trigger_logout><trigger_network_state_changed>false</trigger_network_state_changed><trigger_startup>false</trigger_startup><trigger_other>"
	XML+=${mainPolicyTrigger}
	XML+="</trigger_other><frequency>Ongoing</frequency><location_user_only>false</location_user_only><target_drive>/</target_drive><offline>false</offline><category><name>Main Policies</name></category></general><scope><all_computers>true</all_computers></scope>"
	XML+="<maintenance><recon>true</recon><reset_name>false</reset_name><install_all_cached_packages>false</install_all_cached_packages><heal>false</heal><prebindings>false</prebindings><permissions>false</permissions><byhost>false</byhost><system_cache>false</system_cache><user_cache>false</user_cache><verify>false</verify></maintenance></policy>"
	/bin/echo "${XML}" | xmllint --format - > ~/Desktop/policy.xml

	/usr/bin/curl -k -s  $jssUrl/JSSResource/policies/id/0 --user $jssUsername:$jssPassword -T ~/Desktop/policy.xml -X POST

	/bin/rm -R ~/Desktop/policy.xml

	#######################################
	# Creates Self Service Install Policy #
	#######################################
	/usr/bin/touch ~/Desktop/policy.xml

	installPolicyName=$fullAppName
	installPolicyTrigger=$(echo $singleStringAppName | tr [A-Z] [a-z])

	XML="<policy><general><name>"
	XML+=${installPolicyName}
	XML+="</name><enabled>true</enabled><trigger>EVENT</trigger><trigger_checkin>false</trigger_checkin><trigger_enrollment_complete>false</trigger_enrollment_complete><trigger_login>false</trigger_login><trigger_logout>false</trigger_logout><trigger_network_state_changed>false</trigger_network_state_changed><trigger_startup>false</trigger_startup><frequency>Ongoing</frequency><location_user_only>false</location_user_only><target_drive>/</target_drive><offline>false</offline><category><name>"
	XML+=${category}
	XML+="</name></category></general><scope><all_computers>true</all_computers><computers/><exclusions><computers/><computer_groups><computer_group><name>"
	XML+=${installedName}
	XML+="</name></computer_group></computer_groups></exclusions></scope><self_service><use_for_self_service>true</use_for_self_service><self_service_display_name>Java Cache</self_service_display_name><install_button_text>Install</install_button_text><reinstall_button_text>Reinstall</reinstall_button_text><self_service_description/><force_users_to_view_description>false</force_users_to_view_description><self_service_icon/><feature_on_main_page>false</feature_on_main_page><self_service_categories/></self_service>"
	XML+="<files_processes><search_by_path/><delete_file>false</delete_file><locate_file/><update_locate_database>false</update_locate_database><spotlight_search/><search_for_process/><kill_process>false</kill_process><run_command>jamf policy -trigger "
	XML+=${mainPolicyTrigger}
	XML+="</run_command></files_processes></policy>"
	/bin/echo "${XML}" | xmllint --format - > ~/Desktop/policy.xml

	/usr/bin/curl -k -s  $jssUrl/JSSResource/policies/id/0 --user $jssUsername:$jssPassword -T ~/Desktop/policy.xml -X POST

	/bin/rm -R ~/Desktop/policy.xml

	#######################################
	# Creates Self Service Update Policy #
	#######################################
	/usr/bin/touch ~/Desktop/policy.xml
	updatePolicyName=$fullAppName" - Update"

	XML="<policy><general><name>"
	XML+=${updatePolicyName}
	XML+="</name><enabled>true</enabled><trigger>EVENT</trigger><trigger_checkin>false</trigger_checkin><trigger_enrollment_complete>false</trigger_enrollment_complete><trigger_login>false</trigger_login><trigger_logout>false</trigger_logout><trigger_network_state_changed>false</trigger_network_state_changed><trigger_startup>false</trigger_startup><trigger_other>updates</trigger_other><frequency>Ongoing</frequency><location_user_only>false</location_user_only><target_drive>/</target_drive><offline>false</offline><category><name>"
	XML+="Updates"
	XML+="</name></category></general><scope><all_computers>false</all_computers><computers/><computer_groups><computer_group><name>"
	XML+=${installedName}
	XML+="</name></computer_group></computer_groups><exclusions><computers/><computer_groups><computer_group><name>"
	XML+=${latestName}
	XML+="</name></computer_group></computer_groups></exclusions></scope><self_service><use_for_self_service>true</use_for_self_service><self_service_display_name>Java Cache</self_service_display_name><install_button_text>Install</install_button_text><reinstall_button_text>Reinstall</reinstall_button_text><self_service_description/><force_users_to_view_description>false</force_users_to_view_description><self_service_icon/><feature_on_main_page>false</feature_on_main_page><self_service_categories/></self_service>"
	XML+="<files_processes><search_by_path/><delete_file>false</delete_file><locate_file/><update_locate_database>false</update_locate_database><spotlight_search/><search_for_process/><kill_process>false</kill_process><run_command>jamf policy -trigger "
	XML+=${mainPolicyTrigger}
	XML+="</run_command></files_processes></policy>"
	/bin/echo "${XML}" | xmllint --format - > ~/Desktop/policy.xml

	/usr/bin/curl -k -s  $jssUrl/JSSResource/policies/id/0 --user $jssUsername:$jssPassword -T ~/Desktop/policy.xml -X POST

	/binrm -R ~/Desktop/policy.xml

	###############################
	# Creates Provisioning Policy #
	###############################
	/usr/bin/touch ~/Desktop/policy.xml
	enrollmentPolicyName="Provision - "$fullAppName
	enrollPolicyTrigger="provision_"$formattedAppName

	XML="<policy><general><name>"
	XML+=${enrollmentPolicyName}
	XML+="</name><enabled>true</enabled><trigger>EVENT</trigger><trigger_checkin>false</trigger_checkin><trigger_enrollment_complete>false</trigger_enrollment_complete><trigger_login>false</trigger_login><trigger_logout>false</trigger_logout><trigger_network_state_changed>false</trigger_network_state_changed><trigger_startup>false</trigger_startup><trigger_other>"
	XML+=${enrollPolicyTrigger}
	XML+="</trigger_other><frequency>Ongoing</frequency><location_user_only>false</location_user_only><target_drive>/</target_drive><offline>false</offline><category><name>Provisioning</name></category></general><scope><all_computers>true</all_computers><exclusions><computers/><computer_groups><computer_group><name>"
	XML+=${installedName}
	XML+="</name></computer_group></computer_groups></exclusions></scope>"
	XML+="<files_processes><search_by_path/><delete_file>false</delete_file><locate_file/><update_locate_database>false</update_locate_database><spotlight_search/><search_for_process/><kill_process>false</kill_process><run_command>jamf policy -trigger "
	XML+=${mainPolicyTrigger}
	XML+="</run_command></files_processes></policy>"
	/binecho "${XML}" | xmllint --format - > ~/Desktop/policy.xml

	/usr/bin/curl -k -s  $jssUrl/JSSResource/policies/id/0 --user $jssUsername:$jssPassword -T ~/Desktop/policy.xml -X POST

	/bin/rm -R ~/Desktop/policy.xml

	let count=count+1
done
