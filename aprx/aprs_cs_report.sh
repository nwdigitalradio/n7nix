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
DEBUG=
bdisplay_cnt="false"
bemail_cnt="false"

bverbose="false"

# Array of callsigns to check
cs=("n7nix-4" "k7bls-4" "wa7law")
localcs=("n7nix-4" "k7bls-4")

# Array of start times
arrVar=()

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function send_email
function send_email() {

    subject="Test email for aprs parse $(date)"
#    to_email="$USER@$(hostname)"
    to_email="gunn@beeble"

    echo "Debug: subject: $subject, to: $to_email"
#    echo "Debug: file: N7NIX-4: $nixcnt, K7BLS-4: $blscnt"
#    cat $CSMSGFILE

#    /usr/bin/mutt -s "$subject" $to_email < $CSMSGFILE
    /usr/bin/mutt -s "$subject" $to_email < $EMAILFILE
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

# ===== function display_cntss
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

#       callsign_cnt=$(grep --binary-files=text -A 999 "$value, " "$aprs_file_name" | grep --binary-files=text  -B 999  "${arrVar[i+1]}" | grep --binary-files=text -i "$call_sign")
        callsign_cnt=$(grep --binary-files=text -A 999 "$value" "$aprs_file_name" | grep --binary-files=text  -B 999  "${arrVar[i+1]}" | grep --binary-files=text -i "$call_sign" | head -n1)
#       grep --binary-files=text -A 999 "2023 01 09 06:01" $tmp_dir/aprs_report_2023-01-09.txt | grep --binary-files=text  -B 999  "2023 01 09 09:01" | grep --binary-files=text -i "n7nix"

#      test_cnt="$(grep --binary-files=text -A 999 "$value, " "$aprs_file_name" | grep --binary-files=text  -B 999  "${arrVar[i+1]}")"
#        echo "test_count value: $value, value_1 "${arrVar[i+1]}": $test_cnt"

        # echo "${FUNCNAME[0]}  DEBUG: value:=$value=, count:=$callsign_cnt="
	# remove leading whitespace characters
        callsign_cnt="${callsign_cnt#"${callsign_cnt%%[![:space:]]*}"}"

#       echo "debug: VALUE: $value Next VALUE: ${arrVar[i+1]} CALL SIGN: $call_sign COUNT: $callsign_cnt"

	# remove leading whitespace characters
#        callsign_cnt="${callsign_cnt#"${callsign_cnt%%[![:space:]]*}"}"
#        echo "$i, $value, 2nd grep "${arrVar[i+1]}", $callsign_cnt"
        echo "$i, $value  $callsign_cnt"

       ((i++))
    done

}

# Function print full report

function full_report() {

    if [ ! -z "$DEBUG" ] ; then
        echo "full_report: Current csmsgfile"
        ls -salt $CSMSGFILE
        cat $CSMSGFILE
        echo
    fi
    rm $CSMSGFILE

    for callsign in "${cs[@]}" ; do
        {
            echo

            get_start_times
            display_cnts "$callsign"
            echo "Call sign: $callsign file: $aprs_file_name, number counts: $i"

        } | ( tee -a  $CSMSGFILE > /dev/null )
    done

    if [ ! -z "$DEBUG" ] ; then
        echo " === full_report: end csmsgfile"
        ls -salt $CSMSGFILE
        cat $CSMSGFILE
        echo
        echo " === end file"
    fi
}

function cnt_report() {

    full_report

    if [ ! -z "$DEBUG" ] ; then
        echo "DEBUG flag is NOT null"
    else
        echo "DEBUG flag IS null"
    fi

    if [ ! -z "$DEBUG" ] ; then
        echo "cnt report: file $CSMSGFILE"
        ls -salt $CSMSGFILE
        cat $CSMSGFILE
        echo
        echo " === end file"
    fi

    nixcnt=$(grep -c "N7NIX-4" $CSMSGFILE)
    blscnt=$(grep -c "K7BLS-4" $CSMSGFILE)

    echo "Count report N7NIX-4: $nixcnt, K7BLS-4: $blscnt" > $EMAILFILE
    grep "^7," $CSMSGFILE >> $EMAILFILE
}

# function get_ranking
# Determine the APRS packet count ranking

function get_ranking() {

    disp_cnt=$(grep -c "APRS Packets"  "$aprs_file_name")
    dbgecho "Display Count: $disp_cnt"

    (( disp_cnt-- ))

    echo
    total_calls=$(awk "/APRS Packets/{i++}i>${disp_cnt}" "$aprs_file_name" | awk NR\>1 | wc -l)

    echo "Date: $check_date"
    #echo "total calls debug: $total_calls"
    #awk "/APRS Packets/{i++}i>${disp_cnt}" $aprs_file_name | awk NR\>1 | cat -n
    #echo "total calls debug: end"
    #echo

    # Get Packet count: for second from last display
    total_pkt_cnt=$(awk "/Running Total/{i++}i>${disp_cnt}" "$aprs_file_name" | grep -i "Packet count: " | head -n 1 | sed 's/.* //')

    echo "Total number of stations heard: $total_calls, total packet count: $total_pkt_cnt"

    echo "    Rank        Call Sign     Packets"
    # display top 3 rankings
    awk "/APRS Packets/{i++}i>7" $aprs_file_name | awk NR\>1 | cat -n |  head -3


    callsign="N7NIX-4"
    rank_nix=$(awk "/APRS Packets/{i++}i>${disp_cnt}" $aprs_file_name | awk NR\>1 | sed -n "0,/${callsign}/p" | wc -l)
    callsign="K7BLS-4"
    rank_bls=$(awk "/APRS Packets/{i++}i>${disp_cnt}" $aprs_file_name | awk NR\>1 | sed -n "0,/${callsign}/p" | wc -l)


     callsign1="N7NIX-4"
     callsign2="K7BLS-4"
     if (( rank_nix > rank_bls )) ; then
         callsign1="K7BLS-4"
         callsign2="N7NIX-4"
     fi

    callsign="$callsign1"

#    echo "Debug: Call sign: $callsign, display count: $disp_cnt"
    rank=$(awk "/APRS Packets/{i++}i>${disp_cnt}" $aprs_file_name | awk NR\>1 | sed -n "0,/${callsign}/p" | wc -l)
    pkt_cnt=$(awk "/APRS Packets/{i++}i>${disp_cnt}" $aprs_file_name | awk NR\>1 | sed -n "0,/${callsign}/p" | grep "$callsign")

    # get rid of white space
    pkt_cnt=$(echo $pkt_cnt | expand -t 1 | tr -s '[[:space:]]')
    pkt_cnt2=$(echo $pkt_cnt | cut -f2 -d ' ')
    printf "   %3d\t\t %s\t%4d\n" "$rank" "$callsign" "$pkt_cnt2"

    #awk "/APRS Packets/{i++}i>$disp_cnt" $aprs_file_name | awk NR\>1 | sed -n '0,/$callsign/p'

    callsign="$callsign2"

    # echo "Debug: Call sign: $callsign, display count: $disp_cnt"
    rank=$(awk "/APRS Packets/{i++}i>$disp_cnt" $aprs_file_name | awk NR\>1 | sed -n "0,/$callsign/p" | wc -l)
    pkt_cnt=$(awk "/APRS Packets/{i++}i>${disp_cnt}" $aprs_file_name | awk NR\>1 | sed -n "0,/${callsign}/p" | grep "$callsign")

    # get rid of white space
    pkt_cnt=$(echo $pkt_cnt | expand -t 1 | tr -s '[[:space:]]')
    pkt_cnt2=$(echo $pkt_cnt | cut -f2 -d ' ')
    printf "   %3d\t\t %s\t%4d\n" "$rank" "$callsign" "$pkt_cnt2"

    #echo -n "    $rank "
    #awk "/APRS Packets/{i++}i>${disp_cnt}" $aprs_file_name | awk NR\>1 | sed -n "0,/${callsign}/p" | grep "$callsign"

#    echo "Debug:"
    # awk "/APRS Packets/{i++}i>$disp_cnt" $aprs_file_name | awk NR\>1 | sed -n '0,/$callsign/p'

}

function get_report_filename() {

    aprs_file_name="$tmp_dir/aprs_report_${check_date}.txt"
    if [ -e "$aprs_file_name" ] ; then
        dbgecho "Found file: $aprs_file_name"
    else
        echo "Report file: $aprs_file_name NOT found, exiting"
        exit 1
    fi
    report_file_cnt=$(ls -1 $aprs_file_name 2>/dev/null | wc -l)
    if [ $report_file_cnt -eq 0 ] ; then
        echo "No information in report file found."
        exit 0
    fi

    dbgecho "Found $report_file_cnt report file(s)"
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
	echo "Usage: $scriptname [-p <1|2|etc>][-h]"
	echo "   no args           display today's call sign report file"
        echo "   -p <1|2|3|etc>    days previous report file"
	echo "   -r                rank top 3 APRS packet xmitters plus n7nix & k7bls"
	echo "   -c                display count report only"
	echo "   -C                email count report only"
	echo "   -d                set debug flag"
	echo "   -v                set verbose flag"
        echo "   -h                display this message."
        echo
	) 1>&2
	exit 1
}

# ===== main

get_user_name

tmp_dir="/home/$USER/tmp"
CSMSGFILE="$tmp_dir/aprs_parse_file.txt"
EMAILFILE="$tmp_dir/email_file.txt"

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

	    echo "debug: days_prev: $2, args: $#"
            grep -q '-' <<< $2
	    if [ $? -eq 0 ] ; then
	       echo "Found new argument"
	       days_prev=
	    else
	       echo "Found days previous number: $days_prev"
               shift # past argument
	    fi

            if [ -z $days_prev ] ; then
	        check_date=$(date -d yesterday "+%Y-%m-%d")
	    else
                # date -d '-2 day' '+%Y%d%m'
	        check_date=$(date -d "-$days_prev days" "+%Y-%m-%d")
	    fi
	;;
	-c)
	    dbgecho "Displaying counts only"
            bdisplay_cnt="true"
	;;
	-C)
	    dbgecho "Displaying counts only"
            bemail_cnt="true"
	;;
	-r) # Get ranking
            get_report_filename

	    get_ranking
	    exit
	;;
	-v)
            bverbose="true"
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

if [ "$bdisplay_cnt" != "true" ] ; then
    echo "APRS call sign report Ver: $VERSION started: $(date)"
fi

# ls 2>/dev/null will suppress any error message

get_report_filename

if [ "$bdisplay_cnt" = "true" ] ; then
    dbgecho "bverbose = $bverbose"
    cnt_report
    cat $EMAILFILE

elif [ "$bemail_cnt" = "true" ] ; then
    dbgecho "bverbose = $bverbose"
    cnt_report
    send_email
else
    bverbose="true"
    full_report
    cat $CSMSGFILE
fi

if [ "$bverbose" = "true" ] ; then
    echo "Finished at: $(date)"
fi
