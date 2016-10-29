#!/bin/bash
SAVEDIR=/home/gunn/dev/udrc/systemd
rsync -av -e ssh /etc/systemd/system/ax25* gunn@10.0.42.16:$SAVEDIR/service/
rsync -av -e ssh /etc/systemd/system/direw* gunn@10.0.42.16:$SAVEDIR/service/

rsync -av -e ssh /home/gunn/tmp/ax25/* gunn@10.0.42.16:$SAVEDIR/debug

rsync -av -e ssh /etc/ax25/ax25-*d gunn@10.0.42.16:$SAVEDIR/ax25

exit 0
