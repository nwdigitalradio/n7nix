#!/bin/bash
#
# Check for current version of node, npm, nvm

# ===== function dbgecho

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function node_ver
function node_ver() {

    source ~/.nvm/nvm.sh

# expect
  #  v19.8.1
  #  0
  #  9.5.1
  #  0
  #  0.39.3
  #  0

if [ ! -z "$DEBUG" ] ; then
    echo "debug:"
    node --version ; echo $? ; npm --version ; echo $? ; nvm --version ; echo $?
fi

    dbgecho "==== Installed versions ===="
    # Display node version
    node_ver=$(node --version)
    node_ret=$?
    if [ $node_ret -eq 0 ] ; then
        # Remove leading 'V'
        node_ver="${node_ver:1}"
        echo "node: $node_ver"
    else
        echo "node NOT installed"
    fi

    # Display npm (Node Package Manager) version
    npm_ver=$(npm --version)
    npm_ret=$?
    if [ $npm_ret -eq 0 ] ; then
        echo "npm: $npm_ver"
    else
        echo "npm NOT installed"
    fi

    # Display nvm (Node Version Manager) version
    nvm_ver=$(nvm --version)
    nvm_ret=$?
    if [ $nvm_ret -eq 0 ] ; then
        echo "nvm: $nvm_ver"
    else
        echo "nvm NOT installed"
    fi
}

# ===== main

node_ver
