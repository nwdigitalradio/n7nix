#!/bin/bash
#

BASE_DIR="$HOME/n7nix"
USER=$(whoami)

echo "Running as $USER from directory $(pwd)"

$BASE_DIR/bbs/bbs_verchk.sh
$BASE_DIR/xastir/xs_verchk.sh
$BASE_DIR/ax25/ax_verchk.sh
$BASE_DIR/ax25/ax25_ver.sh
$BASE_DIR/direwolf/dw_ver.sh
$BASE_DIR/gps/gp_verchk.sh
$BASE_DIR/config/wp_verchk.sh
$BASE_DIR/hfprogs/hf_verchk.sh
$BASE_DIR/email/pat/pat_verchk.sh
