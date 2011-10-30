#!/bin/bash

##########################################################
## author: Thomas Blanchard - bouktin@gmail.com
## version: 1.00
## last revision date: 2011-04-01
##########################################################


#if [[ "X$1" == "Xhelp" ]]
if [[ $(echo $1 | grep -icEe "([-]{0,2}(help|usage)|-h)") -eq 1 ]]
then
	echo -e "`basename $0` [help] | [date [additional timezone(s)]]"
	echo -e "without argument, display current date under current locale"
	echo -e "\tExample:"
	echo -e "\t\t`basename $0`"
	echo -e "\t\t`basename $0` \"Thu Mar 31 17:26:22 BST 2011\""
	echo -e "\t\t`basename $0` \"2011/04/01 03:00:00 WEST\""
	echo -e "\t\t`basename $0` \"2011-4-1 03 UTC\" \"Asia/Tokyo\""
	echo -e "\t\t`basename $0` now \"US/Central Europe/Paris\""
	echo -e ""
	echo -e "all timezones can be found in the /usr/share/zoneinfo directory"
	echo -e "timezone format is the path from this directory"
	echo -e "\tExamples: "
	echo -e "\tfrom the file /usr/share/zoneinfo/Europe/Paris , the timezone to give is Europe/Paris"
	echo -e "\tfrom the file /usr/share/zoneinfo/America/Indiana/Vincennes , the timezone to give is America/Indiana/Vincennes"
	echo -e ""
	echo -e "Be carefull with the abbreviation since they may refer to several timezones"
	echo -e "\tExample: CST may refer to \"Central Standard Time (USA)\" OR \"Central Standard Time (Australia)\" OR \"China Time\""
	echo -e ""
	exit 0
fi

if [[ -z "${TZ}" ]]; then OLD_TZ=$TZ; fi
VCTZ=( Asia/Shanghai Europe/Stockholm Europe/London America/Los_Angeles $2);
FORMAT='%F %T %Z'
[[ -n "$1" ]] && DATE="$1" || DATE="`date`"

for tz in ${VCTZ[*]}
do
	#export TZ=$tz
	#echo "date -d '$DATE' +$FORMAT"
	echo $(TZ=$tz date -d "$DATE" +"$FORMAT")" in TZ $tz"
done
if [[ ! -z "${OLD_TZ}" ]]
then unset TZ
else TZ=$OLD_TZ; unset OLD_TZ
fi

exit 0

#export TZ=Asia/Shanghai; 
#date 
#export TZ=Asia/Shanghai; date; export TZ=Europe/London; date ; export TZ=America/Los_Angeles; date; unset TZ
#echo array :
#echo "\${VCTZ[@]} ${VCTZ[@]}	/	\${#VCTZ[@]} ${#VCTZ[@]}"
#echo "\${VCTZ[*]} ${VCTZ[*]}	/	\${#VCTZ[*]} ${#VCTZ[*]}"
