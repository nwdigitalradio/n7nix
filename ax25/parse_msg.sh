#!/bin/bash
#
# If there any command line args will be used as a file name instead of
#  stdin.
#
# Set DEBUG=1 for debug echos
DEBUG=
VERSION="1.2"
scriptname="`basename $0`"

# Used to parse only 'listen' lines from a particular port name
PORT_NAME=
PORT_NUM=0

tmp_dir="/home/pi/tmp"
tmp_file="$tmp_dir/aprs.tmp"
out_file="$tmp_dir/aprs_report.txt"
debug_file="$tmp_dir/aprs_debug.txt"

AX25_CFGDIR="/usr/local/etc/ax25"
AXPORTS_FILE="$AX25_CFGDIR/axports"
last_line=
declare -A callsign
declare -A timestops=(
  [15:00]="abc.txt"
  [16:00]="def.txt"
  [17:00]="hij.txt"
  [18:00]="xyz.txt"
)

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function output_summary
#
function output_summary() {

    # Get elapsed time in seconds
    et=$((SECONDS-start_time))
    {
        echo
        echo "On machine $(uname -n)"
        # Get number of different call signs found.
        callsign_cnt=${#callsign[@]}
        echo "Start:  $start_date"
        echo "Finish: $(date "+%Y %m %d %T %Z"): Elapsed time: $((et / 3600)) hours, $(((et % 3600)/60)) min, $((et % 60)) secs,  Call sign count: $callsign_cnt, Packet count: $total_cnt"
        echo

        if [ -e "$tmp_file" ] ; then
            rm $tmp_file
        fi

        printf "     APRS Packets\tCount\n"
        for i in "${!callsign[@]}" ; do
            printf "%16s\t%3s\n" "$i" "${callsign[$i]}" >> "$tmp_file"
        done

        sort -k2 -n -r $tmp_file
    }  | (tee -a $out_file)
}

# ===== function ctrl_c
#

function ctrl_c() {
    output_summary
    exit 0
}

# ===== function trigger_date

function trigger_date() {

#printf -v last_time '%(%H:%M)T' -1

#while sleep 1; do
    printf -v curr_time '%(%H:%M)T' -1
    printf -v curr_date '%(%Y-%m-%d)T' -1
    [[ "$curr_time" = "$last_time" ]] && return
#   [[ "$curr_date" = "$run_on_date" ]] || { echo "Day ${run_on_date} has ended; exiting" >&2; exit 0; }
    for evt_ts in "${!timestops[@]}"; do
        if [[ $curr_time = "$evt_ts" ]] || [[ $curr_time > $evt_ts && $last_time < $evt_ts ]]; then
            evt_file=${timestops[$evt_ts]}
            echo "THIS IS TEST FILE." >"$tmp_dir/$evt_file"
            output_summary
        fi
    done
    last_time=$curr_time
# done
}

# ===== function trigger_callsign

function trigger_callsign() {

    if [ "$from_root" = "N7NIX" ] || [ "$from_root" = "$callsign_axport_root" ] ; then
        echo "Found local call sign $from_call at $(date)" >> $debug_file
        echo  >> $debug_file
        output_summary
    fi
}

# ===== function get_axport_device
# Pull device names from string

function get_axport_device() {
    dev_str="$1"
    device_axports=$(echo $dev_str | cut -d ' ' -f1)
    callsign_axports=$(echo $dev_str | cut -d ' ' -f2)

    dbgecho "DEBUG: get_axport: arg: $dev_str, $device_axports"

    # Test if device string is not null
    if [ ! -z "$device_axports" ] ; then
        udr_device="$device_axports"
        dbgecho "axport: found device: $udr_device, with call sign $callsign_axports"
    else
        echo "axport: NO ax25 devices found"
    fi
}

# ===== function get_portname

function get_portname() {
    # Collapse all spaces on lines that do not begin with a comment
    getline=$(grep -v '^#' $AXPORTS_FILE | tr -s '[[:space:]] ')

    linecnt=$(wc -l <<< $getline)
    if (( linecnt == 0 )) ; then
        echo "No axports found in $AXPORTS_FILE"
        return
    else
        dbgecho "axports: found $linecnt lines:"
#        dbgecho "$getline"
#        dbgecho
    fi

    while IFS= read -r line ; do
        get_axport_device "$line"
    done <<< $getline

    # get the first port line after the last comment
    #axports_line=$(tail -n3 $AXPORTS_FILE | grep -v "#" | grep -v "N0ONE" |  head -n 1)
    axports_line=$(tail -n3 $AXPORTS_FILE | grep -vE "^#|N0ONE" |  head -n 1)

    dbgecho "Using axports line: $axports_line"
    PORT_NAME=$(echo $axports_line | cut -d' ' -f1)
    callsign_axport=$(echo $axports_line | tr -s '[[:space:]]' | cut -d' ' -f2)
    dbgecho "Using port: $PORT_NAME, call sign: $callsign_axport"
}

# ===== main
#

echo "$scriptname Ver: $VERSION" | tee -a $out_file

while [[ $# -gt 0 ]] ; do
key="$1"

case $key in
   -P|--portnum)
        PORT_NUM="$2"
        shift # past argument
        if [ "$PORT_NUM" != 0 ] && [ "$PORT_NUM" != 1 ] ; then
            echo " Port number must be either 0 or 1"
	    exit 1
        fi
   ;;
   -D|--device)
        DEVICE_TYPE="$2"
        shift # past argument
        if [ "$DEVICE_TYPE" != "dinah" ] && [ "$DEVICE_TYPE" != "udr" ] ; then
            echo "Invalid device type: $DEVICE_TYPE, default to dinah device"
            DEVICE_TYPE="dinah"
        fi
    ;;
   -d|--debug)
      DEBUG=1
      echo "Debug mode on"
    ;;
  -h|--help|?)
      usage
      exit 0
    ;;
   *)
      # unknown option
      echo "Unknow option: $key"
      usage
      exit 1
    ;;
esac
shift # past argument or value
done

if [ -z "$DEVICE_TYPE" ] ; then
    get_portname
else
    PORT_NAME="${DEVICE_TYPE}${PORT_NUM}"
    getline=$(grep -i "${PORT_NAME}" $AXPORTS_FILE | tr -s '[[:space:]] ')
    callsign_axport=$(echo $axports_line | tr -s '[[:space:]]' | cut -d' ' -f2)
    dbgecho "Call sign: $callsign_axport from port name: $PORT_NAME"
fi

# Initialize associative array
# #### I don't think this is necessary ####
#callsign=("$PORT_NAME")
# callsign[$callsign_axport]=0

# callsign_axport set in get_portname
callsign_axport_root="$(echo "$callsign_axport" | cut -f1 -d'-')"

echo "using AX.25 port name: $PORT_NAME and local call sign: $callsign_axport"
echo

printf -v run_on_date '%(%Y-%m-%d)T' -1
# printf -v last_time '%(%H:%M)T' -1

start_time=$SECONDS
start_date="$(date "+%Y %m %d %T %Z")"
total_cnt=0

while read line ; do
#    echo "begin1:${line}:end1"
#    echo "Found $(echo $line | wc -l) lines"
    echo "$line" | grep -q $PORT_NAME
    if [ $? -eq 0 ] ; then
        from_call=$(echo "$line" | cut -f3 -d' ')
	to_call=$(echo "$line" | cut -f5 -d' ')
	at_time=$(echo "$line" | rev | cut -d' ' -f 1 | rev)
#        echo "begin2:$(echo $line | cut -f3 -d' '):end2"
#        echo "$from_call to $to_call at $at_time"
        from_root=$(echo "$from_call" | cut -f1 -d'-')

	curr_line=$(printf "%s to %s" "$from_call" "$to_call")
	if [ "$last_line" = "$curr_line" ] ; then
            via_call=$(echo "$line" | cut -f7 -d' ')
	    echo "Dup $via_call at $at_time"
	else
            printf "%s to %s at\t%s\n" "$from_call" "$to_call" "$at_time"
	fi
	last_line="$curr_line"

	bFound=false
	for i in "${!callsign[@]}" ; do
	    if [ "$i" = "$from_call" ] ; then
	        callsign[$i]=$((callsign[$i] + 1))
		dbgecho "DEBUG: incrementing $from_call for index: $i"
		bFound=true
		break;
	    fi
	done

	if [ "$bFound" = false ] ; then
    	    callsign[$from_call]=1;
	    dbgecho "DEBUG: new array entry: $from_call"
	fi

	((total_cnt++))

	# DEBUG test for some call signs

	trigger_callsign
	trigger_date
    fi
done < "${1:-/dev/stdin}"

# Get elapsed time in seconds
et=$((SECONDS-start_time))
echo
echo "Finish: $(date "+%Y %m %d %T %Z"): Elapsed time: $((et / 3600)) hours, $(((et % 3600)/60)) min, $((et % 60)) secs,  Packet count: $total_cnt"
# echo "Packet count: $total_cnt"
echo

exit 0

