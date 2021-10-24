#!/bin/bash
#

scriptname="`basename $0`"
progname="direwolf"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get_installed_direwolf_ver
function get_installed_direwolf_ver() {

    DEV=""

    type -P $progname  >/dev/null 2>&1
    if [ "$?"  -ne 0 ]; then
        installed_direwolf_ver="NOT installed"
    else
        dbgecho "Found $progname"
        #dire_ver=$(direwolf -v 2>/dev/null | grep -m 1 -i version | cut -d " " -f4)
        dire_ver=$(direwolf -v 2>/dev/null | grep -m 1 -i version)
        grep -i "development" <<< $dire_ver >/dev/null 2>&1
        if [ "$?" -eq 0 ] ; then
            dire_verx=$(echo $dire_ver | cut -d " " -f5)
	    DEV="Dev"
        else
            dire_verx=$(echo $dire_ver | cut -d " " -f4)
        fi
	dbgecho "Version dire_verx: $dire_verx $DEV"

	installed_direwolf_ver=$(echo "${dire_verx#*D} $DEV")
    fi
}

# ===== Display program help info
#
usage () {
	(
	echo "Usage: $scriptname [-u][-l][-h]"
        echo "    No arguments displays current & installed versions."
        echo "    -u Set application update flag."
        echo "       Update source, build & install."
        echo "    -l display local version only."
        echo "    -h display this message."
        echo
	) 1>&2
	exit 1
}

# ===== main

# Check for any command line arguments
# Command line args are passed with a dash & single letter
#  See usage function

while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -d)
            DEBUG=1
        ;;
        -l)
            dbgecho "Display local version only."
            get_installed_direwolf_ver
            echo "$progname: $installed_direwolf_ver"
            exit
        ;;
        -u)
            dbgecho "Update direwolf after checking version numbers."
	    UPDATE_FLAG=true
	    echo "Not implemented"
	    exit
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

get_installed_direwolf_ver
echo "Direwolf version: $installed_direwolf_ver : D${dire_ver#*D}"

