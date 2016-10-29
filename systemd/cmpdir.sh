#! /bin/bash
#
# Compare some directories on vogon to hactar
 IPDEST="10.0.42.99"
#IPDEST="10.0.42.119"
echo "== debug scripts =="
rsync -rvnc --delete -e ssh bin/* gunn@$IPDEST:dev/systemd/bin/
#echo "== some dev directory stuff=="
#rsync -rvnc --delete -e ssh service/* gunn@$IPDEST:dev/systemd/service
echo "== systemd/system =="
rsync -rvnc --delete -e ssh sysd/ax25* gunn@$IPDEST:/etc/systemd/system/
echo "== systemd/system == #2"
rsync -rvnc --delete -e ssh sysd/dire* gunn@$IPDEST:/etc/systemd/system/
echo "== /etc/ax25 =="
rsync -rvnc --delete -e ssh ax25/ax25-*d gunn@$IPDEST:/etc/ax25/
echo "== /etc/ax25 #2=="
rsync -rvnc --delete -e ssh ax25/ax25dev-parm* gunn@$IPDEST:/etc/ax25/
