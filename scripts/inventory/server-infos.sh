#!/bin/bash

myhost=${1:-"server1.example.com"}
dmi_raw_file="/path/to/dmidecode.raw"

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
Access: (0754/-rwxr-xr--)  Uid: (510/user)   Gid: (   10/   wheel)
Access: 2013-04-29 02:33:08.728742000 -0700
Modify: 2012-11-01 11:15:45.318261000 -0700
Change: 2012-11-01 11:17:44.060863000 -0700
[user@ns1 ~]$ date -d "`stat --printf "%y" backup-mysql.sh`" +%s
1351793745
[user@ns1 ~]$ echo "$(date -d now +%s) - $(date -d "`stat --printf "%y" backup-mysql.sh`" +%s)" | bc
15434542

[user@ns1 inventory]$ dmidecode --from-dump "/path/to/dmidecode.raw" -t memory | awk 'BEGIN {memory=0} /Size/ {memory += $2; unit=$3} END {printf("%i GB\n",memory/1024)}'
96 GB

sudo dmidecode -t memory | awk 'BEGIN {count=0; memory=0} /Size: [0-9]+/ {memory += $2; unit=$3; count++ } END {printf("%i GB on %i modules\n",memory/1024,count)}'
32 GB on 8 modules

# more data and options:
http://www.thegeekstuff.com/2008/11/how-to-get-hardware-information-on-linux-using-dmidecode-command/

EODATA

