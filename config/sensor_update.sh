#!/bin/bash
#
# Update DRAWS sensor configuration file if kernel supports latest
# driver
#
# These flags get set from command line
DEBUG=
FORCE_UPDATE=

scriptname="`basename $0`"
sensor_fname="/etc/sensors.d/draws"

# ===== function make_sensor_cfg
# Replace draws sensor configuration file

function make_sensor_cfg() {

    echo "Making sensor config file based on this version of DRAWS hat"
    product_ver=$(tr -d '\0' </sys/firmware/devicetree/base/hat/product_ver)
    assembly_rev=$(echo $product_ver | cut -f2 -d'x' | cut -c1-2)
    fab_rev=${product_ver: -2}

    # convert hex number to decimal
    assembly_rev=$(( 16#$assembly_rev ))
    fab_rev=$(( 16#$fab_rev ))

    printf "Product ver: %s, Assembly rev: %d, fab rev: %d\n" $product_ver $assembly_rev $fab_rev

    if [ $fab_rev -ge 6 ] ; then
        echo "DRAWS has 5V connected to A/D"
    else
        echo "5V not connected to DRAWS A/D"
    fi

#    echo "DEBUG: calling ${FUNCNAME[0]} with kern ver: $1"

    if [ ! -z "$DEBUG" ] ; then
        echo
        echo "DEBUG: Would have replaced $sensor_fname file"
        echo
        return
    fi

    case $1 in
        4)
            sudo tee $sensor_fname > /dev/null << EOF
chip "ads1015-*"
    label in4 "+12V"
    label in6 "User ADC 1"
    label in7 "User ADC 2"
    compute in4 ((48.7/10)+1)*@, @/((48.7/10)+1)
EOF
            # Insert 5V config lines if DRAWS hat support it
            if [ $fab_rev -ge 6 ] ; then
                sudo tee -a $sensor_fname > /dev/null << EOF
    label in5 "+5V"
    compute in5 ((10/10)+1)*@, @/((10/10)+1)
EOF
            else
                sudo tee -a $sensor_fname > /dev/null << EOF
    ignore in5
EOF
            fi
        ;;
        5)
            sudo tee $sensor_fname > /dev/null << EOF
chip "iio_hwmon-*"
    label in1 "+12V"
    label in3 "User ADC 1"
    label in4 "User ADC 2"
    compute in1 ((48.7/10)+1)*@, @/((48.7/10)+1)
EOF
            # Insert 5V config lines if DRAWS hat support it
            if [ $fab_rev -ge 6 ] ; then
                sudo tee -a $sensor_fname > /dev/null << EOF
    label in2 " +5V"
    compute in2 ((10/10)+1)*@, @/((10/10)+1)
EOF
            else
                sudo tee -a $sensor_fname > /dev/null << EOF
    ignore in2
EOF
            fi
       ;;
       *)
           echo "Unknown kernel version $1"
           exit 1
       ;;
    esac
}

# ===== function update_sensor_cfg

function update_sensor_cfg() {
    # Get kernel version either 4 or 5 and greater
    kernver=$1

    # Does DRAWS sensor file name exist?
    if [ ! -e "$sensor_fname" ] ; then
        make_sensor_cfg $kernver
    else
        #
        # NOTE: Should only be checking this if kernel version requirement has been met.
        #
        # Check if proper sensor config file is already installed
        grep -i "iio_hwmon-" $sensor_fname > /dev/null 2>&1
        if [[ $? -eq 0 ]] ; then
            echo "Already have iio_hwmon config for draws sensors"
            if [ "$FORCE_UPDATE" = 1 ] ; then
                make_sensor_cfg $kernver
            fi
        else
            echo "Incorrect sensor config file found ... replacing."
            make_sensor_cfg $kernver
        fi
    fi
}

# ===== function kernver_check
# return 0 if kernel version is 5.4 or greater
# return 1 if kernel version is less than 5.4
# return 2 if not sure so don't update

function kernver_check() {

    retcode=1

    kernver_1dig=$(uname -r | cut -d'.' -f1)
    kernver_2dig=$(uname -r | cut -d'.' -f2)
    if [[ $kernver_1dig -ge 5 ]] ; then
        if [[ $kernver_1dig -eq 5 ]] ; then
            if [[ $kernver_2dig -lt 4 ]] ; then
                echo "sensor config: NOT updated based on kernel ver $(uname -r)"
                return 2
            fi
        fi
        retcode=0
    else
        retcode=1
    fi
    return $retcode
}

# ===== function check_sensor_cfg
# Look at Kernel version number and verify
# sensor config file is up-to-date
# If kern ver is >= 5.4 update sensor configuration file

function check_sensor_cfg() {

    kernver_check
    retcode=$?
    case $retcode in
        0)
            update_sensor_cfg 5
            ;;
        1)
            update_sensor_cfg 4
            ;;
        2)
            echo "sensor config: NOT updated based on kernel ver $(uname -r)"
            ;;
        *)
            echo "Unknown return code from kernver_check: $retcode"
            ;;
    esac
    echo
    echo "FINISHED updating sensor config file"
}

# ===== function display_status
function display_status() {
    echo "===== Kernel version"
    uname -a
    echo
    echo "===== Draws assembly & fab revision"
    product_ver=$(tr -d '\0' </sys/firmware/devicetree/base/hat/product_ver)
    echo "DRAWS version: $product_ver"
    echo
    echo "===== Sensor config file"
    cat /etc/sensors.d/draws
    echo
    echo "===== sensors output"
    sensors
    file_cnt=$(ls -1 ${sensor_fname}* | wc -l)
    if (( $file_cnt > 1 )) ; then
        echo
        echo "  More than 1 DRAWS sensor config file found ($file_cnt)."
        ls ${sensor_fname}*
    fi
}

# ===== function remove_tmp_files
function remove_tmp_files() {
    file_cnt=$(ls -1 ${sensor_fname}* | wc -l)
    if (( $file_cnt > 1 )) ; then
        echo "DEBUG: Found more than 1 draws config files ($file_cnt)"
        sudo rm ${sensor_fname}~
    fi
}

# ===== function usage

function usage() {
   echo "Usage: $scriptname [-f][-s][-d]"
   echo "   -f | --force   force update of sensor config file"
   echo "   -s | --status  display sensor config information"
   echo "   -d | --debug   display debug messages"
   echo
}

# ===== main

# Don't be root
if [[ $EUID == 0 ]] ; then
   echo "Do NOT run this script as root"
   exit 1
fi

# if there are any args then parse them
while [[ $# -gt 0 ]] ; do
   key="$1"

   case $key in
      -d|--debug)   # set DEBUG flag
         DEBUG=1
         echo "Set DEBUG flag"
         ;;
      -f|--force)
         FORCE_UPDATE=1
         echo "Set FORCE_UPDATE flag"
         ;;
      -s|--status)
         display_status
         exit 0
         ;;
      -h|--help)
         usage
	 exit 0
	 ;;
      *)
	echo "Unknown option: $key"
	usage
	exit 1
	;;
   esac
shift # past argument or value
done

# temporary files (ending in ~) in /etc/sensors.d/draws cause problems
remove_tmp_files

# Check if old sensor config file installed.
check_sensor_cfg
