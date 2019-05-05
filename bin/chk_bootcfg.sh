#!/bin/bash
#
# Check /boot/config.txt file is set up properly
#  - verify on-board audio enable is on last line
#  - verify proper overlay is being loaded for HAT
#
#DEBUG=1
UPDATE_ENABLE=true

BOOT_CFGFILE="/boot/config.txt"

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function get product id of HAT

# Set PROD_ID:
# 0 = no EEPROM or no device tree found
# 1 = HAT found but not a UDRC
# 2 = UDRC
# 3 = UDRC II
# 4 = DRAWS
# 5 = 1WSpot

function get_prod_id() {
# Initialize product ID
PROD_ID=
prgram="udrcver.sh"

which $prgram > /dev/null 2>&1
if [ "$?" -eq 0 ] ; then
   dbgecho "Found $prgram in path"
   $prgram -
   PROD_ID=$?
else
   currentdir=$(pwd)
   # Get path one level down
   pathdn1=$( echo ${currentdir%/*})
   dbgecho "Test pwd: $currentdir, path: $pathdn1"
   if [ -e "$pathdn1/bin/$prgram" ] ; then
       dbgecho "Found $prgram here: $pathdn1/bin"
       $pathdn1/bin/$prgram -1
       PROD_ID=$?
   else
       echo "Could not locate $prgram default product ID to draws"
       PROD_ID=4
   fi
fi
}

# ===== check onboard audio device enabled
function chk_onboard_audio() {

    # Is write turned on?
    b_fixit=$1

    # Is last line 'dtparam=audio=on' ?
    last_line=$(tail -n1 $BOOT_CFGFILE)
    audio_on_line="dtparam=audio=on"

    if [ "$last_line" != "$audio_on_line" ] ; then
        echo "  Last line in $BOOT_CFGFILE NOT: $audio_on_line"

        # Check if update is enabled
        if $b_fixit ; then
            # Add Comment character to beginning of current audio line
            sudo sed -i -e 's/^dtparam=audio=on/#&/' $BOOT_CFGFILE
            # Add audio enable line to bottom of file
            sudo tee -a $BOOT_CFGFILE << EOT

# Enable audio (loads snd_bcm2835)
dtparam=audio=on
EOT
        fi
    else
        echo "  Last line in $BOOT_CFGFILE OK"
    fi
}

# ===== check that dtoverlay is for correct HAT
function chk_dtoverlay() {

    # Is write turned on?
    b_fixit=$1

    set_dtoverly=

#    dtoverlay_name=$(grep -i "dtoverlay" $BOOT_CFGFILE | tail -n 1 | cut -d"=" -f2)
    dtoverlay_name=$(grep -i "dtoverlay" $BOOT_CFGFILE | tail -n 1 | sed 's/^.*= //')
    if [ $? -eq 0 ] ; then
        echo "  dtoverlay currently set to: $dtoverlay_name"
    fi

    get_prod_id
    # Test product ID for UDRC or UDRC II
    if [[ "$PROD_ID" -eq 2 ]] || [[ "$PROD_ID" -eq 3 ]] ; then
        # UDRC or UDRC II hat
        # Verify dtoverlay=udrc
        grep -i "dtoverlay=udrc" $BOOT_CFGFILE > /dev/null 2>&1
        if [ $? -eq 0 ] ; then
            echo "  dtoverlay for UDRC II OK"
        else
            echo "  Using wrong overlay for UDRC or UDRC II"
            echo "  $(tput setaf 4)Changing from $dtoverlay_name to udrc$(tput setaf 7)"
            if $b_fixit ; then
                sudo sed -ier ':a;$!{N;ba};s/^\(.*\)dtoverlay=.*/\1dtoverlay=udrc/' $BOOT_CFGFILE
            fi
        fi
        # This shouldn't be here but it was convenient because it gets called from core_config.sh
        # Draws manager does NOT work with UDRC or UDRC II
        service="draws-manager.service"
        sudo systemctl disable "$service"
        if [ "$?" -ne 0 ] ; then
            echo "Problem DISABLING $service"
        fi
         sudo systemctl stop "$service"
         if [ "$?" -ne 0 ] ; then
            echo "Problem STOPPING $service"
        fi

    elif [ "$PROD_ID" -eq 4 ] ; then
        # Draws hat
        grep -i "dtoverlay=draws" $BOOT_CFGFILE > /dev/null 2>&1
        if [ $? -eq 0 ] ; then
            echo "  dtoverlay for DRAWS OK"
        else
            echo "  Using wrong overlay for DRAWS HAT"
            echo "  $(tput setaf 4)Changing from $dtoverlay_name to draws$(tput setaf 7)"
            if $b_fixit ; then
#                sed 's/\(.*\)^dtoverlay=.*/\1dtoverlay=draws/' $BOOT_CFGFILE
#                 sed -ier ':a;$!{N;ba};s/^(.*\n?)dtoverlay=.*/\1dtoverlay=draws/' $BOOT_CFGFILE
#                sudo sed -ier ':a;$!{N;ba};s/^\(.*\n?\)dtoverlay=.*/\1dtoverlay=draws/' $BOOT_CFGFILE
                 sudo sed -ier ':a;$!{N;ba};s/^\(.*\)dtoverlay=.*/\1dtoverlay=draws,alsaname=udrc/' $BOOT_CFGFILE
            fi
        fi
    else
        echo "Product ID test failed with: $PROD_ID"
    fi
}

# ===== main

echo
echo "Verify IF dtoverlay= is set properly"
chk_dtoverlay $UPDATE_ENABLE
echo
echo "Verify IF dtparam=audio is set properly"
chk_onboard_audio $UPDATE_ENABLE

