#!/bin/bash

USER=$(whoami)

sudo /home/$USER/bin/ax25-stop
sleep 1
sudo /home/$USER/bin/ax25-start
