#!/bin/bash
##########################################################
## author: Thomas Blanchard - bouktin@gmail.com
## version: 1.00
## last revision: 2011-10-07
##########################################################

SVTAG=$1
wget -O /dev/stdout -a /dev/null \
	"http://support.dell.com/support/topics/global.aspx/support/my_systems_info/details?servicetag=$SVTAG" \
	| awk 'BEGIN {RS="</tr>"; FS="</td>"} /Next Business Day|Mission Critical/ {print $4}' \
	| sed -e "s#.*>\([0-9]\{1,2\}/[0-9]\{1,2\}/20[0-9]\{2\}\).*#\1#" | head -n 1 #tr '\n' ';'

exit 0

# Notes :
# this script parses html warranty page result from dell support web site 
# the OLD code was a little bit crapy : 
#	| grep Description  | sed "y#<>\"=#____#" | sed "s#.*_No_/a__/td__td class__contract_oddrow__##" \
#	| sed "s#_/td__/tr__/table__/td__/tr__tr filter.*##" | sed "s#_/td__td class__contract_oddrow__#;#g"
# 		it greps the html table containing te informations Description 
# 		it replaces all the <>"= by _ 
# 		it removes all the caracters before the start date
# 		it removes all the caracters after the number of days
# 		it replaces the caracters between the dates and days by ;
# 
# Warranty 
# Next Business Day|Mission Critical|Silver Premium Support|4 Hour On-Site Service|Silver Premium Support|4 Hour On-Site Service|4 HRs response|Pro Support for IT Tech Support.Assistant|Mission Critical|Next Business Day response|Parts Only Warranty
# use this script with the following command line :

simple one:
for ch in $LST_BLD; do ofile=war_$ch; :> $ofile ; echo chassis $ch; LST_TAGS=`cat $ch`; 
	for sv in $LST_TAGS; do echo -en "$sv;" >> $ofile; ./parse_dell.sh $sv >> $ofile; done ; done

handles empty slot:
for ch in $LST_BLD; do ofile=war_$ch; :> $ofile ; echo chassis $ch; LST_TAGS=`cat $ch`; 
	for sv in $LST_TAGS; do echo -en "$sv;" >> $ofile; if [ X"$sv" != X"N/A" ]; then ../parse_dell.sh $sv >> $ofile; else echo "N/A;N/A;N/A" >> $ofile ; fi ; done ; done

if [ X"$sv" != X"N/A" ]; then echo "server present - exec script"; else echo "N/A;N/A;N/A" ; fi ;

| grep Description  | sed "y#<>\"=/#_____#" | sed "s#.*_No__a___td__td class__contract_oddrow__##" | sed "s#__td___tr___table___td___tr__tr filter.*##" | sed "s#__td__td class__contract_oddrow__#;#g"
awk 'BEGIN {RS="<tr>"} /Mission Critical/ {print}' test-pb
awk 'BEGIN {RS="<tr>"; FS="<td"} /Mission Critical/ {print $6}' test-pb | sed -e "s#.*\([0-9]\{2\}/[0-9]\{2\}/20[0-9]\{2\}\).*#\1#"
awk 'BEGIN {RS="</tr>"; FS="</td>"} /Mission Critical/ {print $5}' | sed -e "s#.*\([0-9]\{2\}/[0-9]\{2\}/20[0-9]\{2\}\).*#\1#"
#	
# LST_BLD contains a list of files contained in the local folder
# here is a sample of the LST_BLD variable

LST_BLD="blade-1
blade-2
blade-3
"

# each file contains a list of element and serial number separated by space(s) or tab(s), typically the result of getmodinfo
# the file may contain only the serial number, 
cat blade-2
Chassis 2G7XXXX
Server-1        BCPXXXX
Server-2        837XXXX
[...]
Switch-1        4C9XXXX
[...]

