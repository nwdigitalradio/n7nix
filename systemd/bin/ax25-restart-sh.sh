#!/bin/sh
#
# This script stops then starts direwolf & all AX.25 systemd services
# Script syntax changed from bash to Bourne shell to run from 'at' command

USER=
QUIET=
DEVWAIT=12000

# if DEBUG is defined then echo
dbgecho() { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# if QUIET is defined the DO NOT echo
quietecho() { if [ -z "$QUIET" ] ; then echo "$*"; fi }

# ===== function get_user
# When running as root need to find a valid local bin directory
# Set USER based on finding a REQUIRED_PROGRAM

get_user() {
   # Check if there is only a single user on this system
   if [ $(ls /home | wc -l) -eq 1 ] ; then
       USER=$(ls /home)
   else
       USER=
       # Get here when there is more than one user on this system,
       # Find the local bin that has the requested program
       # Requested program list: REQUIRED_PROGRAM

       REQUIRED_PROGRAM="ax25-stop"

       for DIR in $(ls /home | tr '\n' ' ') ; do
          if [ -d "/home/$DIR" ] && [ -e "/home/$DIR/bin/$REQUIRED_PROGRAM" ] ; then
              USER="$DIR"
              dbgecho "DEBUG: found dir: /home/$DIR & /home/$DIR/bin/$REQUIRED_PROGRAM"

              break
          fi
        done
    fi
}

# ==== function check_user
# Verify user name is legit

check_user() {
   userok=false
   dbgecho "$scriptname: Verify user name: $USER"
   for username in $USERLIST ; do
      if [ "$USER" = "$username" ] ; then
         userok=true;
      fi
   done

   if [ "$userok" = "false" ] ; then
      echo "$scriptname: ERROR: User name ($USER) does not exist,  must be one of: $USERLIST"
      exit 1
   fi

   dbgecho "using USER: $USER"
}

# ===== function wait_not
# wait until device does not exist

wait_not() {
    devnum=0
    devname="ax$devnum"
    PARMDIR="/proc/sys/net/ax25/$devname"
    elapsed_time=0
#   begin_time=$SECONDS
    begin_time=$(($(date +%s%N)/1000000))
    while [ $elapsed_time -lt $DEVWAIT ] ; do
        if [ ! -d "$PARMDIR" ] ; then
            break;
	fi
#	elapsed_time=$((SECONDS-begin_time))
        currentsec=$(($(date +%s%N)/1000000))
        elapsed_time=$((currentsec - begin_time))
    done
    # DEBUG only
    if [ -z "$DEBUG" ] ; then
        # elapsed_time=$((SECONDS-begin_time))
        currentsec=$(($(date +%s%N)/1000000))
        elapsed_time=$((currentsec - begin_time))
        echo "ax25-restart: Wait time: $elapsed_time"
    fi
}

# ===== function stop_service

stop_service() {
    service="$1"
    $SYSTEMCTL stop "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem STOPPING $service"
    fi
}

# ===== function start_service
start_service() {
    $SYSTEMCTL --no-pager start "$service"
    if [ "$?" -ne 0 ] ; then
        echo "Problem starting $service"
        systemctl status $service
        exit
    fi
}

# ===== function usage

usage() {
   echo "Usage: $scriptname [-q][-d][-h][USER]" >&2
   echo "   -q | --quiet    Set quiet flag (for running in a sub shell)"
   echo "   -d | --debug    Set debug flag for verbose output"
   echo "   -h | --help     Display this message"
   echo
}


# ===== main

while [ $# -gt 0 ] ; do
    APP_ARG="$1"

    case $APP_ARG in
        -q|--quiet)
            QUIET="-q"
       ;;
        -d|--debug)
            echo "Verbose output"
            DEBUG=1
       ;;
       -h|--help|-?|?)
            usage
            exit 0
       ;;
       *)
            # Might be a USER name
            USER="$1"
            break;
       ;;
    esac

    shift # past argument
done

# Check if running as root
if [ $(id -u) != 0 ] ; then
    # NOT running as root
    quietecho "set sudo"
    if [ -z $QUIET ] ; then
        SYSTEMCTL="sudo systemctl"
    else
        SYSTEMCTL="sudo systemctl --quiet"
    fi
    USER=$(whoami)
else
    if [ -z $QUIET ] ; then
        SYSTEMCTL="systemctl"
    else
        SYSTEMCTL="systemctl --quiet"
    fi

    # Get list of users with home directories
    USERLIST="$(ls /home)"
    USERLIST="$(echo $USERLIST | tr '\n' ' ')"

    get_user
    check_user
fi

# Order may be important
START_SERVICE_LIST="direwolf.service ax25dev.path ax25dev.service ax25-mheardd.service ax25d.service"
STOP_SERVICE_LIST="ax25dev.service ax25dev.path direwolf.service ax25-mheardd.service ax25d.service"

#LOCAL_BIN_PATH="/home/$USER/bin"
# sudo $LOCAL_BIN_PATH/ax25-stop $QUIET

for service in `echo ${STOP_SERVICE_LIST}` ; do
#    echo "DEBUG: Stopping service: $service"
    stop_service $service
done

# Wait until device goes away
wait_not
# sleep 1
# sudo $LOCAL_BIN_PATH/ax25-start $QUIET

for service in `echo ${START_SERVICE_LIST}` ; do
    start_service $service
    if [ "$service" = "direwolf.service" ] ; then
       while [ ! -L "/tmp/kisstnc" ] ; do
           sleep 0.4
       done
    fi
done
