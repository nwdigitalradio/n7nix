#!/bin/bash
#
# UDRC ID EEPROM check
# - return the product ID found in EEPROM
# - if any args are found just return product ID, no display
#
# 0 = no EEPROM or no device tree found
# 1 = HAT found but not a UDRC
# 2 = UDRC
# 3 = UDRC II
# 4 = DRAWS
# 5 = 1WSpot
#
# Uncomment this statement for debug echos
#DEBUG=1

firmware_prodfile="/sys/firmware/devicetree/base/hat/product"
firmware_prod_idfile="/sys/firmware/devicetree/base/hat/product_id"
firmware_vendorfile="/sys/firmware/devicetree/base/hat/vendor"

PROD_ID_NAMES=("INVALID" "INVALID" "UDRC" "UDRC II" "DRAWS" "1WSpot")
NWDIG_VENDOR_NAME="NW Digital Radio"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

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

# ===== main =====

id_check
return_val=$?
dbgecho "Return val: $return_val"
# check for any arguments indicating being called from another script.
if [[ $# -gt 0 ]] ; then
    exit $return_val
fi

case $return_val in
0)
   echo "HAT firmware not initialized or HAT not installed."
   echo "No id eeprom found, exiting"
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
   echo "Undefined return code: $return_val"
;;
esac

exit $return_val
