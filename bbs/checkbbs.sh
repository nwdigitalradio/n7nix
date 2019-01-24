#!/bin/bash
#
# Read index of BBS & compare with local copy
# call options
# -S be silent
# -r raw mode
#
DEBUG=1

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== main

date_now=$(date "+%Y%m%d_%H%M")
session_rootfile="nixbbs2m_session"
dir_rootfile="nixbbs2m_dir"
msg_rootfile="nixbbs2m_msg"

session_file=$(ls -t $session_rootfile* | head -1)
msg_file=$(ls -t $msg_rootfile* | head -1)
echo "Existing files: Session file: $session_file, Msg file: $msg_file"

session_epoch=$(stat -c %Y $session_file)
msg_epoch=$(stat -c %Y $msg_file)


current_epoch=$(date "+%s")
elapsed_epoch=$((current_epoch - session_epoch))

dbgecho "DEBUG: Seconds since last session: $elapsed_epoch, current: $current_epoch, file epoch: $session_epoch"

# Check if directory file is current
if ((elapsed_epoch >= 6000)) ; then
    echo "  Refreshing ${session_rootfile}_$date_now.txt"

    # Get BBS Directory Session
{
sleep  1
printf "l\n"
sleep 4
printf "b\n"
} | (call -r -s N7NIX -T 30 -W udr0 nixbbs) > ${session_rootfile}_$date_now.txt

    sleepb4call="5"
    echo "Waiting before second call: $sleepb4call"
else
    echo "  Using existing $session_file"
fi

dir_file=${dir_rootfile}_$date_now.txt
# Get BBS Directory

# Get current name of session file
session_file=$(ls -t $session_rootfile* | head -1)
sed -e '1,/MSG#  ST SIZE   /d; /ENTER COMMAND:/,$d' $session_file > $dir_file

msg_cnt="$(cat $dir_file | wc -l)"
echo "Total messages: $msg_cnt"

if ((elapsed_epoch >= 6000)) || ((msg_cnt == 0)) ; then
    echo "  Refreshing ${session_rootfile}_$date_now.txt"

# Create new msg file
msg_file=${msg_rootfile}_$date_now.txt

readcmd=""
while read -r line ; do
    msgnum=$(echo $line | cut -d ' ' -f1)
    dbgecho "read msg number: $msgnum"
    readcmd="$readcmd printf \"r $msgnum\n\"; sleep '2s';"
done < $dir_file

echo "readcmd: $readcmd"
echo "multiple commmand test"
# eval $readcmd


{
eval $readcmd

sleep 4
printf "b\n"

} | (call -r -s N7NIX -T 30 -W udr0 nixbbs) > $msg_file

else
    echo "Using existing message file: $msg_file"
fi

msg_x_file=$(ls -t $msg_rootfile* | head -1)
echo "Using msg file: $msg_x_file"
#sed -e '1,/ENTER COMMAND: /d; /ENTER COMMAND:/,$d' $msg_x_file > testfile.txt

sed -e '1,/ENTER COMMAND: /d; /ENTER COMMAND:/,$d' $msg_x_file

echo
echo "==============="
cat $msg_x_file
echo "==============="
