#!/bin/bash
#
# Uncomment this statement for debug echos
DEBUG=

scriptname="`basename $0`"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

firmware_prodfile="/sys/firmware/devicetree/base/hat/product"
firmware_prod_idfile="/sys/firmware/devicetree/base/hat/product_id"
firmware_vendorfile="/sys/firmware/devicetree/base/hat/vendor"

PROD_ID_NAMES=("INVALID" "INVALID" "UDRC" "UDRC II" "DRAWS" "1WSpot")
NWDIG_VENDOR_NAME="NW Digital Radio"

# ===== function EEPROM id_check =====

# Return code:
# 0 = no EEPROM or no device tree found
# 1 = HAT found but not a UDRC
# 2 = UDRC
# 3 = UDRC II
# 4 = DRAWS
# 5 = 1WSpot

function id_check() {
# Initialize to EEPROM not found
udrc_prod_id=0

# Does firmware file exist
if [ -f $firmware_prodfile ] ; then
   # Read product file
   UDRC_PROD="$(tr -d '\0' < $firmware_prodfile)"
   # Read vendor file
   FIRM_VENDOR="$(tr -d '\0' < $firmware_vendorfile)"
   # Read product id file
   UDRC_ID="$(tr -d '\0' < $firmware_prod_idfile)"
   #get last character in product id file
   UDRC_ID=${UDRC_ID: -1}

   dbgecho "UDRC_PROD: $UDRC_PROD, ID: $UDRC_ID"

   if [[ "$FIRM_VENDOR" == "$NWDIG_VENDOR_NAME" ]] ; then
      case $UDRC_PROD in
         "Universal Digital Radio Controller")
            udrc_prod_id=2
         ;;
         "Universal Digital Radio Controller II")
            udrc_prod_id=3
         ;;
         "Digital Radio Amateur Work Station")
            udrc_prod_id=4
         ;;
         "1WSpot")
            udrc_prod_id=5
         ;;
         *)
            echo "Found something but not a UDRC: $UDRC_PROD"
            udrc_prod_id=1
         ;;
      esac
   else

      dbgecho "Probably not a NW Digital Radio product: $FIRM_VENDOR"
      udrc_prod_id=1
   fi

   if [ udrc_prod_id != 0 ] && [ udrc_prod_id != 1 ] ; then
      if (( UDRC_ID == udrc_prod_id )) ; then
         dbgecho "Product ID match: $udrc_prod_id"
      else
         echo "Product ID MISMATCH $UDRC_ID : $udrc_prod_id"
         udrc_prod_id=1
      fi
   fi
   dbgecho "Found HAT for ${PROD_ID_NAMES[$UDRC_ID]} with product ID: $UDRC_ID"
else
   # RPi HAT ID EEPROM may not have been programmed in engineering samples
   # or there is no RPi HAT installed.
   udrc_prod_id=0
fi

return $udrc_prod_id
}

# ===== function get_sndcard_list
# Get a list of sound cards that are not part of bcm2835
# Sets variable $extcard_names

function get_sndcard_list() {
    # Get list of all sound cards
    sndcard_names="$(aplay -l | grep "^card " | cut -f1 -d',')"

    # Get count of all sound cards
    sndcard_cnt=$(echo "$sndcard_names" | wc -l)

    echo " ==== List All sound card device names ($sndcard_cnt)"
    echo "$sndcard_names"
    # echo "Sound devices not internal to RPi"
    #grep -v "bcm2835" <<< "$sndcard_names"

    extcard_names=$(echo "$sndcard_names" | grep -v "bcm2835")
    #dbgecho "$extcard_names"
    echo
}

# ===== function display_id_eeprom =====

function display_id_eeprom() {
   echo "     HAT ID EEPROM"
   echo "Name:        $(tr -d '\0' </sys/firmware/devicetree/base/hat/name)"
   echo "Product:     $(tr -d '\0' </sys/firmware/devicetree/base/hat/product)"
   echo "Product ID:  $(tr -d '\0' </sys/firmware/devicetree/base/hat/product_id)"
   echo "Product ver: $(tr -d '\0' </sys/firmware/devicetree/base/hat/product_ver)"
   echo "UUID:        $(tr -d '\0' </sys/firmware/devicetree/base/hat/uuid)"
   echo "Vendor:      $(tr -d '\0' </sys/firmware/devicetree/base/hat/vendor)"
}

# ===== function check_overlay
# 07101.230: Loaded overlay 'udrc'
# 006791.899: Loaded overlay 'draws'

function check_overlay() {
    sudo vcdbg log msg 2>&1   | grep  -q "Loaded overlay 'draws'"
    draws_ret=$?
    sudo vcdbg log msg 2>&1   | grep -q "Loaded overlay 'udrc'"
    udrc_ret=$?

    dbgecho "UDRC overlay = $udrc_ret, DRAWS overlay = $draws_ret"

    if [ $draws_ret -eq 0 ] ; then
        echo "draws overlay loaded"
    fi
    if [ $udrc_ret -eq 0 ] ; then
        echo "udrc overlay loaded"
    fi

    if [ $draws_ret -eq 1 ] && [ $udrc_ret -eq 1 ]  ; then
        echo "No NWDR overlays were loaded"
    fi

    if [ ! -z $DEBUG ] ; then
        echo
        echo "List of all coverlays loaded"
        sudo vcdbg log msg 2>&1   | grep "overlays"
    fi
}

# ===== main

# If there are any command line args set debug flag
if [[ $# -gt 0 ]] ; then
    DEBUG=1
fi

echo " == get_sndcard_list"
get_sndcard_list

echo " == id_check"
id_check
NWDR_PROD_ID=$?
dbgecho "id_check return val: $NWDR_PROD_ID"

case $NWDR_PROD_ID in
0)
   echo "HAT firmware not initialized or HAT not installed."
   echo -e "\n\tNo id eeprom found\n"
;;
1)
   echo "Found a HAT but not a UDRC, product not identified"
   display_id_eeprom
;;
2)
   echo "Found an original UDRC"
   echo
   display_id_eeprom
;;
3)
   echo "Found a UDRC II"
   echo
   display_id_eeprom
;;
4)
   echo "Found a DRAWS"
   echo
   display_id_eeprom
;;
5)
   echo "Found a One Watt Spot"
   echo
   display_id_eeprom
;;
*)
   echo "Undefined return code: $NWDR_PROD_ID"
;;
esac

if [ "$NWDR_PROD_ID" -eq 2 ] || [ "$NWDR_PROD_ID" -eq 3 ] || [ "$NWDR_PROD_ID" -eq 4 ] ; then
    echo
    echo " == boot config file check"
    # dtoverlay=draws,alsaname=udrc
    # dtoverlay=udrc

    if [ -e "/boot/config.txt" ] ; then
        grep -iq "^dtoverlay=draws" /boot/config.txt
	drawsret=$?
        if [ $drawsret -eq 0 ] && [ "$NWDR_PROD_ID" -eq 4 ] ; then
            echo "boot config dtoverlay matches product ID"
        fi

        if [ $drawsret -ne 0 ] ; then
            grep -iq "^dtoverlay=udrc" /boot/config.txt
	    udrcret=$?
            if [ $udrcret -eq 0 ] && ([ "$NWDR_PROD_ID" -eq 2 ] || [ "$NWDR_PROD_ID" -eq 3 ]) ; then
                echo "boot config dtoverlay matches product ID"
	    fi
            if [ $udrcret -ne 0 ] ; then
	        echo "dtoverlay specified does not match any NWDR product ID"
	    fi
	fi

    else
        echo "Could NOT find /boot/config.txt file"
    fi
    check_overlay

else
    echo "Not finding an NWDR product, skipped check of boot config.txt file"
fi
