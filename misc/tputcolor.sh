#!/bin/bash
# tputcolors

echo
echo -e "$(tput bold) reg  bld  und   tput-command-colors$(tput sgr0)"

for i in $(seq 1 7); do
  echo " $(tput setaf $i)Text$(tput sgr0) $(tput bold)$(tput setaf $i)Text$(tput sgr0) $(tput sgr 0 1)$(tput setaf $i)Text$(tput sgr0)  \$(tput setaf $i)"
done

echo "$(tput bold)    Bold            "'$(tput bold)'
echo "$(tput sgr 0 1) Underline       "'$(tput sgr 0 1)'
echo "$(tput sgr0)    Reset           "'$(tput sgr0)'
echo
