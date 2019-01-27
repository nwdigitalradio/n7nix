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
    if (( readnum > msg_cnt )) ; then
        echo "Only $msg_cnt messages on BBS."
        exit 1
    fi
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
    for ((mn =1; mn <= $msgcnt; mn++)) ; do
        msg_num=$((msgcnt - mn + 1))
        echo
        echo "===== message: $msg_num"
#        awk -vN=$mn 'n>=N;/ENTER COMMAND: .*/{++n}' $msg_x_file | grep -E -B 9999 -m1 "(ENTER COMMAND: | *** Cleared)" | sed '$d'
        awk -vN=$mn 'n>=N;/ENTER COMMAND: .*/{++n}' $msg_x_file | grep -E -B 9999 -m1 "ENTER COMMAND: " | sed '$d'
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
printf "b\n"

} | (call -r -s N7NIX -T 30 -W udr0 nixbbs) > $msg_file 2>&1


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

   -r|--read)
       msg_num="$2"
       shift # past argument

       readmsg_num $msg_num
       exit 0
   ;;

   -f|--force)
       FORCE=1
       get_bbs_msgs
       exit 0
   ;;
   -l|-list)
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

    # Verify that there is a previous index file
    if [ ! -z "$last_dirfile" ] ; then
        diff $last_dirfile $dir_file   > /dev/null 2>&1
        if [ "$?" -eq 0 ] ; then
            echo "No new messages found on bbs."
        else
            echo "Update index file & msg file."
            get_bbs_msgs
        fi
    else
        echo "No previous index file to compare"
    fi
else
    echo "Using existing index file: $last_dirfile, no update at this time."
fi

clean_up "$msg_rootfile"
clean_up "$dir_rootfile"
clean_up "$session_rootfile"
