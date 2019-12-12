#!/bin/bash
#
# Uncomment this statement for debug echos
#DEBUG=1

scriptname="`basename $0`"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_direwolf
# Determine if direwolf is running

function is_direwolf() {
# Sox will NOT work if direwolf or any other sound card program is running
pid=$(pidof direwolf)
retcode="$?"
return $retcode
}

# ===== main

is_direwolf
if [ "$?" -eq 0 ] ; then
    echo "Direwolf is running, pid: $pid"
else
    echo "Direwolf is NOT running"
fi

# Verify programs are installed
PROGLIST="piARDOP_GUI piardop2 piardopc"


dbgecho "Verify required programs"
# Verify required programs are installed

for prog_name in `echo ${PROGLIST}` ; do
   type -P $prog_name &> /dev/null
   retcode="$?"
   if [ "$retcode" -ne 0 ] ; then
      echo "$scriptname: Need to Install $prog_name"
         NEEDPKG_FLAG=true
   else
       # Get last word of filename, break on under bar, only look at first 3 characters
       lastword=$(grep -oE '[^_]+$' <<< $prog_name | cut -c1-3)
       if [ "$lastword" != "GUI" ] ; then
           echo "Found program: $prog_name, $($prog_name -h | head -n 1)"
       else
           echo "Found program: $prog_name"
       fi
   fi
done

prog_name="arim"
type -P $prog_name &> /dev/null
if [ $? -ne 0 ] ; then
   echo "$scriptname: Need to Install $prog_name"
      NEEDPKG_FLAG=true
else
    echo "Found program: $prog_name, version: $($prog_name -v | head -n 1)"
fi

# Verify virtual sound device ARDOP
cfgfile="/home/$USER/.asoundrc"

if [ ! -e "$cfgfile" ] ; then
    echo "File: $cfgfile does not exist"
fi

grep -i "pcm.ARDOP" $cfgfile > /dev/null 2>&1
if [ $? -ne 0 ] ; then
    echo "No ARDOP entry in $cfgfile"
else
    echo "Found ARDOP entry in $cfgfile"
fi
