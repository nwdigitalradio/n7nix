#!/bin/bash
#
# Read index of BBS & compare with local copy
# call options
# -S be silent
# -r raw mode
#
DEBUG=1
FORCE=0
SENDTO="gunn@beeble.localnet"
BBS_CALL="nixbbs"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function usage

function usage() {
   echo "Usage: $scriptname [-r <msg_num>][-a][-d][-f][-l][-sb][-sp][-h]" >&2
   echo "   -r <msg_num> Read message number"
   echo "   -a Read all messages"
   echo "   -d set debug flag"
   echo "   -D dump bbs files"
   echo "   -f Force refreshing local BBS files"
   echo "   -l Display message indexes"
   echo "   -s Send to BBS"
   echo "   -h no arg, display this message"
   echo
}

# ===== function notify_new_msg()

function notify_new_msg() {
    if [ -e "$1" ] ; then
        subject="bbs message notify: $date_now"
        mutt  -s "$subject" $SENDTO  < $1
        echo "Notification sent to: $SENDTO"
    else
        echo "notify: message file: $1 does not exist"
    fi
}

# ===== function dump_bbs_files()

function dump_bbs_files() {

    # Get current name of sesssion file
    session_file=$(ls -t $session_rootfile* | head -1)
    echo
    echo "==== session file: $session_file"
    echo
    cat "$session_file"

    # Get current name of index file
    dir_file=$(ls -t $dir_rootfile* | head -1)
    msg_cnt="$(cat $dir_file | wc -l)"
    echo
    echo "==== index file($msg_cnt): $dir_file"
    echo
    cat "$dir_file"

    # Get current name of message file
    echo
    msg_x_file=$(ls -t $msg_rootfile* | head -1)
    echo "==== message file: $msg_x_file"
    echo
    cat "$msg_x_file"
}

# ===== function readmsg_num()

readmsg_num() {
    readnum="$1"
    dir_file=$(ls -t $dir_rootfile* | head -1)
    msg_cnt="$(cat $dir_file | wc -l)"

    msg_x_file=$(ls -t $msg_rootfile* | head -1)
    msg_numbers=
    dbgecho "Reading msg # $readnum, total msgs: $msg_cnt, from file: $msg_x_file"
    for ((mn=1; mn <= $msg_cnt; mn++)) ; do
        msg_num=$((msg_cnt - mn + 1))

        msgtext=$(awk -vN=$mn 'n>=N;/ENTER COMMAND: .*/{++n}' $msg_x_file | grep -E -B 9999 -m1 "ENTER COMMAND: " | sed '$d')
        msgnum=$(echo $msgtext | cut -d '#' -f2 | cut -d ' ' -f1)
        msg_numbers="$msg_numbers $msgnum"
        if (( msgnum == readnum )) ; then
           echo "$msgtext"
           break;
        fi
    done

#    awk -vN=$mn 'n>=N;/ENTER COMMAND: .*/{++n}' $msg_x_file | grep -E -B 9999 -m$mn "(ENTER COMMAND: | *** Cleared)" | sed '$d'
#    msgtext=$(awk -vN=$mn 'n>=N;/ENTER COMMAND: .*/{++n}' $msg_x_file | grep -E -B 9999 -m1 "ENTER COMMAND: " | sed '$d')

    dbgecho "message numbers: $msg_numbers"
}

# ===== function readmsg_all()

readmsg_all() {
    dir_file=$(ls -t $dir_rootfile* | head -1)
    msgcnt="$(cat $dir_file | wc -l)"
    msg_x_file=$(ls -t $msg_rootfile* | head -1)

    echo "message count: $msgcnt"
    # Create a list of message numbers from message index file
    msg_num_list=
    while read -r line ; do
        msg_num_list="$msg_num_list $(echo $line |cut -d " " -f1)"
    done < $dir_file
    echo "DEBUG: msg_num_list $msg_num_list"

    for mn in `echo $msg_num_list` ; do
        echo
        echo "===== message: $mn"
#        awk -vN=$mn 'n>=N;/ENTER COMMAND: .*/{++n}' $msg_x_file | grep -E -B 9999 -m1 "(ENTER COMMAND: | *** Cleared)" | sed '$d'
#        awk -vN=$mn 'n>=N;/ENTER COMMAND: .*/{++n}' $msg_x_file | grep -E -B 9999 -m1 "ENTER COMMAND: " | sed '$d'
        grep -A 9999 MSG#$mn $msg_x_file | grep -E -B 9999 -m1 "ENTER COMMAND: " | sed '$d'
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
    echo "=== Get new index session file: ${session_rootfile}_$date_now.txt"

    # Get BBS Directory Session
{
sleep  2
printf "l\n"
sleep 8
sleep 4
printf "\n"
printf "b\n"
sleep 2
} | (call -r -s N7NIX -T 30 -W udr0 $BBS_CALL) > ${session_rootfile}_$date_now.txt

    dir_file=${dir_rootfile}_$date_now.txt
    create_msg_index $dir_file
}

# ===== function get_bbs_msgs()

function get_bbs_msgs() {


# Existing msg index file?
ls  -t $dir_rootfile*  > /dev/null 2>&1
if [ "$?" -ne 0 ] ; then
    # Create new index file
    get_msg_index
fi

dir_file=$(ls -t $dir_rootfile* | head -1)

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
sleep 4
printf "\n"
printf "b\n"

} | (call -r -s N7NIX -T 30 -W udr0 $BBS_CALL) > $msg_file 2>&1


}

# ===== function cmp_msg_index()

function cmp_msg_index() {
    indexfile_cnt=$(ls -1 $dir_rootfile* | wc -l)

    # Verify that there are 2 previous index files for comparison
    if (( indexfile_cnt >= 2 )) ; then
        last_dirfile=$(ls -t $dir_rootfile* | head -1)
        set -- $(ls -t $dir_rootfile*)
        prev_dirfile=$2
        echo "cmp_msg_index: last file: $last_dirfile, prev file: $prev_dirfile"
        diff $last_dirfile $prev_dir_file   > /dev/null 2>&1
        if [ "$?" -eq 0 ] ; then
            echo "cmp_msg_index: No changes found on bbs."
        else
            echo "cmp_msg_index: message index has changed"
            get_bbs_msgs
            notify_new_msg $(ls -t $msg_rootfile* | head -1)
        fi
    else
        echo "cmp_msg_index: No previous index file to compare"
    fi
}

# ===== function display_msg_index()

function display_msg_index() {
    dir_file=$(ls -t $dir_rootfile* | head -1)
    cat "$dir_file"
}

# ===== function send_to_bbs()
# arg b= bulletin, p=priviate

function send_to_bbs() {
bulletin_call="SJCACS"
outbox_dir="outbox"

if [ ! -d "./$outbox_dir" ] ; then
    echo "Outbox directory does not exist."
    exit 1
fi
msgcnt=0
sendcmd=""
for file in $(ls ./$outbox_dir/*) ; do
    filecnt=$((filecnt + 1))

    type_line=$(grep -i "type:" $file | cut -d ':' -f2)
    # Remove preceeding white space
    type_line="$(sed -e 's/^[[:space:]]*//' <<<"$type_line")"

    callsign_line=$(grep -i "callsign:" $file | cut -d ':' -f2)
    # Remove preceeding white space
    callsign="$(sed -e 's/^[[:space:]]*//' <<<"$callsign_line")"

    subject_line=$(grep -i "subject:" $file | cut -d ':' -f2)
    # Remove preceeding white space
    subject="$(sed -e 's/^[[:space:]]*//' <<<"$subject_line")"

    echo "Proposal $filecnt: type: $type_line, call sign: $callsign, subject: $subject"

    sendcmd="$sendcmd printf \"sb $callsign\n\"; sleep '2s'; printf \"$subject\n\"; sleep '2s' ; tail -n +5 $file ; sleep '4s' ;"

done

echo "senddcmd: $sendcmd"
testcode="true"

if [ "$testcode" == "true" ] ; then
{
eval $sendcmd

sleep 4
printf "b\n"

} | (call -r -s N7NIX -T 30 -W udr0 $BBS_CALL)

fi

echo "Number of messages in outbox: $filecnt"

}

# ===== function clean_up()
# arg filename root
function clean_up() {

filename_root="$1"
if [ -z "$filename_root" ] ; then
    echo "Clean_up called with no filename root"
    return;
fi
filename_count=$(ls -1 $filename_root* | wc -l)

echo "Clean_up filename: $filename_root, count: $filename_count"

while (( filename_count > 2 )) ; do

    filename=$(ls -t ${filename_root}* | tail -n1)
    echo "Removing file: $filename"
    rm $filename
    filename_count=$(ls -1 $filename_root* | wc -l)
done

}

# ===== main

date_now=$(date "+%Y%m%d_%H%M")
session_rootfile="${BBS_CALL}2m_session"
dir_rootfile="${BBS_CALL}2m_dir"
msg_rootfile="${BBS_CALL}2m_msg"

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
   -r|--read)
       msg_num="$2"
       shift # past argument

       readmsg_num $msg_num
       exit 0
   ;;
   -f|--force)
       FORCE=1
#       get_bbs_msgs
#       exit 0
   ;;
   -l|--list)
       display_msg_index
       exit 0
   ;;
   -s|--send)
       send_to_bbs b
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

msg_cnt=0
last_dirfile=

# Existing msg index file?
ls  -t $dir_rootfile*  > /dev/null 2>&1
if [ "$?" -eq 0 ] ; then
    # Get name of most recent index file
    last_dirfile=$(ls -t $dir_rootfile* | head -1)
    echo "Found an existing index file: $last_dirfile"
    msg_cnt="$(cat $last_dirfile | wc -l)"
else
    echo "No message index file found"
fi

# Time to refresh the latest index file?

echo "Refresh decision: elpased time: $elapsed_epoch, Message count: $msg_cnt, Force: $FORCE"

if ((elapsed_epoch >= 6000)) || ((msg_cnt == 0)) || [ "$FORCE" = 1 ] ; then
    # Update message index file
    get_msg_index
    cmp_msg_index
else
    # Test only
    cmp_msg_index
    echo "Using existing index file: $last_dirfile, no update at this time."
fi

clean_up "$msg_rootfile"
clean_up "$dir_rootfile"
clean_up "$session_rootfile"
