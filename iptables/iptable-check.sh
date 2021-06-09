#!/bin/bash
#
# iptable-check.sh
#
# Verify that iptables has been configured for AX.25 operation
# If iptables has not been configured then add some rules to the tables

DEBUG=
SU=
scriptname="`basename $0`"

rules_file="/etc/iptables/rules.ipv4.ax25"
hook_file="/lib/dhcpcd/dhcpcd-hooks/70-ipv4.ax25"

bFORCE_UPDATE=false

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== get_rule_count
# sets variable rule_count

function get_rule_count() {

    rule_count=$(grep -c "\-A OUTPUT" $rules_file)
}
# ===== write iptable rules
function write_rules() {
    if [ "$CREATE_IPTABLES" = "true" ] ; then

        sudo /bin/bash $BIN_DIR/iptable-flush.sh

        # Setup some iptable rules
        # 224.0.0.22
        #  - used for the IGMPv3 protocol.
        # 239.255.255.250:1900
        #  - Chromecast
        #  - traffic is discovery multicast traffic that occurs every 2 minutes from the system
        #  - UPnP (Universal Plug and Play)/SSDP (Simple Service Discovery Protocol) by various vendors to advertise the capabilities of (or discover) devices
        echo
        echo "== setup iptables"
        sudo /bin/bash $BIN_DIR/iptable-up.sh
        sudo sh -c "iptables-save > $rules_file"

        grep -q "iptables-restore" $hook_file > /dev/null 2>&1
        retcode="$?"
        if [ "$retcode" -ne 0 ] ; then
            echo "Setup restore command"
            sudo tee $hook_file > /dev/null <<EOF
iptables-restore < $rules_file
EOF
        fi
        get_rule_count
        echo "Number of ax25 rules now: $rule_count"
    fi
}

# ===== function get_user

function get_user() {
   # Check if there is only a single user on this system
   if (( `ls /home | wc -l` == 1 )) ; then
      USER=$(ls /home)
   else
      echo -n "Enter user name ($(echo $USERLIST | tr '\n' ' ')), followed by [enter]"
      read -ep ": " USER
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

# ===== function usage

function usage() {
    echo "Usage: $scriptname [-f][-d][-h]" >&2
    echo "   -f        Force an iptable update"
    echo "   -d        set Debug flag"
    echo "   -h        display this message"
    echo
}

#
# ===== main
#

while [[ $# -gt 0 ]] ; do
APP_ARG="$1"

case $APP_ARG in
   -f|--force)
       echo "Force an iptables rules update"
       bFORCE_UPDATE=true
   ;;
   -d|--debug)
      DEBUG=1
      echo "Debug mode on"
   ;;
   -h|--help|-?)
      usage
      exit 0
   ;;
   *)
       echo "Unrecognized command line argument: $APP_ARG"
       usage
       exit 0
   ;;

esac

shift # past argument
done

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
    echo "set sudo"
    SU="sudo"
    USER=$(whoami)
else
    get_user
    check_user
fi
BIN_DIR="/home/$USER/bin"

echo "==== List current iptables rules ===="
# List iptables rules
#
# with no table specified filter table is used by default
# -L list: List all rules in all chains
# -v verbose output
# -n numeric: IP addresses & port numbers are printed in numeric format
# -x exact: display exact value of the packet & byte counters instead of rounded number
# -t Netfilter tale (filter, nat, mangle, raw or security)
echo
echo " ***** FILTER table"
$SU iptables -L -nvx

rule_count=0
if [ -e "$rules_file" ] ; then
    get_rule_count
fi
echo
echo "Number of ax25 iptables rules found: $rule_count"

CREATE_IPTABLES=false

# Check force update iptables flag
if [ $bFORCE_UPDATE = false ] ; then
    # Check for required iptables files

    IPTABLES_FILES="$rules_file $hook_file"
    for ipt_file in `echo ${IPTABLES_FILES}` ; do

       if [ -f $ipt_file ] ; then
          echo "iptables file: $ipt_file exists"
       else
          echo "Creating iptables file: $ipt_file"
          CREATE_IPTABLES=true
       fi
    done
else
    CREATE_IPTABLES=true
fi

if [ -e "$rules_file" ] && [ $rule_count -lt 10 ] ; then
    dbgecho "Will create iptables rules due to rule count: $rule_count"
    CREATE_IPTABLES=true
fi

write_rules

if [ ! -z "$DEBUG" ] ; then
    IPTABLES_FILES="$rules_file $hook_file"
    for ipt_file in `echo ${IPTABLES_FILES}` ; do
        echo
        echo "== Dump file: $ipt_file"
        cat $ipt_file
    done
fi
