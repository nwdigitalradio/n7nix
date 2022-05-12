#!/bin/bash
#
# which-desktop.sh
#

if [ -z "$XDG_CURRENT_DESKTOP" ] && [ -z "$GDMSESSION" ] ; then
    echo "Try running this script from a console launched from the window manager"
    exit 0
fi
printf 'Desktop: %s\nSession: %s\n' "$XDG_CURRENT_DESKTOP" "$GDMSESSION"
