#!/bin/bash

#######################################
## system-kickstart.sh
## 	kickstart a Dell blade server: forces a pxe boot and powercycle
## 	
## 
## author: Thomas Blanchard https://github.com/bouktin
## last revision: 2013-06-14
## version: 0.04
## 
#######################################

# safety
DATA_DIR=/dev/null

F_PARAM=parameters
F_PROJCFG=project-config
error=0
# one of { powerdown powerup powercycle }
PWR_ACTION=${1:-"powercycle"}

test -f $F_PARAM && . $F_PARAM || ( echo "no $F_PARAM file found please see the README file"; exit 1)
let "error+=$?"
test -f $F_PROJCFG && . $F_PROJCFG || ( echo "no $F_PROJCFG file found please see the README file"; exit 1)
let "error+=$?"
if [ $error -gt 0 ]; then exit $error; fi

FLOG=$DATA_DIR/system-kickstart.log
>$FLOG
echo "see file log $FLOG for details."

# DATA INPUT FILE FORMAT:
# chassis;module;hostname
# chassis-101.dc.infrastructure.example.com;Server-13;web101.dc.example.com
DATA_INPUT=$DATA_DIR/system-kickstart.data
test -f $DATA_INPUT || ( echo "no $DATA_INPUT file found please see the README file"; exit 1 )
let "error+=$?"
dos2unix $DATA_INPUT >> $FLOG 2>&1
let "error+=$?"

if [ $error -gt 0 ]; then exit $error; fi

for line in `grep -v "^#" $DATA_INPUT`
do 
	chassis=$(echo $line | cut -d ";" -f 1 | tr -d '\n\r');
	mod=$(echo $line | cut -d ";" -f 2 | tr 'A-Z' 'a-z' | tr -d '\n\r');
	slot=$(echo $mod | cut -d "-" -f 2);
	name=$(echo $line | cut -d ";" -f 3 | tr -d '\n\r');
	
	#TODO: check the server console with the idrac to check they match
	
 	# deploy the servers
	#wrap_expect $chassis "" 1>>$FLOG 2>&1
	
	echo "Deploying server $name on chassis $chassis $mod ..." 1>>$FLOG 2>&1

	# if the server is already down, then use powerup instead
	srv_status=$(wrap_expect $chassis "racadm serveraction -m $mod powerstatus" 2>>$FLOG)
	#status is "ON" or "OFF"
	if [ "X$srv_status" == "XON" ]; then
		PWR_ACTION="powercycle"
	elif [ "X$srv_status" == "XOFF" ]; then
		PWR_ACTION="powerup"
	else
		echo "ERROR: unrecognised power status: \"$srv_status\", skipping this server" 1>>$FLOG 2>&1
		continue
	fi
	
	echo "server is \"$srv_status\", power action set to \"$PWR_ACTION\"" 1>>$FLOG 2>&1

	echo "wrap_expect $chassis \"deploy -m $mod -b PXE -o yes\"" 1>>$FLOG 2>&1
	#echo "wrap_expect $chassis \"serveraction -m $mod powercycle\"" 1>>$FLOG 2>&1
	#echo "wrap_expect $chassis \"serveraction -m $mod powerdown\"" 1>>$FLOG 2>&1
	#echo "wrap_expect $chassis \"serveraction -m $mod powerup\"" 1>>$FLOG 2>&1
	echo "wrap_expect $chassis \"serveraction -m $mod $PWR_ACTION\"" 1>>$FLOG 2>&1

	if [ $TEST -eq 0 ]
	then
		wrap_expect $chassis "deploy -m $mod -b PXE -o yes" 1>>$FLOG 2>&1
		#wrap_expect $chassis "serveraction -m $mod powercycle" 1>>$FLOG 2>&1
		#wrap_expect $chassis "serveraction -m $mod powerdown" 1>>$FLOG 2>&1
		#wrap_expect $chassis "serveraction -m $mod powerup" 1>>$FLOG 2>&1
		wrap_expect $chassis "serveraction -m $mod $PWR_ACTION" 1>>$FLOG 2>&1
		echo "$chassis $mod $name : ${PWR_ACTION}-ed" 1>>$FLOG 2>&1
	else
		echo "DRY RUN -- nothing to do (TEST = $TEST)" 1>>$FLOG 2>&1
	fi

	echo -n "x..."
done

echo " done."

