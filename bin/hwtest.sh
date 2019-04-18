#!/bin/bash
#
# Verify hardware only

echo
echo " === Verify AudioSense-Pi drivers are not loaded."
b_foundAudioSense=false

# Check that the ASoC driver for the AudioSense-Pi soundcard is NOT
# loaded
driverdir="/lib/modules/$(uname -r)/kernel/sound/soc/codecs"
audiosense_i2c_drivername="snd-soc-tlv320aic32x4-i2c.ko"
audiosense_codec_drivername="snd-soc-tlv320aic32x4.ko"

if [ -e  "$driverdir/$audiosense_i2c_drivername" ] ; then
    echo "chk1: $audiosense_i2c_drivername exists, Driver CONFLICT"
    b_foundAudioSense=true
fi

if [ -e  "$driverdir/$audiosense_codec_drivername" ] ; then
    echo "chk2: $audiosense_codec_drivername exists, Driver CONFLICT"
    b_foundAudioSense=true
fi
if ! $b_foundAudioSense ; then
    echo "AudioSense drivers NOT loaded."
fi

echo
echo " === Verify Sound Card is found"

# Verify that aplay enumerates udrc sound card
aplay -l
echo

CARDNO=$(aplay -l | grep -i udrc)

if [ ! -z "$CARDNO" ] ; then
   echo "udrc card number line: $CARDNO"
   CARDNO=$(echo $CARDNO | cut -d ' ' -f2 | cut -d':' -f1)
   echo "udrc is sound card #$CARDNO"
else
   echo "No udrc sound card found."
fi

# Verify that the tlv320aic32 driver is loaded

echo
echo "=== Verify tlv320aic driver load"
dirname="/proc/device-tree/soc/i2c@7e804000/tlv320aic32x4@18"
if [ -d  "$dirname" ] ; then
    echo "Directory: $dirname exists and status is $(tr -d '\0' < $dirname/status)"
else
    echo -e "\n\tDirectory: $dirname does NOT exist\n"
    dirname="/proc/device-tree/soc/i2c@7e804000"
    if [ -d  "$dirname" ] ; then
        echo "Directory: $dirname exists and status is $(tr -d '\0' < $dirname/status)"
    else
        echo -e "\n\tDirectory: $dirname does NOT exist\n"
    fi
fi
