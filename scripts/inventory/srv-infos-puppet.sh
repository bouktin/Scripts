#!/bin/bash

# author: Thomas Blanchard - thomasfp.blanchard@gmail.com
# version: 0.3
# version date: 2014-04-10
# purpose: Retrieves a specific server's data from a puppet server

myhost=${1:-"web1.example.net"}
output=${2:-"detailed"}

CERTS="/some/path/to/monitoring/puppet-certs/"
CURL_CMD=/usr/bin/curl
CURL_OPTS="-s --cert $CERTS/monitor.example.net-cert.pem --key $CERTS/monitor.example.net-key.pem --cacert $CERTS/puppetmaster.pem"
PUPPET_URL="https://puppet.example.net:8081/facts/"
CMD_PROCESSOR="python -mjson.tool"
NIS_CONSOLE="/conf/nis/console-list"

function get_puppet_facts () {
	OUT=$($CURL_CMD $CURL_OPTS -H 'Accept: application/json' "${PUPPET_URL}${myhost}" )
	res=$?
	if [ $res -ne 0 ] ; then
		if [ "X$output" = "Xcsv" ] ; then 
			echo "$myhost;no data found - curl error;;;"
		else
			echo -e "problem running the curl command : returned $res"
			echo -e "output:\n$OUT"
		fi
	else
		# could be used later: assigns each of the line to a varialbe name pp_$field, e.g.: field productname in var $pp_productname
		eval $( echo -e "$OUT" | $CMD_PROCESSOR | grep \
			-e '"memorysize":' -e '"fqdn":' -e '"lsbdistdescription":' \
			-e '"processorcount":' -e '"productname":' -e '"serialnumber":' \
			-e '"uptime":' -e '"virtual":' -e '"error":' \
			| sed   -e "s/^[[:blank:]]\+\"\([[:alnum:]]\+\)\":[[:blank:]]*/pp_\1=/" \
					-e "s/,\?[[:blank:]]\+$/;/" ) # sed to format lines from '\t"field": "some value",' to 'field="some value";' (without simple quotes ' )
		# echo "DEBUG: proc=$pp_processorcount - mem=$pp_memorysize - S/T=$pp_serialnumber"
		if [ "X$output" = "Xcsv" ] ; then 
			echo -n "$pp_fqdn;$pp_memorysize;$pp_productname;$pp_processorcount;$pp_serialnumber"
		else
			echo "displaying information for server: $myhost:"
			#echo -e "$OUT" 
			echo -e "$OUT" | $CMD_PROCESSOR | grep \
				-e '"memorysize":' -e '"fqdn":' -e '"lsbdistdescription":' \
				-e '"processorcount":' -e '"productname":' -e '"serialnumber":' \
				-e '"uptime":' -e '"virtual":' -e '"error":' \
				| sed -e "s/^[[:blank:]]\+\"\([[:alnum:]]\+\)\":/\1:/" -e "s/,[[:blank:]]\+$//"
		fi
	fi
}

function get_dmi_info () {
	dmi_raw_file="/systems/server-data/dmidecode.raw,$myhost"
	if [ -e "$dmi_raw_file" ]; then
		echo "Information for server: $myhost"
		mod_time="$(stat --printf "%y" $dmi_raw_file)"
		freshness=$(echo "$(date -d now +%s) - $(date -d "$mod_time" +%s)" | bc)
		if [ $freshness -gt 129600 ]
		then echo -e "WARNING: data older than 36h \nfile $dmi_raw_file mod time: $mod_time"
		else echo -e "data date: $mod_time"
		fi
		echo -n "Server Model: "; dmidecode --from-dump "$dmi_raw_file" -s system-product-name
		echo -n "Service Tag: "; dmidecode --from-dump "$dmi_raw_file" -s system-serial-number
		echo -n "Bios version: "; dmidecode --from-dump "$dmi_raw_file" -s bios-version
		echo -n "Installed Memory: "; dmidecode --from-dump "$dmi_raw_file" -t memory | awk 'BEGIN {count=0; memory=0} /Size: [0-9]+/ {memory += $2; unit=$3; count++ } END {printf("%i GB on %i modules\n",memory/1024,count)}'
		
	else
		echo "the file \"$dmi_raw_file\" doesn't exist, please check the server name"

	fi
}

function get_console () {
	# default: console is CNAME in DNS:
	console=$(dig +nocmd +noall +answer +nosearch console.$myhost CNAME | awk '{print $5}')
	if [ "X$console" = "X" ]; then
		# not a CNAME, may be an A record (racked servers like r720)
		console=$(dig +nocmd +noall +answer +nosearch console.$myhost A | awk '{print $1" ("$5")"}')
	fi
	if [ "X$console" = "X" ]; then
		# no console in DNS, checking NIS
		console=$(grep -e "\<$myhost\>" $NIS_CONSOLE | awk '{print $2" "$3}')
		if [ "X$console" = "X" ]; then
			console="no console information in DNS and NIS, may be a vm"
		fi
	fi
	if [ "X$output" = "Xcsv" ] ; then 
		echo -en ";$console\n"
	else
		echo -e console: \"$console\"
	fi
}

function get_warranty () {
	/config/scripts/check-dell-warranty.pl -st $pp_serialnumber | awk -F";" '{print "servicetag:"$5}'
}

#get_dmi_info
get_puppet_facts
get_console
#get_warranty

exit 0

#echo <<EODATA>/dev/stderr
3600*24
86400
3600*36
129600

[user@ns1 ~]$ stat backup-mysql.sh
  File: `backup-mysql.sh'
  Size: 995             Blocks: 8          IO Block: 32768  regular file
Device: 25h/37d Inode: 7530519     Links: 1
Access: (0754/-rwxr-xr--)  Uid: (510/user)   Gid: (   510/   user)
Access: 2013-04-29 02:33:08.728742000 -0700
Modify: 2012-11-01 11:15:45.318261000 -0700
Change: 2012-11-01 11:17:44.060863000 -0700
[user@ns1 ~]$ date -d "`stat --printf "%y" backup-mysql.sh`" +%s
1351793745
[user@ns1 ~]$ echo "$(date -d now +%s) - $(date -d "`stat --printf "%y" backup-mysql.sh`" +%s)" | bc
15434542

[user@ns1 inventory]$ dmidecode --from-dump "/systems/server-data/dmidecode.raw,$myhost" -t memory | awk 'BEGIN {memory=0} /Size/ {memory += $2; unit=$3} END {printf("%i GB\n",memory/1024)}'
96 GB

# the following is interesting if you can get the raw dmidecode for each server you monitor
sudo dmidecode -t memory | awk 'BEGIN {count=0; memory=0} /Size: [0-9]+/ {memory += $2; unit=$3; count++ } END {printf("%i GB on %i modules\n",memory/1024,count)}'
32 GB on 8 modules

# more data and options:
http://www.thegeekstuff.com/2008/11/how-to-get-hardware-information-on-linux-using-dmidecode-command/

## puppet stuff:
# full curl command: (set myhost)
/usr/bin/curl -s --cert /home/user/inventory/puppet-certs/monitor.example.net-cert.pem --key /home/user/inventory/puppet-certs/monitor.example.net-key.pem --cacert /home/user/inventory/puppet-certs/puppetmaster.pem -H 'Accept: application/json' "https://puppet.example.net:8080/facts/$myhost"

EODATA

