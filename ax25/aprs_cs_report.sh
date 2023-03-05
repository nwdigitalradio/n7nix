#!/bin/bash
#
# aprs_cs_report
#
# This script meant to be run from a crontab
#
# Looks for file names in this format:
#     printf -v curr_date '%(%Y-%m-%d)T' -1
#     out_file="$tmp_dir/aprs_report_${curr_date}.txt"

VERSION="1.2"
scriptname="`basename $0`"

CSMSGFILE="/home/pi/tmp/aprs_parse_file.txt"
tmp_dir="/home/pi/tmp"

# Array of callsigns to check
cs=("n7nix-4" "k7bls-4" "wa7law")

# Array of start times
arrVar=()

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function send_email
function send_email() {

    subject="Test email for aprs parse $(date)"
#    to_email="$USER@$(hostname)"
    to_email="gunn@beeble"

    echo "Debug: subject: $subject, to: $to_email"
    echo "Debug: file:"
    cat $CSMSGFILE

    /usr/bin/mutt -s "$subject" $to_email < $CSMSGFILE
    echo "Mutt return code $?"
}

# ===== function get_start_times
function get_start_times() {

#    echo "${FUNCNAME[0]} "
    # Get a string with all start times
#    start_times=$(grep --binary-files=text -i "total: " $aprs_file_name | cut -f1 -d','| cut -d: -f2-)

    # The following will cut all characters after the last ':'
    #  Keep just the beginning of the time string, no seconds
    start_times=$(grep --binary-files=text -i "^Period:" $aprs_file_name | cut -f1 -d',' | cut -d':' -f3- | sed 's|\(.*\):.*|\1|')

    # Some DEV notes:
    # echo "start times 1: $start_times"
    #  echo "${a#*:}"
    # start_times="$(echo "${starttimes#*:}")"
    # echo "start times read line 2: $start_times"
    # echo "-----"
    # IFS=$'\n' read -a arrVar <<< "$start_times"

    # Break start time string up into array elements
    # Note: < <( ) is a Process Substitution,
    i=0
    while IFS='\n' read -r line ; do
        line="${line#"${line%%[![:space:]]*}"}"
#        echo "$i, -$line-"
        arrVar+=("$line")
	((i++))
    done < <(printf '%s\n' "$start_times")

#    echo "Number of times in array ${#arrVar[@]}"
}

# ===== function display_cnts
#
function display_cnts() {

    call_sign="$1"
#    echo "${FUNCNAME[0]} : call sign $call_sign"
#    echo "DEBUG: display cnts for call sign: $call_sign"

    #    grep -i $i $file
    # echo display array
    # Iterate the loop to read and print each array element
    i=0
    for value in "${arrVar[@]}" ; do

	# Just ignore anything that is not a valid date
        if [ ${#value} -lt 16 ] ; then
	    continue;
        fi

#        callsign_cnt=$(grep --binary-files=text -A 999 "$value, " "$aprs_file_name" | grep --binary-files=text  -B 999  "${arrVar[i+1]}" | grep --binary-files=text -i "$call_sign")
        callsign_cnt=$(grep --binary-files=text -A 999 "$value" "$aprs_file_name" | grep --binary-files=text  -B 999  "${arrVar[i+1]}" | grep --binary-files=text -i "$call_sign" | head -n1)
#                       grep --binary-files=text -A 999 "2023 01 09 06:01" /home/pi/tmp/aprs_report_2023-01-09.txt | grep --binary-files=text  -B 999  "2023 01 09 09:01" | grep --binary-files=text -i "n7nix"

#      test_cnt="$(grep --binary-files=text -A 999 "$value, " "$aprs_file_name" | grep --binary-files=text  -B 999  "${arrVar[i+1]}")"
#        echo "test_count value: $value, value_1 "${arrVar[i+1]}": $test_cnt"

        # echo "${FUNCNAME[0]}  DEBUG: value:=$value=, count:=$callsign_cnt="
	# remove leading whitespace characters
        callsign_cnt="${callsign_cnt#"${callsign_cnt%%[![:space:]]*}"}"

#        echo "debug: VALUE: $value Next VALUE: ${arrVar[i+1]} CALL SIGN: $call_sign COUNT: $callsign_cnt"

	# remove leading whitespace characters
        callsign_cnt="${callsign_cnt#"${callsign_cnt%%[![:space:]]*}"}"
#        echo "$i, $value, 2nd grep "${arrVar[i+1]}", $callsign_cnt"
        echo "$i, $value  $callsign_cnt"

       ((i++))
    done

}

# ===== Display program help info

function usage () {
	(
	echo "Usage: $scriptname [-p <1|2|etc>][-h]"
	echo "   no args           display today's call sign report file"
        echo "   -p <1|2|3|etc>    days previous report file"
        echo "   -h                display this message."
        echo
	) 1>&2
	exit 1
}

# ===== main

echo "APRS call sign report Ver: $VERSION started: $(date)" | tee $CSMSGFILE

# Check if the collection script is running
pgrep -f aprs_cs_collect.sh > /dev/null
if [ $? -eq 1 ] ; then
    echo "$(tput setaf 1)Warning: Collection script is not running.$(tput sgr0)"
fi

# Get current date to match with file name
printf -v check_date '%(%Y-%m-%d)T' -1


# parse any command line options
while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -d)
            # Set debug flag
             DEBUG=1
	     dbgecho "DEBUG flag set, ARGS on command line: $#"
        ;;
        -p)
            days_prev=$2
            shift # past argument

            if [ -z $days_prev ] ; then
	        check_date=$(date -d yesterday "+%Y-%m-%d")
	    else
                # date -d '-2 day' '+%Y%d%m'
	        check_date=$(date -d "-$days_prev days" "+%Y-%m-%d")
	    fi
	;;
        -h)
            usage
            exit 0
        ;;
        *)
            echo "Undefined argument: $key"
            usage
            exit 1
        ;;
    esac
    shift # past argument or value
done

# ls 2>/dev/null will suppress any error message

aprs_file_name="/home/pi/tmp/aprs_report_${check_date}.txt"
if [ -e "$aprs_file_name" ] ; then
    echo "Found file: $aprs_file_name"
else
    echo "Report file: $aprs_file_name NOT found, exiting"
    exit 1
fi
report_file_cnt=$(ls -1 $aprs_file_name 2>/dev/null | wc -l)
if [ $report_file_cnt -eq 0 ] ; then
    echo "No information in report file found."
    exit 0
fi

echo "Found $report_file_cnt report file(s)"


for callsign in "${cs[@]}" ; do
    {
        echo
        echo "Call sign: $callsign file: $aprs_file_name"

        get_start_times
        display_cnts "$callsign"
    } | (tee -a $CSMSGFILE)
done

echo "Finished at: $(date)"
# send_email
