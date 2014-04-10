#!/bin/bash

# needs Check MK livestatus running on port 6557

nagios="mon101.dev.example.net"
#nagios="mon101.prd.example.net"
port=6557

if [ "$1" = "help" ] || [ -z "$1" ] ; then
	echo "usage: `basename $0` HOST [duration]
duration in minutes (e.g. 120 for 2h) default 90 minutes
examples: 
* scheduling a 90m downtime for web101.example.net
`basename $0` web101.example.net
* scheduling a 3h downtime for web102.example.net
`basename $0` web102.example.net 180

nagios server used: $nagios"

	exit 0
fi

host=$1
duration_minutes=${2-90}
#duration=5400
duration=$(($duration_minutes*60))
stime=$(date +%s)
etime=$(($stime+$duration))
author=$(id -un)
comment="Downtime generated from $HOSTNAME via livestatus COMMAND by $author"
echo -e "COMMAND [$stime] SCHEDULE_HOST_DOWNTIME;$host;$stime;$etime;1;0;$duration;$author;$comment\n" | nc $nagios $port
res=$?

#echo "command sent - res: $res"
echo "Scheduled downtime of ${duration}s for host $host starting now"
