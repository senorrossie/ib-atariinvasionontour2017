#!/bin/bash

BASEDIR="$(dirname "$0")"

let MAXCHAR=1476		# 1489 - 13
INTERVAL=30

OLDIFS=$IFS
while [ true ]; do
	# Load configuration
	if [ -e $BASEDIR/service.cfg ]; then
		if [ ! -x $BASEDIR/service.cfg ]; then
			chmod 755 $BASEDIR/service.cfg
		fi
		. $BASEDIR/service.cfg
		echo "(Re-)loaded configuration file."
	fi
	IFS=$OLDIFS
	json_files=(*.json)

	# Set the clock (%-[HMS] = Do not pad with zero)
	printf "time/clock/set:$(($(date '+(%-H*60+%-M)*60+%-S')))" | netcat -u -q 1 localhost 4444
	for JSON in ${json_files[@]}; do
		IFS=$''
		subject=${JSON%.json}
		images=($subject.*.jpg)
		data=$( sed 's/^ *//;s/ *$//;s/ {1,\}/ /g;s/ "/"/g;s/" /"/g;s/\t//g' $JSON | tr -d '\r\n' | tr -d '\r' )
		echo "Found json file for: ${subject}... With ${#images[@]} images."
		if [ ${#data} -lt $MAXCHAR ]; then
			printf " --- Submitting: "
			printf "Item, "
			printf "hb/homebrew:%s\n" $data | netcat -u -q 1 localhost 4444
			printf -v img_data "\"%s\"," "${images[@]}"
			img_data="[${img_data%?}]"    # Remove the final comma and create a valid json array
			printf "Images"
			printf "hb/image:%s\n" $img_data | netcat -u -q 1 localhost 4444
			printf " --- DONE!\n\n"
			printf "(zzZZ) Sleeping for %ss (ZZzz)" "$INTERVAL"
			sleep $INTERVAL
			printf "\n\n"
		else
			printf " --- Skipping!\n --- Reason: JSON data to big for udp packet (${#data} chars > $MAXCHAR)\n\n"
		fi
		IFS=$OLDIFS
	done
	sleep 1
done
