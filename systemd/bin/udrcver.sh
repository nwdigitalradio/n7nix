#!/bin/bash
#
# UDRC ID EEPROM check
# - return the product ID found in EEPROM
#
# 0 = no EEPROM or no devicetree found
# 1 = HAT found but not a UDRC
# 2 = UDRC
# 3 = UDRC II
#
# Uncomment this statement for debug echos
#DEBUG=1

firmware_prodfile="/sys/firmware/devicetree/base/hat/product"
firmware_prod_idfile="/sys/firmware/devicetree/base/hat/product_id"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== id_check =====

function id_check() {
# Initialize to EEPROM not found
udrc_prod_id=0
# Does firmware file exist
if [ -f $firmware_prodfile ] ; then
   # Read product file
   UDRC_PROD="$(cat $firmware_prodfile)"
   sizeprodstr=${#UDRC_PROD}
   dbgecho "UDRC_PROD: $UDRC_PROD, size: $sizeprodstr"
   if (( $sizeprodstr < 34 )) ; then
      dbgecho "Probably not a Universal Digital Radio Controller: $UDRC_PROD"
      udrc_prod_id=1
   elif [ "${UDRC_PROD:0:34}" == "Universal Digital Radio Controller" ] ; then
      dbgecho "Definitely some kind of UDRC"
   else
      echo "Found something but not a UDRC: $UDRC_PROD"
      udrc_prod_id=1
   fi

   # get last 2 characters in product file
   UDRC_PROD=${UDRC_PROD: -2}
   # Read product id file
   UDRC_ID="$(cat $firmware_prod_idfile)"
   #get last character in product id file
   UDRC_ID=${UDRC_ID: -1}
   udrc_prod_id=$UDRC_ID

   dbgecho "Product: $UDRC_PROD, Id: $UDRC_ID"
   if [ "$UDRC_PROD" == "II" ] && [ "$UDRC_ID" == "3" ] ; then
     dbgecho "Found a UDRC II"
   elif [ "$UDRC_PROD" == "er" ] && [ "$UDRC_ID" == "2" ] ; then
     dbgecho "Found an original UDRC"
   else
     udrc_prod_id=1
   fi

else
   # RPi HAT ID EEPROM may not have been programmed in engineering samples
   # or there is no RPi HAT installed.
   udrc_prod_id=0
fi

return $udrc_prod_id
}

# ===== display_id_eeprom =====

function display_id_eeprom() {
   echo "     HAT ID EEPROM"
   echo "Name:        $(cat /sys/firmware/devicetree/base/hat/name)"
   echo "Product:     $(cat /sys/firmware/devicetree/base/hat/product)"
   echo "Product ID:  $(cat /sys/firmware/devicetree/base/hat/product_id)"
   echo "Product ver: $(cat /sys/firmware/devicetree/base/hat/product_ver)"
   echo "UUID:        $(cat /sys/firmware/devicetree/base/hat/uuid)"
   echo "Vendor:      $(cat /sys/firmware/devicetree/base/hat/vendor)"
}

# ===== main =====

id_check
return_val=$?
dbgecho "Return val: $return_val"

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
   display_id_eeprom
;;
3)
  echo "Found a UDRC II"
  display_id_eeprom
;;
*)
  echo "Undefined return code: $return_val"
;;
esac

exit 0
