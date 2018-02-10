#!/bin/bash
#
# For Audio need to "Force audio out through HDMI"
#  - hdmi_drive=2

screen_type="official_7"
screen_type="soundfounder_7"
screen_type="soundfounder_10"

cfg_in_file="/boot/config.txt"
#cfg_out_file="$cfg_in_file"
cfg_out_file="boot_test.txt"

echo " === Modify /boot/config.txt"

# ===== function insert_str

# if string doesn't exist insert into file
function insert_str() {
   cfg_str="$1"
   grepret=$(grep -i "^$1" $cfg_in_file)
   if [ $? -ne 0 ] ; then
      # Add to bottom of file
      cat << EOT >> $cfg_out_file
$cfg_str
EOT
   else
      echo "Found existing string $grepret"
   fi

}

# ===== function sunfounder_hdmi

# Insert common config lines for Sunfounder monitors
function sunfounder_hdmi() {
   grepret=$(grep "hdmi_cvt" $cfg_in_file)
   if [ $? -ne 0 ] ; then
      # Add to bottom of file
      insert_str "hdmi_group=2"
      insert_str "hdmi_mode=87"
      insert_str "hdmi_drive=2"
   fi
}

# ===== main

case $screen_type in
   case "official_7"
      insert_str "lcd_rotate=2"
   ;;
   # hdmi_cvt= width height framerate aspect margins interlace reduced_blanking
   case "sunfounder_7"
      insert_str "hdmi_cvt=1024 600 60 3 0 0 0"
      sunfounder_hdmi
   ;;
   case "sunfounder_10"
      insert_str "hdmi_cvt=1280 800 60 5 0 0 0"
      sunfouder_hdmi
   ;;
esac

echo "FINISHED modifying $cfg_out_file"
