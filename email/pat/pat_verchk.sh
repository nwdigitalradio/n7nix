#!/bin/bash
#
# Get latest version of PAT
#
# Uncomment this statement for debug echos
#DEBUG=1

scriptname="`basename $0`"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get_installed_pat_ver
# get currently installed version

function get_installed_pat_ver() {

    # Determine if program has been installed
    type -P $progname  >/dev/null 2>&1
    if [ "$?"  -ne 0 ]; then
        installed_pat_ver="NOT installed"
    else
        dbgecho "Found $progname"
        installed_pat_ver=$(pat version | cut -f2 -d ' ' | sed 's/[^0-9\.]*//g')
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

progname="pat"

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
            get_installed_pat_ver
            echo "$progname: $installed_pat_ver"
            exit
        ;;
        -u)
            dbgecho "Update pat after checking version numbers."
            UPDATE_FLAG=true
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

get_installed_pat_ver

# get current version number in repo
pat_ver=$(curl -s https://raw.githubusercontent.com/la5nta/pat/master/VERSION.go | grep -i "Version = " | cut -f2 -d '"')

echo "PAT: current version: $pat_ver, installed: $installed_pat_ver"
