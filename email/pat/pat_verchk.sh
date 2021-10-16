#!/bin/bash
#
# Uncomment this statement for debug echos
#DEBUG=1

scriptname="`basename $0`"

# get currently installed version
prog_ver=$(pat version | cut -f2 -d ' ' | sed 's/[^0-9\.]*//g')

# get current version number in repo
pat_ver=$(curl -s https://raw.githubusercontent.com/la5nta/pat/master/VERSION.go | grep -i "Version = " | cut -f2 -d '"')

# Determine if program has been installed
progname="pat"
type -P $progname >/dev/null 2>&1
if [ "$?"  -ne 0 ]; then
    prog_ver="NOT installed"
else
    # get installed program version
    prog_ver=$(pat version | cut -f2 -d ' ' | sed 's/[^0-9\.]*//g')
fi

echo "PAT: current version: $pat_ver, installed: $prog_ver"
