#! /bin/bash
#
# Compare some directories on vogon to hactar
IPDEST="10.0.42.99"
rsync -rvnc --delete -e ssh sysd/* gunn@$IPDEST:dev/systemd/sysd
rsync -rvnc --delete -e ssh /etc/systemd/system/ax25* gunn@$IPDEST:/etc/systemd/system/
rsync -rvnc --delete -e ssh /etc/systemd/system/dire* gunn@$IPDEST:/etc/systemd/system/
rsync -rvnc --delete -e ssh systemd/* gunn@$IPDEST:dev/systemd
rsync -rvnc --delete -e ssh /etc/ax25/ax25-*d gunn@$IPDEST:/etc/ax25/
rsync -rvnc --delete -e ssh /etc/ax25/ax25dev-parm* gunn@$IPDEST:/etc/ax25/
