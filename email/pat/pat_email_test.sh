#!/bin/bash
#
# Messages are posted to:
# ~/.local/share/pat/mailbox/YOURCALL/out
# ~/.local/share/pat/mailbox/$p_callsign
#
#
# PAT command line Commands:
#
# connect         Connect to a remote station.
#  interactive     Run interactive mode.
#  http            Run http server for web UI.
#  compose         Compose a new message.
#  read            Read messages.
#  composeform     Post form-based report.
#  position        Post a position report (GPSd or manual entry).
#  extract         Extract attachments from a message file.
#  rmslist         Print/search in list of RMS nodes.
#  updateforms     Download the latest form templates from winlink.org.
#  configure       Open configuration file for editing.
#  version         Print the application version.
#  env             List environment variables.
#  help            Print detailed help for a given command.

VERSION="1.0"
DEBUG=
NO_SEND=
SENDTO="noOne"

scriptname="`basename $0`"

PAT_CONFIG_FILE="${HOME}/.config/pat/config.json"
EMAIL_BODY_FILE="/tmp/emailbody.tmp"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function make_msg
# Make a well formed email message
#
# compose [options]
#	If no options are passed, composes interactively.
#	If options are passed, reads message from stdin similar to mail(1).
#
#Options:
#   --cc, -c          CC Address(es) (may be repeated)
#   --p2p-only        Send over peer to peer links only (avoid CMS)
#                     Recipient address (may be repeated)
#   --from, -r        Address to send from. Default is your call from config or --mycall, but can be specified to use tactical addresses.
#   --subject, -s     Subject
#   --attachment , -a Attachment path (may be repeated)

#  $MUTT -s "$subject" -c $ccto $SENDTO < $MSG_FILENAME

function make_msg() {
    {
        echo "CPU temperature & throttle check"
        vcgencmd measure_temp
        vcgencmd get_throttled
        echo
        echo "Uptime: $(uptime)"
        echo
        # Report file system disk space usage
        echo $(df -h | grep -i root)
        echo
    } > $EMAIL_BODY_FILE

    if [ ! -z $DEBUG ] ; then
        echo "===== email body file"
        cat $EMAIL_BODY_FILE
    fi

    subject="//WL2K $(hostname) $(date)"

    pat compose -s "$subject" -c "basil@pacabunga.com" "$SENDTO" < $EMAIL_BODY_FILE

    echo "pat compose ret code: $?"
}

# get call sign
function get_call() {

    p_callsign=$(grep -i -m 1 "mycall" $PAT_CONFIG_FILE | cut -d':' -f 2 | cut -d',' -f 1)
    dbgecho "debug1: $p_callsign"

    # remove leading whitespace characters
    p_callsign="${p_callsign#"${p_callsign%%[![:space:]]*}"}"
    dbgecho "debug2: $p_callsign"

    #Remove surronding quotes
    p_callsign="${p_callsign%\"}"
    p_callsign="${p_callsign#\"}"
    echo "local call sign: $p_callsign"
}

# ===== function get_pat_ax25_port

function get_pat_ax25_port() {

    port_used=$(grep -A 1 "ax25" $PAT_CONFIG_FILE | grep -i port | cut -f2 -d':' | cut -f1 -d',')
    # remove leading whitespace characters
    port_used="${port_used#"${port_used%%[![:space:]]*}"}"
    echo "debug2: $port_used"

    #Remove surronding quotes
    pat_port_used="${port_used%\"}"
    pat_port_used="${pat_port_used#\"}"
}

# ===== Display program help info
#
usage () {
	(
	echo "Version $scriptname: $VERSION"
	echo "Usage: $scriptname <Sendto email address> <transport method> <Destination gateway or P2P call sign>"
        echo
	) 1>&2
}

# ==== main

usage

# Get sendto call sign from command line args

if [[ "$#" -eq 0 ]] ; then
    echo "Number of command line args: $#"
    echo
    echo "$scriptname: requires command line argument of call sign to send email to"
    echo
    exit
else
    echo "Number of command line arguments: $#"
fi

# Initialize transport method
transport="telnet"

# Check for any command line arguments
if [[ "$#" -ge 1 ]] ; then

    SENDTO="$1"

    # Convert callsign to upper case
    SENDTO=$(echo "$SENDTO" | tr '[a-z]' '[A-Z]')
    # Add URL of email address
    SENDTO="$SENDTO@winlink.org"

    if [ ! -z $2 ] ; then
        transport="$2"
    fi
fi

echo "Sending email to $SENDTO using transport $transport"

# Get local call sign
get_call

outbox_dir="$HOME/.local/share/pat/mailbox/$p_callsign/out"

# Do this to get a list of files without directories
# ls -p -> append / indicator to directories
before_cnt=$(ls -p $outbox_dir | grep -v / | wc -l)

# For DEBUG purposes don't make or send any email
if [ -z $NO_SEND ] ; then
    make_msg

    after_cnt=$(ls -p $outbox_dir | grep -v / | wc -l)
    echo "outbox count before: $before_cnt, after: $after_cnt"
    if [ $transport = "telnet" ] ; then
        pat connect telnet
        echo "pat connect ret code: $?"
    elif [ $transport = "ax25" ] ; then

        # Sets variable 'pat_port_used'
        get_pat_ax25_port

        pat connect ax25+linux://$pat_port_used/n7nix
	echo "pat connect ret code: $?"
    else
        echo "Transport method $transport not supported"
    fi

fi

# After a 'pat connect' there should be no files left in the outbox
# directory
#
#  ls -p  $HOME/.local/share/pat/mailbox/KE7KML/out" | grep -v / | wc -l
current_cnt=$(ls -p $outbox_dir | grep -v / | wc -l)

if (( "current_cnt" > 0 )) ; then
    echo "===== outbox directory: count=$current_cnt: dir: $outbox_dir"
    ls -p $outbox_dir | grep -v '/'
fi
