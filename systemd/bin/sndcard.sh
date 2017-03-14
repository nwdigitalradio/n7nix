#!/bin/bash
#
# Verify that aplay enumerates udrc sound card

CARDNO=$(aplay -l | grep -i udrc)

if [ ! -z "$CARDNO" ] ; then
   echo "udrc card number line: $CARDNO"
   CARDNO=$(echo $CARDNO | cut -d ' ' -f2 | cut -d':' -f1)
   echo "udrc is sound card #$CARDNO"
else
   echo "No udrc sound card found."
fi
