#!/bin/bash
#
#     printf -v curr_date '%(%Y-%m-%d)T' -1
#     out_file="$tmp_dir/aprs_report_${curr_date}.txt"

VERSION="1.0"
scriptname="`basename $0`"

CSMSGFILE="/home/$USER/tmp/aprs_parse_file.txt"
tmp_dir="/home/pi/tmp"

cs=("n7nix-4" "k7bls-4" "wa7law")


# ===== function send_email
function send_email() {

    {
echo
echo "Testing at $(date)"
echo "/N7NIX bot"
} >> $CSMSGFILE

    subject="Test email for aprs parse $(date)"
    to_email="$USER@$(hostname)"

    mutt -s "$subject" $to_email < $CSMSGFILE
    echo "Mutt return code $?"
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

echo "APRS call sign check started: $(date)" > $CSMSGFILE

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


report_file_cnt=$(ls -1 /home/pi/tmp/aprs_report_${check_date}.txt 2>/dev/null | wc -l)
if [ $report_file_cnt -eq 0 ] ; then
    echo "No report files found."
    exit 0
fi

echo "Found $report_file_cnt report files"

for i in "${cs[@]}" ; do
    for file in $tmp_dir/aprs_report_$check_date.txt ; do
        echo
        echo "Call sign: $i file: $file"
	grep -i $i $file
    done
done

echo "Finished at: $(date)"
# send_email
