#!/bin/bash
vcgencmd measure_temp
vcgencmd get_throttled
throt=$(vcgencmd get_throttled | cut -d 'x' -f2)
if [[ "$throt" != 0 ]] ; then
    echo "   0: under-voltage"
    echo "   1: arm frequency capped"
    echo "   2: currently throttled"
    echo "   3: soft temp limit active"
    echo "  16: under-voltage has occurred"
    echo "  17: ARM frequency capped has occurred"
    echo "  18: throttling has occurred"
    echo "  19: soft temp limit has occurred"
fi

