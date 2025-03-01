#!/bin/bash
$SNAP/bin/trollcoin-config.sh || { echo "Failed to run trollcoin-config.sh"; exit 1; }
$SNAP/bin/TrollCoin 2>&1 | grep -v -e "Qt: Session management error" -e "QStandardPaths: XDG_RUNTIME_DIR not set"