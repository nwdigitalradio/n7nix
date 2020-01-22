#!/bin/bash

ax25ipd_pid=$(pidof ax25ipd)
if [ ! -z "$ax25ipd_pid" ] ; then
    echo "ax25ipd is running with pid: $ax25ipd_pid, will stop"
    kill "$ax25ipd_pid"
else
    echo "ax25ipd not running"
fi


