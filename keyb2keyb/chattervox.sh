#!/bin/bash
#
USER=$(whoami)
REPO_DIR="/home/$USER/dev/github/chattervox"

#
# ===== main
#
# Check for repository directory
if [ ! -e "$REPO_DIR" ] ; then
    echo "Chatterfox has not been installed"
    exit 1
fi

cd $REPO_DIR

# echo "Test argument passing: $@"
node build/main.js "$@"
