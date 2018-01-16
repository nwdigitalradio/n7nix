#!/bin/bash
#
# kern_cpy_local.sh
#
# Copy files to support udrc/udrx driver in a raspian linux source tree.
#

user="$(whoami)"

target_kern="/home/kernel/raspi_linux"
compass_kern="/home/$user/dev/github/linux"

defconfig_cfg="CONFIG_SND_BCM2708_SOC_UDRC CONFIG_AD9832 CONFIG_ADF4360 CONFIG_CMX991 CONFIG_LCD_HX8357 CONFIG_AD525X_DPOT CONFIG_AD525X_DPOT_I2C CONFIG_SENSORS_IIO_HWMON"

sound_soc_bcm_files="bcm2835-i2s.c Kconfig Makefile udrc.c"
sound_soc_codec_files="tlv320aic32x4.c tlv320aic32x4.h tlv320aic32x4-i2c.c tlv320aic32x4-spi.c"
boot_dts_overlay_files="udrc-boost-output-overlay.dts udrc-overlay.dts udrx-overlay.dts"
snd_bcm2708_soc_incfile="udrc.h"

filecnt=0
DIFF="diff -wBb"

kpath="arch/arm/configs"
fname="udr_defconfig"
echo "== diff $fname ==="
$DIFF $compass_kern/$kpath/$fname $target_kern/$kpath/bcm2709_defconfig
((filecnt++))

kpath="sound/soc/bcm"
for filename in `echo ${sound_soc_bcm_files}` ; do
   echo "== diff $filename ==="
   $DIFF $compass_kern/$kpath/$filename $target_kern/$kpath
   ((filecnt++))
done

kpath="sound/soc/codecs"
for filename in `echo ${sound_soc_codec_files}` ; do
   echo "== diff $filename ==="
   $DIFF $compass_kern/$kpath/$filename $target_kern/$kpath
   ((filecnt++))
done

kpath="arch/arm/boot/dts/overlays"
for filename in `echo ${boot_dts_overlay_files}` ; do
   echo "== diff $filename ==="
   $DIFF $compass_kern/$kpath/$filename $target_kern/$kpath
   ((filecnt++))
done

kpath="include/config/snd/bcm2708/soc"
for filename in `echo ${snd_bcm2708_incfile}` ; do
   echo "== diff $filename ==="
   $DIFF $compass_kern/$kpath/$filename $target_kern/$kpath
   ((filecnt++))
done

echo
echo "Total files checked: $filecnt"
