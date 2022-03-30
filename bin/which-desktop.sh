#!/bin/bash
#
# which-desktop.sh
#

printf 'Desktop: %s\nSession: %s\n' "$XDG_CURRENT_DESKTOP" "$GDMSESSION"
