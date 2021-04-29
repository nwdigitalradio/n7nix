#!/bin/bash
#
# get all NET- alpha numerics from two programming csv files
#  list contains digital frequencies for 2M, 220 & 440 bands.
#
# rmslist.sh uses the output of this file in directory $HOME/n7nix/rmsgw
#  - rmslisth.sh can be found in $HOME/bin
#  - requires output file in $HOME/n7nix/rmsgw/freq_alpha.txt
#
# Use on workstation containing csv programming files:
#
# cd dev/github/n7nix/rmsgw
# ../bin/getalpha.sh > freq_alpha.txt
#
# For reference sed script to be used on a frequency string with
# decimal point
#  - remove preceding white space
#  - remove period (all punctuation)
#  - convert to lower case
# sed -e $'s/\t//g' -e "s/[[:punct:]]\+//g" -e "s/.*$/\L&/g"

# Programming files live here
freq_2m="$HOME/dev/github/SJACSflist/reffiles/Kenwood_TM-V71A.csv"
freq_220="$HOME/dev/github/SJACSflist/reffiles/Alinco_DR235.csv"

# Parse 2M, 440 csv file
while IFS= read -r line ; do

    alpha_str=$(echo $line | cut -d',' -f1)

    freq_str=$(echo $line | cut -d',' -f2 | tr -d '.')
    # right pad a string with zero
    freq_str=$(echo "$freq_str" | sed -e :a -e 's/^.\{1,8\}$/&0/;ta')
#     freq_str="$(printf -- '%-09s' $freq_str)"

    printf "%09s %s\n" "$freq_str"  "$alpha_str"

done <<< $(grep "NET-" $freq_2m | cut -d',' -f2,3)

# Parse 220 csv file
while IFS= read -r line ; do

    alpha_str=$(echo $line | cut -d',' -f1)

    freq_str=$(echo $line | cut -d',' -f2 | tr -d '.')
    # right pad a string with zero
    freq_str=$(echo "$freq_str" | sed -e :a -e 's/^.\{1,8\}$/&0/;ta')

    printf "%09s %s\n" "$freq_str"  "$alpha_str"

done <<< $(grep "NET-" $freq_220 | cut -d',' -f2,3)
