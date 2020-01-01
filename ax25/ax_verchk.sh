#!/bin/bash
#
# Display debian source versions for libax25, ax25apps, ax25tools
#
# Check version numbers with installed programs
# Program from ax25tools: nrparms -v
# Program from ax25apps: call -v
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
binstallupdate=false

# ===== function dbgecho

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== Display program help info
#
usage () {
	(
	echo "Usage: $scriptname [-u][-h]"
        echo "    No arguments displays current & installed versions."
        echo "    -u Set application update flag. Intall packages"
        echo "    -h display this message."
        echo
	) 1>&2
	exit 1
}

# ===== function version_gt

# Determine if first argument $1 is greater than second argument

function version_gt() {
#    printf 'version_gt: %s\n' "$@" | sort -V | head -n 1
    test "$(printf '%s\n' "$@" | sort --version-sort | head -n 1)" != "$1";
}

# ===== function display_ax25pkgver
# Display installed AX.25 package versions

function display_ax25pkgver() {
    install[lib]=$(dpkg -l "libax25"  | tail -n 1 | tr -s '[[:space:]]' | cut -f3 -d' ' | cut -f1 -d'-')
    install[app]=$(dpkg -l "ax25apps" | tail -n 1 | tr -s '[[:space:]]' | cut -f3 -d' ' | cut -f1 -d'-')
    install[tool]=$(dpkg -l "ax25tools" | tail -n 1 | tr -s '[[:space:]]' | cut -f3 -d' ' | cut -f1 -d'-')

    echo "install:  lib: ${install[lib]}, app: ${install[app]}, tool: ${install[tool]}"
}

# ===== main

# Check for any command line arguments
# Command line args are passed with a dash & single letter
#  See usage function

while [[ $# -gt 0 ]] ; do

    key="$1"
    case $key in
        -l)
            dbgecho "Display installed versions only."
            display_ax25pkgver
            exit
        ;;
        -u)
            echo "Update AX.25 packages after checking version numbers."
            echo
            bupgrade=true
        ;;
        -h)
            usage
            exit 0
        ;;
        *)
            echo "Undefined argument: $key"
            usage
            exit 1
        ;;
    esac
    shift # past argument or value
done

fetrepo_libver=$(curl -s https://raw.githubusercontent.com/ve7fet/linuxax25/master/libax25/configure.ac | grep "AC_INIT(")
fetrepo[lib]=$(echo $fetrepo_libver | cut -f2 -d ' ' | cut -f1 -d',')
#echo "fet repo: ax25 lib: ${fetrepo[lib]}"

fetrepo_appver=$(curl -s https://raw.githubusercontent.com/ve7fet/linuxax25/master/ax25apps/configure.ac | grep "AC_INIT(")
fetrepo[app]=$(echo $fetrepo_appver | cut -f2 -d ' ' | cut -f1 -d',')
#echo "fet repo: ax25 apps: $fetrepo_appver"

fetrepo_toolver=$(curl -s https://raw.githubusercontent.com/ve7fet/linuxax25/master/ax25tools/configure.ac | grep "AC_INIT(")
fetrepo[tool]=$(echo $fetrepo_toolver | cut -f2 -d ' ' | cut -f1 -d',')

echo "fet repo: lib: ${fetrepo[lib]}, app: ${fetrepo[app]}, tool: ${fetrepo[tool]}"


nixrepo[lib]=$(ls -1 $HOME/n7nix/ax25/debpkg/*.deb | grep -i libax25 | cut -f2 -d'_' | cut -f1 -d'-')
nixrepo[app]=$(ls -1 $HOME/n7nix/ax25/debpkg/*.deb | grep -i ax25apps | cut -f2 -d'_' | cut -f1 -d'-')
nixrepo[tool]=$(ls -1 $HOME/n7nix/ax25/debpkg/*.deb | grep -i ax25tools | cut -f2 -d'_' | cut -f1 -d'-')

echo "nix repo: lib: ${nixrepo[lib]}, app: ${nixrepo[app]}, tool: ${nixrepo[tool]}"

# Display installed AX.25 package versions
display_ax25pkgver

PROGLIST="lib app tool"

# Check if nix repo up-to-date
bnixupdate=false
for prog in $PROGLIST ; do
    first_version="${fetrepo[$prog]}"
    second_version="${nixrepo[$prog]}"

    dbgecho "nix repo check: $prog: $first_version, $second_version"

    if version_gt "$first_version" "$second_version" ; then
        echo "Repo version: $first_version is greater than installed version $second_version, n7nix needs to update his repo for $prog"
        bnixupdate=true
    fi
done

if $bnixupdate ; then
    echo "Update to n7nix repo required ... exiting."
    exit 1
fi


# Check if installed version up-to-date
binstallupdate=false
for prog in $PROGLIST ; do
    first_version="${fetrepo[$prog]}"
    second_version="${install[$prog]}"

    dbgecho "Installed version check $prog: $first_version, $second_version"

    if version_gt "$first_version" "$second_version" ; then
        echo "$first_version is greater than $second_version, will install newer ax25 $prog"
        binstallupdate=true
    fi
done

if $binstallupdate ; then

    if $bupgrade ; then
        echo "AX.25 packages will be updated"
        sudo dpkg -i $HOME/n7nix/ax25/debpkg/libax25_${nixrepo[lib]}-1_armhf.deb
        sudo dpkg -i $HOME/n7nix/ax25/debpkg/ax25apps_${nixrepo[app]}-1_armhf.deb
        sudo dpkg -i $HOME/n7nix/ax25/debpkg/ax25tools_${nixrepo[tool]}-1_armhf.deb

        # Verify installation of installed AX.25 packages
        # Display installed AX.25 package versions
        display_ax25pkgver
    else
        echo "AX.25 packages would have been updated"
    fi
else
    echo "AX.25 packages are up-to-date."
fi


if [ ! -z "$DEBUG" ] ; then
    first_version="1.1.0"
    second_version="1.0.3"

    echo "Code test: comparison: $first_version, $second_version"

    if version_gt $first_version $second_version; then
        echo "$first_version is greater than $second_version !"
    fi
fi
