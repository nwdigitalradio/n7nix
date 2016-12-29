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
CALLSIGN="N7NIX"
CITY="LOPEZ Island"
STATE="WA"
GRIDSQUARE="CN88nl"

USER=

function dbgecho { if [ ! -z "$DEBUG" ] ; then echo "$*"; fi }

# ===== function is_pkg_installed

function is_pkg_installed() {

return $(dpkg-query -W -f='${Status}' $1 2>/dev/null | grep -c "ok installed")
}

# ===== function get_user
function get_user() {

# prompt for user name
# Check if there is only a single user on this system

USERLIST="$(ls /home)"
USERLIST="$(echo $USERLIST | tr '\n' ' ')"

if (( `ls /home | wc -l` == 1 )) ; then
   USER=$(ls /home)
else
  echo "Enter user name ($(echo $USERLIST | tr '\n' ' ')), followed by [enter]:"
  read -e USER
fi

# verify user name is legit
userok=false

for username in $USERLIST ; do
  if [ "$USER" = "$username" ] ; then
     userok=true;
  fi
done

if [ "$userok" = "false" ] ; then
   echo "$myname: User name does not exist,  must be one of: $USERLIST"
   exit 1
fi

dbgecho "$myname: using USER: $USER"
}

# ===== main

# check if required packages are installed
# Could not get systemd to load uronode properly
# install inetd for the time being

dbgecho "Check required packages: $PKG_REQUIRE"
needs_pkg=false

for pkg_name in `echo ${PKG_REQUIRE}` ; do

   is_pkg_installed $pkg_name
   if [ $? -eq 0 ] ; then
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

get_user

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
[N7NIX-7 VIA udr0]
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
   URONODE_VER="2.6"
   cd /usr/local/src
   wget http://downloads.sourceforge.net/project/uronode/uronode-$URONODE_VER.tar.gz
   tar -xzxf uronode-$URONODE_VER.tar.gz
   cd uronode-$URONODE_VER
   ./configure
   make
   make install
   make installhelp
   make installconf
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
