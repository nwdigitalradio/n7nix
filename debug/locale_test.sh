#!/bin/bash
DEBUG=

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function check locale settings
# Compare country code in X11 layout, WPA config file & iw reg settings

function check_locale() {
    wificonf_file="/etc/wpa_supplicant/wpa_supplicant.conf"
    x11_country=$(localectl status | grep "X11 Layout" | cut -d ':' -f2)
    dbgecho "DEGBUG: x11_country 1: $x11_country"

    # Remove preceeding white space
    x11_country="$(sed -e 's/^[[:space:]]*//' <<<"$x11_country")"
    dbgecho "DEGBUG: x11_country 2: $x11_country"

    # Convert to upper case
    x11_country=$(echo "$x11_country" | tr '[a-z]' '[A-Z]')
    dbgecho "DEGBUG: x11_country 3: $x11_country"

    iw_country=$(iw reg get | grep -i country | cut -d' ' -f2 | cut -d':' -f1)
    dbgecho "DEGBUG: iw_country 1: $iw_country"

    # Convert to upper case
    iw_country=$(echo "$iw_country" | tr '[a-z]' '[A-Z]')
    dbgecho "DEGBUG: iw_country 2: $iw_country"

    if [ -e "$wificonf_file" ] ; then
        # Only match last occurrence
	wifi_country=$(sudo grep -i "country=" "$wificonf_file" | tail -n 1 | cut -d '=' -f2 )
        # Remove preceeding white space
        wifi_country="$(sed -e 's/^[[:space:]]*//' <<<"$wifi_country")"
        # Convert to upper case
        wifi_country=$(echo "$wifi_country" | tr '[a-z]' '[A-Z]')
    else
        echo "Local country code check: WiFi config file: $wificonf_file, does not exist"
        wifi_country="00"
    fi

    if [ "$x11_country" == "$wifi_country" ] && [ "$x11_country" == "$iw_country" ]; then
        echo "Locale country codes consistent among WiFi cfg file, iw reg & X11: $wifi_country"
    else
        echo "Locale country codes do not match: WiFi: $wifi_country, iw: $iw_country, X11: $x11_country."
     fi
}

# ===== main

echo "---- locale"
check_locale

# If there any command lines then set wifi config.

if [ $# -gt 0 ] ; then
    echo "=== Set WiFi country code to $x11_country"

    # Not sure if this works in countries other than US.
    # Convert country code to lower case
    country_code=$(echo "$x11_country" | tr '[A-Z]' '[a-z]')
    # Set WiFi country code in first line of wpa_supplicant config file.
    sudo sed -i '1i\'"country=$country_code" /etc/wpa_supplicant/wpa_supplicant.conf
    # Set WiFi regulatory domain
    iw reg set $x11_country
    check_locale
fi
