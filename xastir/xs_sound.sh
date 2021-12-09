#!/bin/bash
# Verify where sound files are
# Seems to be a problem if compiled
# /usr/local/share/xastir/sounds does not seem to work
DEBUG=
COPY_FLAG=

XASTIR_CFG_FILE="$HOME/.xastir/config/xastir.cnf"

scriptname="$(basename $0)"
xastirpath=$(dirname $(which xastir))

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== Display program help info

usage () {
	(
	echo "Usage: $scriptname [-f[-h]"
        echo "   -c   Copy sound files"
	echo "   -d   Set debug flag"
        echo "   -h   Display this message"
        echo
	) 1>&2
	exit 1
}

# ===== Main

while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -d)
            DEBUG=1
        ;;
        -c|copy)
            echo "Copy sound files to proper share directory"
            COPY_FLAG=1
        ;;
        -h)
            usage
            exit 0
        ;;
        *)
            echo "Undefined argument: $key"
            usage
            exit 1
        ;;
    esac
    shift # past argument or value
done


echo "Xastir path: $xastirpath"

SHARE_DIR="/usr/share/xastir"
if [ -d "$SHARE_DIR" ] ; then
    filecnt=$(ls -salt $SHARE_DIR/sounds | grep -c -i "wav")
    echo "xastir share dir exists, with $filecnt sound files"
else
    echo "xastir share dir ($SHARE_DIR) does NOT exist"

fi

SHARE_DIR="/usr/local/share/xastir"
if [ -d "$SHARE_DIR" ] ; then
    filecnt=$(ls -salt $SHARE_DIR/sounds | grep -c -i "wav")
    echo "xastir local share dir  exists, with $filecnt sound files"
    if [ -e "$XASTIR_CFG_FILE" ] ; then
        sound_alerts=$(grep -i "sound_play"  $XASTIR_CFG_FILE)
        while IFS= read -r line; do
#           echo "... $line ..."
            alert_var=$(echo $line | cut -f1 -d ':')
            alert_enable=$(echo $line | cut -f2 -d ':')

            case $alert_var in
	        SOUND_PLAY_ONS)
	            alert_name="New Station"
		;;
	        SOUND_PLAY_ONM)
	            alert_name="New Message"
	        ;;
	        SOUND_PLAY_PROX)
	            alert_name="Proximity"
	        ;;
	        SOUND_PLAY_BAND)
	            alert_name="Band open"
	        ;;
	        SOUND_PLAY_WX_ALERT)
	            alert_name="Weather alert"
	        ;;
	        *)
	            echo "Sound var not found: $alert_var"
		    alert_name=""
		    alert_enable=0
	        ;;
	    esac
            dbgecho "DEBUG: var: $alert_var, name: $alert_name, enable: $alert_enable"
            enable_str="OFF"
	    if [ "$alert_enable" -eq 1 ] ; then
	        enable_str="ON"
	    fi
            printf "%s\t%s\n"  "$alert_name"  "$enable_str"

        done <<< "$sound_alerts"
    fi
else
    echo"xastir local share dir ($SHARE_DIR) does NOT exist"
fi

if [ -e "$XASTIR_CFG_FILE" ] ; then
    echo "Found Xastir config file: $XASTIR_CFG_FILE"
    sound_cmd=$(grep "SOUND_COMMAND" $XASTIR_CFG_FILE | cut -f2- -d':')
    echo "SOUND COMMAND configured: $sound_cmd"
    sound_dir=$(grep "SOUND_DIR" $XASTIR_CFG_FILE | cut -f2- -d':')

else
    echo "No Xastir config file found"
fi
