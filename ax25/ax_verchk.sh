#!/bin/bash
#
# Display debian source versions for libax25, ax25apps, ax25tools
#
# Program from ax25tools: nrparms
# Program from ax25apps: call
# library version number:
# use ldconfig -v | grep libraryname , also command has option command -V or binaryfile --version
# libax25io.la
# libax25.so
# libax25.so.1
#
# VE7FET repo:
#
# https://raw.githubusercontent.com/ve7fet/linuxax25/master/ax25apps/configure.ac
# https://raw.githubusercontent.com/ve7fet/linuxax25/master/ax25tools/configure.ac
# https://raw.githubusercontent.com/ve7fet/linuxax25/master/libax25/configure.ac
#
# Uncomment this statement for debug echos
#DEBUG=1

declare -A fetrepo
declare -A nixrepo
declare -A install
bupgrade=false

# ===== function dbgecho

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function version_gt
# Determine if first argument $1 is greater than second argument

function version_gt() {
#    printf 'version_gt: %s\n' "$@" | sort -V | head -n 1
    test "$(printf '%s\n' "$@" | sort --version-sort | head -n 1)" != "$1";
}

# ===== main

fetrepo_libver=$(curl -s https://raw.githubusercontent.com/ve7fet/linuxax25/master/libax25/configure.ac | grep "AC_INIT(")
fetrepo[lib]=$(echo $fetrepo_libver | cut -f2 -d ' ' | cut -f1 -d',')
#echo "fet repo: ax25 lib: ${fetrepo[lib]}"

fetrepo_appver=$(curl -s https://raw.githubusercontent.com/ve7fet/linuxax25/master/ax25apps/configure.ac | grep "AC_INIT(")
fetrepo[app]=$(echo $fetrepo_appver | cut -f2 -d ' ' | cut -f1 -d',')
#echo "fet repo: ax25 apps: $fetrepo_appver"

fetrepo_toolver=$(curl -s https://raw.githubusercontent.com/ve7fet/linuxax25/master/ax25tools/configure.ac | grep "AC_INIT(")
fetrepo[tool]=$(echo $fetrepo_toolver | cut -f2 -d ' ' | cut -f1 -d',')

echo "fet repo: lib: ${fetrepo[lib]}, app: ${fetrepo[app]}, tool: ${fetrepo[tool]}"


nixrepo[lib]=$(ls -1 /home/pi/n7nix/ax25/debpkg/*.deb | grep -i libax25 | cut -f2 -d'_' | cut -f1 -d'-')
nixrepo[app]=$(ls -1 /home/pi/n7nix/ax25/debpkg/*.deb | grep -i ax25apps | cut -f2 -d'_' | cut -f1 -d'-')
nixrepo[tool]=$(ls -1 /home/pi/n7nix/ax25/debpkg/*.deb | grep -i ax25tools | cut -f2 -d'_' | cut -f1 -d'-')

echo "nix repo: lib: ${nixrepo[lib]}, app: ${nixrepo[app]}, tool: ${nixrepo[tool]}"

install[lib]=$(dpkg -l "libax25"  | tail -n 1 | tr -s '[[:space:]]' | cut -f3 -d' ' | cut -f1 -d'-')
install[app]=$(dpkg -l "ax25apps" | tail -n 1 | tr -s '[[:space:]]' | cut -f3 -d' ' | cut -f1 -d'-')
install[tool]=$(dpkg -l "ax25tools" | tail -n 1 | tr -s '[[:space:]]' | cut -f3 -d' ' | cut -f1 -d'-')

echo "install:  lib: ${install[lib]}, app: ${install[app]}, tool: ${install[tool]}"

PROGLIST="lib app tool"

# Check if nix repo up-to-date

for prog in $PROGLIST ; do
    first_version="${fetrepo[$prog]}"
    second_version="${nixrepo[$prog]}"

    dbgecho "nix repo check: $prog: $first_version, $second_version"

    if version_gt "$first_version" "$second_version" ; then
        echo "Repo version: $first_version is greater than installed version $second_version, n7nix needs to update his repo for $prog"
    fi
done


# Check if installed version up-to-date

for prog in $PROGLIST ; do
    first_version="${fetrepo[$prog]}"
    second_version="${install[$prog]}"

    dbgecho "Installed version check $prog: $first_version, $second_version"

    if version_gt "$first_version" "$second_version" ; then
        echo "$first_version is greater than $second_version, will install newer ax25 $prog"
    fi
done


if [ ! -z "$DEBUG" ] ; then
    first_version="1.1.0"
    second_version="1.0.3"

    echo "Code test: comparison: $first_version, $second_version"

    if version_gt $first_version $second_version; then
        echo "$first_version is greater than $second_version !"
        bupgrade=true
    fi
fi
