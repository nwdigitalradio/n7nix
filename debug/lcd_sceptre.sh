#!/bin/bash
#
# For RPi 4  /boot/config.txt file to make Sceptre E16 lcd monitor work
#
# Need boot config.txt file to look like this
#[pi4]
## Enable DRM VC4 V3D driver on top of the dispmanx display stack
##dtoverlay=vc4-fkms-v3d
#max_framebuffers=2
#hdmi_force_hotplug:0=1
#hdmi_group:0=1
#hdmi_mode:0=4

BOOT_CFG_FILE="config.txt"

# Comment 'dtoverlay=' line in [pi4] section
echo "Edit first line after [pi4]"
#sed -i -e "/\[pi4\]/ s/^dtoverlay=.*/#&/" $BOOT_CFG_FILE
#sed -i -e "/\[pi4\]/ s/^dtoverlay=.*/#dtoverlay=/" $BOOT_CFG_FILE
#sed -i -e "s/^dtoverlay=.*/#&/" $BOOT_CFG_FILE
sed -i -e "/\[pi4\]/,/\[/ s/^dtoverlay=.*/#&/" $BOOT_CFG_FILE


echo
echo "Add 3 lines at first blank line in [pi4] section"
# Add 3 lines after above line
#sed -i -e '/\[pi4\]/,/\[/ /^#dtoverlay=.*/a\
#sed -i -e '/\[pi4\]/,/\[/a\
sed -i -e '/^\[pi4\]/,/^$/s/^$/hdmi_force_hotplug:0=1\
hdmi_group:0=1\
hdmi_mode:0=4\
/' $BOOT_CFG_FILE

echo
diff $BOOT_CFG_FILE config.bak
echo "End edit"
