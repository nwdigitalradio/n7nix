#!/bin/bash
#
# aprs_cs_per.sh
#
# Output APRS activity on a every 15 minute period
# Used to debug tx iGate filter settings in aprx
#
# If there any command line args will be used as a file name instead of
#  stdin.
#
# listen -a | ./aprs_cs_per.sh
#
# This script runs by itself in a continuous loop
# Set DEBUG=1 for debug echos
DEBUG=
USER=

# Set bRESET_COUNT to 1 to clear associate array call sign counts
#  every day
bRESET_COUNT=1
# Used to echo call sign counts every 15 minutes
bPERIOD_CNT="true"

VERSION="1.9"
scriptname="`basename $0`"

# Used to parse only 'listen' lines from a particular port name
PORT_NAME=
PORT_NUM=0

AX25_CFGDIR="/usr/local/etc/ax25"
AXPORTS_FILE="$AX25_CFGDIR/axports"
last_line=

declare -A callsign_tot
declare -A callsign_per
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

# ===== function summary_total

function summary_total() {

    if [ $callsign_totcnt != 0 ] ; then
        printf "     APRS Packets\tCount\n"
        for i in "${!callsign_tot[@]}" ; do
            printf "%16s\t%3s\n" "$i" "${callsign_tot[$i]}" >> "$tmp_file"
        done

        sort -k2 -n -r $tmp_file
    else
        echo "DEBUG: ${FUNCNAME[0]} called with NO call signs"
    fi
}
# ===== function summary_period

function summary_period() {

    if [ $callsign_percnt != 0 ] ; then
        printf "     APRS Packets\tCount\n"
        for i in "${!callsign_per[@]}" ; do
            printf "%16s\t%3s\n" "$i" "${callsign_per[$i]}" >> "$tmp_file"
        done

        sort -k2 -n -r $tmp_file
    else
	echo "DEBUG: ${FUNCNAME[0]} called with NO call signs"
    fi
}

# ===== function output_summary
#
# first argument $1 is trigger identifier
# outfile name: printf '%(%Y%m%d)T-%(%H%M)T' 20221228-2217
#

function output_summary() {

    trigger="$1"
    bTotal="$2"

    # Get elapsed time in seconds
    total_et=$(( SECONDS - start_time ))
    period_et=$(( SECONDS - period_start_time ))
    {
        echo
        echo "On machine $(uname -n), triggered by $trigger, for a $bTotal, $scriptname Ver: $VERSION"

        # Get number of different call signs found.
        callsign_totcnt=${#callsign_tot[@]}
        callsign_percnt=${#callsign_per[@]}

	# This will mess up the grep between dates
#	echo "Output summary for: $(date "+%Y %m %d %T %Z")"

        echo "Running Total:  start date: $start_date, Elapsed time: $((total_et / 3600)) hours, $(((total_et % 3600)/60)) min, $((total_et % 60)) secs,  Call Sign count: $callsign_totcnt, Packet count: $total_cnt"
        echo "Period:         start date: $period_start_date, Elapsed time: $((period_et / 3600)) hours, $(((period_et % 3600)/60)) min, $((period_et % 60)) secs,  Period Call Sign count: $callsign_percnt, Period Packet count: $period_cnt"

        if [ -e "$tmp_file" ] ; then
            rm $tmp_file
        fi

	if [ "$bTotal" = "total" ] ; then
	   summary_total
	else
	   summary_period
	fi

    }  | (tee -a $out_file)
}

# ===== function ctrl_c
#

function ctrl_c() {
    if [ $bPERIOD_CNT == "false" ] ; then
        output_summary "ctrl_c" "total"
    else
        echo "Exiting ...."
    fi
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

            callsign_percnt=${#callsign_per[@]}

            echo "$(date): Hey TEST FILE, # call signs: $callsign_percnt" >> "$tmp_dir/$evt_file"

            if [ $bPERIOD_CNT == "false" ] ; then
		output_summary "date" "period"
            fi

            # Empty period call sign count array
            callsign_per=()
	    period_cnt=0
	    period_start_date="$(date "+%Y %m %d %T %Z")"
	    period_start_time=$SECONDS

	    if [ "$bRESET_COUNT" != 0 ] ; then
	        # reset counts every 24 hours when '%(%Y-%m-%d)T' changes
                if [[ "$curr_date" != "$run_on_date" ]] ; then
	            callsign_totcnt=${#callsign_tot[@]}

                    if [ $bPERIOD_CNT == "false" ] ; then
		        output_summary "date" "total"
		    fi

                    # Empty total call sign count array
                    callsign_tot=()
	    	    total_cnt=0
		    start_time=$SECONDS
                    echo "$(date) Resetting total count array, Call sign count: $callsign_totcnt" >> $debug_file

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
        output_summary "call sign" "total"
        if [ "$bRESET_COUNT" != 0 ] ; then
            # reset array
            callsign_per=()
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

# ===== function get_user

function get_user() {
   # Check if there is only a single user on this system
   if (( `ls /home | wc -l` == 1 )) ; then
      USER=$(ls /home)
   else
      echo "Enter user name ($(echo $USERLIST | tr '\n' ' ')), followed by [enter]:"
      read -e USER
   fi
}

# ==== function check_user
# verify user name is legit

function check_user() {
   userok=false
   dbgecho "$scriptname: Verify user name: $USER"
   for username in $USERLIST ; do
      if [ "$USER" = "$username" ] ; then
         userok=true;
      fi
   done

   if [ "$userok" = "false" ] ; then
      echo "User name ($USER) does not exist,  must be one of: $USERLIST"
      exit 1
   fi

   dbgecho "using USER: $USER"
}

# ===== function get_user_name
function get_user_name() {

    # Get list of users with home directories
    USERLIST="$(ls /home)"
    USERLIST="$(echo $USERLIST | tr '\n' ' ')"

    # Check if user name was supplied on command line
    if [ -z "$USER" ] ; then
        # prompt for call sign & user name
        # Check if there is only a single user on this system
        get_user
    fi
    # Verify user name
    check_user
}

# ===== Display program help info

function usage () {
	(
	echo "Usage: $scriptname [-p ][-h]"
        echo "   -P <port_num>     Set Interface port number (0 or 1)"
	echo "   -D <device_name>  Set Device name (udr or dinah)"
        echo "   -d                Set debug flag"
        echo "   -h                display this message"
	) 1>&2
	exit 1
}

# ===== main
#
# check if process is already running

for pid in $(pidof -x $scriptname); do
    if [ $pid != $$ ]; then
        echo "[$(date)] : $scriptname : Process is already running with PID $pid"
        exit 1
    fi
done
get_user_name

tmp_dir="/home/$USER/tmp"
tmp_file="$tmp_dir/aprs.tmp"
out_file="$tmp_dir/aprs_report.txt"
debug_file="$tmp_dir/aprs_debug.txt"

# Create out_file if it does NOT exist
if [ ! -e $out_file ] ; then
    echo "Create file: $out_file"
    touch $out_file
fi
echo "$(date): $scriptname Ver: $VERSION" | tee -a $out_file

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
   mkdir -p $tmp_dir
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
period_start_time=$SECONDS

start_date="$(date "+%Y %m %d %T %Z")"
period_start_date="$(date "+%Y %m %d %T %Z")"
total_cnt=0
period_cnt=0
printf -v curr_date '%(%Y-%m-%d)T' -1
out_file="$tmp_dir/aprs_report_${curr_date}.txt"

bls_cnt=0
nix_cnt=0
dup_cnt=0
tot_cnt=0
start_time=$SECONDS
# Period interval in seconds
PERIOD_CHK=900
echo "$(date) starting period check every $((PERIOD_CHK/60)) minutes"

while read line ; do
#    echo "begin1:${line}:end1"
#    echo "Found $(echo $line | wc -l) lines"
    echo "$line" | grep -q "^${PORT_NAME}:"
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

          if [ 1 -eq 0 ] ; then
	    if [[ ${#via_call} -le 8 ]] ; then
                printf "Dup %s at\t\t\t\t%s\n" "$via_call" "$at_time"
	    else
	        printf "Dup %s at\t\t\t%s\n" "$via_call" "$at_time"
	    fi
	  else
	    echo -n "d"
	    (( dup_cnt++ ))
	  fi
	else
	    # via_call with nine characters does not line up,
	    #  only pads with 7 spaces, need 15 spaces
	    from_len=${#from_call}
	  if [ 1 -eq 0 ] ; then
            printf "%-9s\t%s via %-10s\t%s\n" "$from_call" "$to_call" "$via_call" "$at_time"
	  else
  	    (( tot_cnt++ ))
	  fi
	fi

	# listen -a | grep -i "k7bls\|n7nix"
	grep -qi "k7bls" <<< $curr_line
	if [ $? -eq 0 ] ; then
	    echo -n "k"
	    (( bls_cnt++ ))
	fi

	grep -qi "n7nix" <<< $curr_line
	if [ $? -eq 0 ] ; then
	    echo -n "n"
	    (( nix_cnt++ ))
	fi

	elapsed_time=$((SECONDS-start_time))
	if (( SECONDS - start_time > PERIOD_CHK )) ; then
	    start_time=$SECONDS
	    echo
	    echo "$(date) Counts: n7nix: $nix_cnt, k7bls: $bls_cnt, Dup: $dup_cnt, total: $tot_cnt"
	    echo
	    nix_cnt=0
	    bls_cnt=0
	    dup_cnt=0
	    tot_cnt=0
	fi
	last_line="$curr_line"

        # Weed out some junk aprs packets
	# Test for NON-ASCII characters and callsign too long
	if [[ $from_call = *[![:ascii:]]* ]] || [[ $from_len -gt 9 ]] ; then
	    echo
            echo " Found Non-ASCII characters in from_call or length too large: $from_len"
	    echo
	    continue;
        fi

        callsign_tot[$from_call]=$((callsign_tot[$from_call] + 1))
        callsign_per[$from_call]=$((callsign_per[$from_call] + 1))

	((period_cnt++))
	((total_cnt++))

    fi

    if [ $bPERIOD_CNT == "false" ] ; then
        trigger_date
    fi

done < "${1:-/dev/stdin}"

output_summary "main loop exit" "total"
exit 0
