#!/bin/bash
#
# Check for current version of node, npm, nvm

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

echo "==== Installed versions ===="
node_ver=$(node --version)
node_ret=$?
# Remove leading 'V'
node_ver="${node_ver:1}"
if [ $node_ret -eq 0 ] ; then
    echo "node: $node_ver"
fi

npm_ver=$(npm --version)
npm_ret=$?
if [ $npm_ret -eq 0 ] ; then
    echo "npm: $npm_ver"
fi

nvm_ver=$(nvm --version)
nvm_ret=$?
if [ $nvm_ret -eq 0 ] ; then
    echo "nvm: $nvm_ver"
else
    echo "nvm NOT installed"
fi

