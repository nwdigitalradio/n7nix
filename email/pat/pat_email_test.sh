#!/bin/bash
#
# Messages are posted to:
# ~/.local/share/pat/mailbox/YOURCALL/out
# ~/.local/share/pat/mailbox/KE7KML
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


DEBUG=
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

#  $MUTT -s "$subject" -c $ccto $sendto < $MSG_FILENAME

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
    sendto="n7nix@winlink.org"
    pat compose -s $subject -c "basil@pacabunga.com" $sendto < $EMAIL_BODY_FILE
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
    echo "debug3: $p_callsign"
}

# ==== main


get_call

outbox_dir="$HOME/.local/share/pat/mailbox/$p_callsign/out"

before_cnt=$(ls -p  $outbox_dir | grep -v / | wc -l)

make_msg

after_cnt=$(ls -p  $outbox_dir | grep -v / | wc -l)

echo "outbox count before: $before_cnt, after: $after_cnt"
if { "$after_cnt" > 0 ] ; then
    echo "===== outbox directory: $outbox_dir"
    ls -salt $outbox_dir
fi

pat connect telnet
echo "pat connect ret code: $?"
