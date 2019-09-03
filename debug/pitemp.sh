#!/bin/bash
vcgencmd measure_temp
vcgencmd get_throttled
throt=$(vcgencmd get_throttled | cut -d 'x' -f2)
if [[ "$throt" != 0 ]] ; then
    echo "   0: under-voltage"
    echo "   1: arm frequency capped"
    echo "   2: currently throttled"
    echo "  16: under-voltage has occurred"
    echo "  17: arm frequency capped has occurred"
    echo "  18: throttling has occurred"
fi

