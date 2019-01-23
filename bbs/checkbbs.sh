#!/bin/bash
#
# Read index of BBS & compare with local copy
# call options
# -S be silent
# -r raw mode

date_now=$(date "+%Y%m%d_%H%M")
session_rootfile="nixbbs2m_session"
dir_rootfile="nixbbs2m_dir"

session_file=$(ls -t $session_rootfile* | head -1)
echo "Session file: $session_file"
session_epoch=$(stat -c %Y $session_file)
current_epoch=$(date "+%s")
elapsed_epoch=$((current_epoch - session_epoch))

echo "DEBUG: Seconds since last session: $elapsed_epoch, current: $current_epoch, file epoch: $session_epoch"

if ((elapsed_epoch >= 6000)) ; then

# Get BBS Directory Session
{
sleep  1
printf "l\n"
sleep 4
printf "b\n"
} | (call -r -s N7NIX -T 30 -W udr0 nixbbs) | tee ${session_rootfile}_$date_now.txt

fi

dir_file=${dir_rootfile}_$date_now.txt

# Get BBS Directory

session_file=$(ls -t $session_rootfile* | head -1)
sed -e '1,/MSG#  ST SIZE   /d; /ENTER COMMAND:/,$d' $session_file > $dir_file

readcmd="sleep 1;"
while read -r line ; do
    msgnum=$(echo $line | cut -d ' ' -f1)
    echo "read msg number: $msgnum"
    readcmd="$readcmd r $msgnum; sleep 2; "
done < $dir_file

echo "readcmd: $readcmd"

{
echo "$readcmd"
} | (call -r -s N7NIX -T 30 -W udr0 nixbbs)

#  | (call -s N7NIX -S -r -W -T 60 udr0 nixbbs) > testfile.txt

# printf "~o nixbbs2m_$date_now\n"
# printf "l\n"
# printf "~c\n"
# printf "l\n"
# printf "r 1\n"
# printf "r 2\n"
# printf "~h~h\n"
# printf "\~h\n"
# printf "b\n"
