#!/bin/bash
#
# Install & configure uronode
#
# Uncomment this statement for debug echos
DEBUG=1

myname="`basename $0`"
AX25_CFGDIR="/usr/local/etc/ax25"
PKG_REQUIRE="telnet openbsd-inetd"

# Same info required by  RMS Gateway
CALLSIGN="NOONE"
CITY="LOPEZ Island"
STATE="WA"
GRIDSQUARE="CN88nl"
AX25PORT="udr0"
SSID="7"

USER=

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed" >/dev/null 2>&1)
}

# ===== function get_callsign

function get_callsign() {

if [ "$CALLSIGN" == "N0ONE" ] ; then
   read -t 1 -n 10000 discard
   echo "Enter call sign, followed by [enter]:"
   read -e CALLSIGN

   sizecallstr=${#CALLSIGN}

   if (( sizecallstr > 6 )) || ((sizecallstr < 3 )) ; then
      echo "Invalid call sign: $CALLSIGN, length = $sizecallstr"
      return 0
   fi

   # Convert callsign to upper case
   CALLSIGN=$(echo "$CALLSIGN" | tr '[a-z]' '[A-Z]')
fi

dbgecho "Using CALL SIGN: $CALLSIGN"
return 1
}

# ===== function get_user
function get_user() {
    # Check if there is only a single user on this system
    if (( `ls /home | wc -l` == 1 )) ; then
        USER=$(ls /home)
    else
        echo "Enter user name ($(echo $USERLIST | tr '\n' ' ')), followed by [enter]:"
        read -e USER
    fi
}
# ==== function check_user
# verify user name is legit

function check_user() {
   userok=false
   dbgecho "$scriptname: Verify user name: $USER"
   for username in $USERLIST ; do
      if [ "$USER" = "$username" ] ; then
         userok=true;
      fi
   done

   if [ "$userok" = "false" ] ; then
      echo "User name ($USER) does not exist,  must be one of: $USERLIST"
      exit 1
   fi

   dbgecho "using USER: $USER"
}

# ===== main

# running as root?
if [[ $EUID != 0 ]] ; then
    echo "Must run as root"
    exit 0
fi

# check if required packages are installed
# Could not get systemd to load uronode properly
# install inetd for the time being

dbgecho "Check required packages: $PKG_REQUIRE"
needs_pkg=false

for pkg_name in `echo ${PKG_REQUIRE}` ; do

   is_pkg_installed $pkg_name
   if [ $? -ne 0 ] ; then
      echo "$myname: Will Install $pkg_name package"
      needs_pkg=true
      break
   fi
done

if [ "$needs_pkg" = "true" ] ; then
   echo

   apt-get install -y -q $PKG_REQUIRE
   if [ "$?" -ne 0 ] ; then
      echo "$myname: package install failed. Please try this command manually:"
      echo "apt-get -y $PKG_REQUIRE"
      exit 1
   fi
fi

# Get list of users with home directories
USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

get_user
check_user

# prompt for a callsign
while get_callsign ; do
    echo "Input error, try again"
done

# check if /var/ax25 exists as a directory or symbolic link
if [ ! -d "/var/ax25" ] || [ ! -L "/var/ax25" ] ; then
   if [ ! -d "/usr/local/var/ax25" ] ; then
      echo "ax25 directory /usr/local/var/ax25 DOES NOT exist, ax25 install failed"
      exit 1
   else
      echo "Making symbolic link to /var/ax25"
      ln -s /usr/local/var/ax25 /var/ax25
   fi
else
   echo " Found ax.25 link or directory /var/ax25"
fi

# Entry in /etc/services
grep -i "uronode" /etc/services
if [ $? -eq 1 ] ; then
   echo "$myname: uronode service not installed"
{
echo "uronode         3694/tcp                        # ax.25 uronode"
} >> /etc/services
else
   echo "$myname: uronode service already installed"
fi

# Entry in /usr/local/etc/ax25/ax25d.conf

grep -i "uronode" $AX25_CFGDIR/ax25d.conf
if [ $? -eq 1 ] ; then
   echo "$myname: uronode ax25d entry not installed"

cat << EOT >> $AX25_CFGDIR/ax25d.conf
[$CALLSIGN-$SSID VIA $AX25PORT]
NOCALL   * * * * * *  L
default  * * * * * *  - root /usr/local/sbin/uronode uronode
#
<netrom>
NOCALL   * * * * * *  L
default  * * * * * *  - root /usr/local/sbin/uronode uronode
EOT
else
   echo "$myname: uronode ax25d entry already installed"
fi

prog_name=uronode
type -P $prog_name &>/dev/null
if [ $? -ne 0 ] ; then
# Currently manually check for latest version
   URONODE_VER="2.13"
#   cd /usr/local/src/uronode-$URONODE_VER.tar.gz
#   tar -xzxf uro
#   wget http://downloads.sourceforge.net/project/uronodenode-$URONODE_VER.tar.gz

    wget http://ftp.debian.org/debian/pool/main/u/uronode/uronode_$URONODE_VER.orig.tar.gz
    tar -zxvf uronode_$URONODE_VER.orig.tar.gz
    cd uronode-$URONODE_VER

   ./configure
# Use interactive mode? [Y/n]: n
   make
   make install
   make installhelp
   make installconf

   FILESIZE=$(stat -c %s make.debug)
   if [ $FILESIZE -eq 0 ] ; then
       echo
       echo "NO errors detected during make"
       echo
   else
       echo
       echo "ERORS found during make"
       cat make.debug
fi

# edit /etc/ax25/uronode.info
cat << EOT > $AX25_CFGDIR/uronode.info
This is a raspberry pi running URONode.
Setup with a debug kernel for catching panics.
EOT
# edit /etc/ax25/uronode.motd

cat << EOT > $AX25_CFGDIR/uronode.motd
This is $CALLSIGN's URONode  located on $CITY
$STATE [$GRIDSQUARE] (grid)
Type "?" for commands or H <command> for more detailed help on a command.
EOT

# For shell access for Sysop users
# callsign:password:local linux username:shell
# edit /etc/ax25/uronode.users

# Convert callsign to lower case
CALLSIGN=$(echo "$CALLSIGN" | tr '[A-Z]' '[a-z]')

# Chech for duplicate
cat << EOT >> $AX25_CFGDIR/uronode.users
$CALLSIGN:$CALLSIGN:$USER:shell
EOT

# Check for duplicate
cat << EOT >> /etc/inetd.conf
#:HAM-RADIO: amateur-radio services
ax25-node stream tcp nowait root /usr/sbin/ax25-node
uronode  stream  tcp     nowait  root    /usr/local/sbin/uronode  uronode
EOT

URONODE_CFGFILE="$AX25_CFGDIR/uronode.conf"
# Edit uronode.conf file
HOSTNAME="localhost"
EMAIL_ADDR="basil@pacabunga.com"
LOCALNET="10\.0\.42\.0\/24"
node_id="UR1LPZ"
SSID=7
NODEID="$node_id:$CALLSIGN-$SSID"
NR_PORT="netrom"

dbgecho "Set hostname $HOSTNAME in file: $URONODE_CFGFILE"
sed -i -e "/HostName/s/.*/HostName\t$HOSTNAME/" $URONODE_CFGFILE

dbgecho "Set Email $EMAIL_ADDR in file: $URONODE_CFGFILE"
sed -i -e "/Email/s/.*/Email\t$EMAIL_ADDR/" $URONODE_CFGFILE

dbgecho "Set LocalNet $LOCALNET in file: $URONODE_CFGFILE"
sed -i -e "/LocalNet/s/.*/LocalNet\t$LOCALNET/" $URONODE_CFGFILE

dbgecho "Set NodeId $NODEID in file: $URONODE_CFGFILE"
sed -i -e "/NodeId/s/.*/NodeId\t$NODEID/" $URONODE_CFGFILE

dbgecho "Set NrPort $NR_PORT in file: $URONODE_CFGFILE"
sed -i -e "/NrPort/s/.*/NrPort\t$NR_PORT/" $URONODE_CFGFILE

echo
echo "$myname: uronode install & config FINISHED"
echo
