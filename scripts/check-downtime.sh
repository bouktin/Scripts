#!/bin/bash

# needs Check MK livestatus running on port 6557

nagios="mon101.dev.example.net"
#nagios="mon101.prd.example.net"
port=6557

host=$1
stime=$(date +%s)
columns="host_name service_description is_service type end_time comment"
echo "$columns" | tr ' ' ';'
echo "GET downtimes
Columns: $columns
Filter: host_name = $host" | nc $nagios $port

res=$?

#echo "command sent - res: $res"

