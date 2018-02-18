#!/bin/bash
#
# For Audio need to "Force audio out through HDMI"
#  - hdmi_drive=2
#
# Select one of the following:
# of_7 for official_7
# sf_7 for soundfounder_7
# sf_10 for soundfounder_10

# Default LCD display to config
lcd_select="sf_10"

cfg_in_file="/boot/config.txt"
cfg_out_file="$cfg_in_file"
#cfg_out_file="boot_test.txt"


# ===== function insert_str

# if string doesn't exist insert into file
function insert_str() {
   cfg_str="$1"
   grepret=$(grep -i "^$1" $cfg_in_file)
   if [ "$?" -ne "0" ] ; then
      # Add to bottom of file
      cat << EOT >> $cfg_out_file
$cfg_str
EOT
   else
      echo "Found existing string $cfg_str: $grepret"
   fi

}

# ===== function sunfounder_hdmi

# Insert common config lines for Sunfounder monitors
function sunfounder_hdmi() {
   grepret=$(grep "^hdmi_cvt" $cfg_in_file)
   if [ "$?" -ne "0" ] ; then
      # Add to bottom of file
      insert_str "hdmi_group=2"
      insert_str "hdmi_mode=87"
      insert_str "hdmi_drive=2"
   else
      echo "Found existing hdmi_cvt string: $grepret"
   fi
}

# ===== main

# Be sure we're running as root
if [[ $EUID != 0 ]] ; then
   echo "$scriptname: Must be root"
   exit 1
fi

# Check if there are any args on command line
if (( $# != 0 )) ; then
   lcd_select=$1
fi

echo "Configuring LCD: $lcd_select"
echo " === Modify /boot/config.txt"

case $lcd_select in
   "of_7")
      insert_str "lcd_rotate=2"
   ;;
   # hdmi_cvt= width height framerate aspect margins interlace reduced_blanking
   "sf_7")
      sunfounder_hdmi
      insert_str "hdmi_cvt=1024 600 60 3 0 0 0"
   ;;
   "sf_10")
      sunfounder_hdmi
      insert_str "hdmi_cvt=1280 800 60 5 0 0 0"
   ;;
esac

echo "FINISHED modifying $cfg_out_file"
