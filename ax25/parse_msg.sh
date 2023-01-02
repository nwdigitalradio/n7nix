#!/bin/bash
#
# aprs_cs_collect
#
# If there any command line args will be used as a file name instead of
#  stdin.
# This script runs by itself in a continuous loop
# Set DEBUG=1 for debug echos
DEBUG=

# Set bRESET_COUNT to 1 to clear associate array call sign counts
#  every day
bRESET_COUNT=1

VERSION="1.6"
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
# https://stackoverflow.com/questions/50932280/shell-script-to-run-through-the-day-to-create-files-at-particular-time
declare -A timestops=(
  [00:01]="time0001.txt"
  [06:01]="time0601.txt"
  [09:01]="time0901.txt"
  [12:01]="time1201.txt"
  [15:01]="time1501.txt"
  [18:01]="time1801.txt"
  [21:01]="time2101.txt"
)

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function output_summary
#
# first argument $1 is trigger identifier
# outfile name: printf '%(%Y%m%d)T-%(%H%M)T' 20221228-2217
#

function output_summary() {

    trigger="$1"
    # Get elapsed time in seconds
    et=$((SECONDS-start_time))
    period_et=$((SECONDS-period_time))
    {
        echo
        echo "On machine $(uname -n), triggered by $trigger, $scriptname Ver: $VERSION"
        # Get number of different call signs found.
        callsign_cnt=${#callsign[@]}
        echo "Start:  $start_date, start count: $period_start_date"
        echo "Total:  $(date "+%Y %m %d %T %Z"), Elapsed time: $((et / 3600)) hours, $(((et % 3600)/60)) min, $((et % 60)) secs,  Call sign count: $callsign_cnt, Packet count: $total_cnt"
        echo "Period: Elapsed time: $((period_et / 3600)) hours, $(((period_et % 3600)/60)) min, $((period_et % 60)) secs,  Period Packet count: $period_cnt"

        if [ -e "$tmp_file" ] ; then
            rm $tmp_file
        fi

	callsign_cnt=${#callsign[@]}
	if [ $callsign_cnt != 0 ] ; then
            printf "     APRS Packets\tCount\n"
            for i in "${!callsign[@]}" ; do
                printf "%16s\t%3s\n" "$i" "${callsign[$i]}" >> "$tmp_file"
            done

            sort -k2 -n -r $tmp_file
	else
	    echo "DEBUG: ${FUNCNAME[0]} called with NO call signs"
	fi
    }  | (tee -a $out_file)
}

# ===== function ctrl_c
#

function ctrl_c() {
    output_summary "ctrl_c"
    exit 0
}

# ===== function trigger_date

function trigger_date() {

#printf -v last_time '%(%H:%M)T' -1

    printf -v curr_time '%(%H:%M)T' -1
    [[ "$curr_time" = "$last_time" ]] && return
    printf -v curr_date '%(%Y-%m-%d)T' -1

    for evt_ts in "${!timestops[@]}"; do
        if [[ $curr_time = "$evt_ts" ]] || [[ $curr_time > $evt_ts && $last_time < $evt_ts ]]; then
            evt_file=${timestops[$evt_ts]}
            callsign_cnt=${#callsign[@]}
            echo "$(date): Hey TEST FILE, # call signs: $callsign_cnt" >> "$tmp_dir/$evt_file"

            output_summary "date"

	    period_cnt=0
	    period_start_date="$(date "+%Y %m %d %T %Z")"
	    period_time=$SECONDS

	    if [ "$bRESET_COUNT" != 0 ] ; then
	        # reset counts every 24 hours when '%(%Y-%m-%d)T' changes
                if [[ "$curr_date" != "$run_on_date" ]] ; then
                    # Empty call sign count array
                    callsign=()
	            callsign_cnt=${#callsign[@]}
                    echo "$(date) Resetting count array, Call sign count: $callsign_cnt" >> $debug_file

        	    run_on_date="$curr_date"
                    out_file="$tmp_dir/aprs_report_${curr_date}.txt"
		fi
	    fi
        fi
    done
    last_time=$curr_time
}

# ===== function trigger_callsign

function trigger_callsign() {

    # DEBUG test for some call signs

    if [ "$from_root" = "N7NIX" ] || [ "$from_root" = "$callsign_axport_root" ] ; then
        echo "$(date) Found local call sign $from_call" >> $debug_file
        echo  >> $debug_file
        output_summary "call sign"
        if [ "$bRESET_COUNT" != 0 ] ; then
            # reset array
            callsign=()
	    echo "$(date) Resetting count array" >> $debug_file
	    start_count_date="$(date "+%Y %m %d %T %Z")"
	fi
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

# Verify there is a local temporary directory
if [ ! -d $tmp_dir ] ; then
    # Verify user home dir name
    # Get list of users with home directories
    USERLIST="$(ls /home)"
    # Check if there is only a single user on this system
    if (( `ls /home | wc -l` == 1 )) ; then
        USER=$(ls /home)
    else
        echo "Enter user name ($(echo $USERLIST | tr '\n' ' ')), followed by [enter]:"
        read -e USER
   fi
   mkdir -p /home/$USER/tmp
fi

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
# echo "Will trigger on call sign: $callsign_axport, $callsign_axport_root and N7NIX"

times=$(echo  "${!timestops[@]}" | xargs -n1 | sort | xargs)
echo "Will trigger on times: ${times}"
reset_str="will NOT"
if [ $bRESET_COUNT != 0 ] ; then
   reset_str="WILL"
fi
echo "Call sign array counts $reset_str be cleared at beginning of new day"

#echo "Will trigger on times: ${!timestops[@]}"
#for evt_ts in "${timestops[@]}"; do
#    echo -n "$evt_ts "
#done
echo ; echo

# Initialize for trigger_date() function
printf -v run_on_date '%(%Y-%m-%d)T' -1
printf -v last_time '%(%H:%M)T' -1

start_time=$SECONDS
period_time=$SECONDS

start_date="$(date "+%Y %m %d %T %Z")"
period_start_date="$(date "+%Y %m %d %T %Z")"
total_cnt=0
period_cnt=0
printf -v curr_date '%(%Y-%m-%d)T' -1
out_file="$tmp_dir/aprs_report_${curr_date}.txt"


while read line ; do
#    echo "begin1:${line}:end1"
#    echo "Found $(echo $line | wc -l) lines"
    echo "$line" | grep -q $PORT_NAME
    if [ $? -eq 0 ] ; then
        from_call=$(echo "$line" | cut -f3 -d' ')
	to_call=$(echo "$line" | cut -f5 -d' ')
	via_call=$(echo "$line" | cut -f7 -d' ')
	at_time=$(echo "$line" | rev | cut -d' ' -f 1 | rev)
#        echo "begin2:$(echo $line | cut -f3 -d' '):end2"
#        echo "$from_call to $to_call at $at_time"
        from_root=$(echo "$from_call" | cut -f1 -d'-')

	curr_line=$(printf "%s to %s" "$from_call" "$to_call")
	if [ "$last_line" = "$curr_line" ] ; then
	    if [[ ${#via_call} -le 8 ]] ; then
                printf "Dup %s at\t\t\t\t%s\n" "$via_call" "$at_time"
	    else
	        printf "Dup %s at\t\t\t%s\n" "$via_call" "$at_time"
	    fi
	else
	    if [[ ${#from_call} -le 7 ]] ; then
                printf "%s\t\t%s via %-8s\t%s\n" "$from_call" "$to_call" "$via_call" "$at_time"
	    else
                printf "%s\t%s via %-8s\t%s\n" "$from_call" "$to_call" "$via_call" "$at_time"
	    fi
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

	((period_cnt++))
	((total_cnt++))

    fi

    trigger_date

done < "${1:-/dev/stdin}"

output_summary "main loop exit"
exit 0

