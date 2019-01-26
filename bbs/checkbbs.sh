#!/bin/bash
#
# Read index of BBS & compare with local copy
# call options
# -S be silent
# -r raw mode
#
DEBUG=1
FORCE=0

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function usage

function usage() {
   echo "Usage: $scriptname [-m <msg_num>][-a][-f][-h]" >&2
   echo "   -m <msg_num> Read message number"
   echo "   -a Read all messages"
   echo "   -i Show message indexes"
   echo "   -f Force refreshing local BBS files"
   echo "   -d set debug flag"
   echo "   -D dump bbs files"
   echo "   -h no arg, display this message"
   echo
}

# ===== function dump_bbs_files()

function dump_bbs_files() {
    # Get current name of session file
    dir_file=$(ls -t $dir_rootfile* | head -1)
    msg_cnt="$(cat $dir_file | wc -l)"
    echo "==== index file($msg_cnt): $dir_file"
    echo
    cat $dir_file

    msg_x_file=$(ls -t $msg_rootfile* | head -1)
    echo "==== message file: $msg_x_file"
    echo
    cat $msg_x_file
}

# ===== function readmsg_num()

readmsg_num() {
    mn="$1"
    dir_file=$(ls -t $dir_rootfile* | head -1)
    msg_cnt="$(cat $dir_file | wc -l)"
    if (( mn > msg_cnt )) ; then
        echo "Only $msg_cnt messages on BBS."
        exit 1
    fi
    msg_x_file=$(ls -t $msg_rootfile* | head -1)

    dbgecho "Reading msg # $mn, total msgs: $msg_cnt, from file: $msg_x_file"
#    awk -vN=$mn 'n>=N;/ENTER COMMAND: .*/{++n}' $msg_x_file | grep -E -B 9999 -m$mn "(ENTER COMMAND: | *** Cleared)" | sed '$d'
    awk -vN=$mn 'n>=N;/ENTER COMMAND: .*/{++n}' $msg_x_file | grep -E -B 9999 -m$mn "ENTER COMMAND: " | sed '$d'
    dbgecho "awk finished."
}

# ===== function readmsg_all()

readmsg_all() {
    dir_file=$(ls -t $dir_rootfile* | head -1)
    msgcnt="$(cat $dir_file | wc -l)"
    msg_x_file=$(ls -t $msg_rootfile* | head -1)

    echo "message count: $msgcnt"
    for ((mn =1; mn <= $msgcnt; mn++)) ; do
        awk -vN=$mn 'n>=N;/ENTER COMMAND: .*/{++n}' $msg_x_file | grep -E -B 9999 -m$mn "(ENTER COMMAND: | *** Cleared)" | sed '$d'
    done
}

# ===== function create_msg_index
# arg1 directory file name

function create_msg_index() {

    dir_file="$1"
    # create BBS Directory listing
    echo "=== Create directory file:  $dir_file"
    # Get current name of session file
    session_file=$(ls -t $session_rootfile* | head -1)
    sed -e '1,/MSG#  ST SIZE   /d; /ENTER COMMAND:/,$d' $session_file > $dir_file

    msg_cnt="$(cat $dir_file | wc -l)"
    echo "Total messages in directory: $msg_cnt"
}

# ===== function get_msg_index()

function get_msg_index() {
    echo "=== Getting index session file: ${session_rootfile}_$date_now.txt"

    # Get BBS Directory Session
{
sleep  2
printf "l\n"
sleep 4
printf "b\n"
} | (call -r -s N7NIX -T 30 -W udr0 nixbbs) > ${session_rootfile}_$date_now.txt

    dir_file=${dir_rootfile}_$date_now.txt
    create_msg_index $dir_file
}

# ===== function display_msg_index()

function display_msg_index() {
    dir_file=$(ls -t $dir_rootfile* | head -1)
    cat "$dir_file"
}

# ===== function get_bbs_msgs()

function get_bbs_msgs() {

# Create new index file
get_msg_index
dir_file=$(ls -t $dir_rootfile* | head -1)
if [ ! -e "$dir_file" ] ; then
    create_msg_index $dir_file
fi

# Create new msg file
msg_file=${msg_rootfile}_$date_now.txt

echo "=== Create message file: $msg_file"

readcmd=""
while read -r line ; do
    msgnum=$(echo $line | cut -d ' ' -f1)
    dbgecho "read msg number: $msgnum"
    readcmd="$readcmd printf \"r $msgnum\n\"; sleep '2s';"
done < $dir_file

echo "readcmd: $readcmd"
echo "multiple commmand test"
# eval $readcmd
sleepb4call="6"
echo "Waiting $sleepb4call seconds before second call"
sleep $sleepb4call


{
eval $readcmd

sleep 8
printf "b\n"

} | (call -r -s N7NIX -T 30 -W udr0 nixbbs) > $msg_file 2>&1


}

# ===== main

date_now=$(date "+%Y%m%d_%H%M")
session_rootfile="nixbbs2m_session"
dir_rootfile="nixbbs2m_dir"
msg_rootfile="nixbbs2m_msg"

ALL_MSGS="false"
FORCE=0

session_file=$(ls -t $session_rootfile* | head -1)
msg_file=$(ls -t $msg_rootfile* | head -1)
echo "Existing files: Session file: $session_file, Msg file: $msg_file"

session_epoch=$(stat -c %Y $session_file)
msg_epoch=$(stat -c %Y $msg_file)

current_epoch=$(date "+%s")
elapsed_epoch=$((current_epoch - session_epoch))

dbgecho "DEBUG: Seconds since last session: $elapsed_epoch, current: $current_epoch, file epoch: $session_epoch"


# Command line args are passed with a dash & single letter
#  See usage function

while [[ $# -gt 0 ]] ; do
key="$1"

case $key in
   -d|--debug)
       DEBUG=1
       echo "Debug mode on"
   ;;
   -D|--dump)
       dump_bbs_files
       exit 0
   ;;
   -a|--all)
       ALL_MSGS="true"
       readmsg_all
       exit 0
   ;;

   -m|--msg)
       msg_num="$2"
       shift # past argument

       echo "Displaying message number: $msg_num"
       readmsg_num $msg_num
       exit 0
   ;;

   -f|--force)
       FORCE=1
       get_bbs_msgs
       exit 0
   ;;
   -i|-index)
       display_msg_index
       exit 0
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



if ((elapsed_epoch >= 6000)) || ((msg_cnt == 0)) || [ "$FORCE" = 1 ] ; then
    get_bbs_msgs
else
    echo "Using existing message file: $msg_file"
fi


