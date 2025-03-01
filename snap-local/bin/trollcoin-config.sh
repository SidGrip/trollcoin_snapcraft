#!/bin/bash
set -e

CONF='trollcoin.conf'
TROLLCOIN_DIR="$SNAP_USER_DATA/.trollcoin"
NODES_TMP='/tmp/peers.txt'
NODES_TXT='/tmp/nodes.txt'
RPC_PORT='17000'
P2P_PORT='15000'

function active_nodes() {
  # Get the list of active nodes
  curl -sSL https://chainz.cryptoid.info/troll/api.dws?q=nodes -o "$NODES_TMP"

  # Extract IP addresses, prepend 'addnode=', and write to /tmp/nodes.txt
  exec 3>&1 4>&2
  trap 'exec 2>&4 1>&3' 0 1 2 3
  exec 1>"$NODES_TXT" 2>&1

  grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' "$NODES_TMP" |
  while read -r node; do
    echo "addnode=$node"
  done
}

function troll_config() {
  mkdir -p "$TROLLCOIN_DIR"

  local PEERS
  PEERS=$(<"$NODES_TXT")

  # If config doesn't exist, create a new one with all fields
  if [ ! -f "$TROLLCOIN_DIR/$CONF" ]; then
    local RPCUSER
    local RPCPASSWORD
    RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
    RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)

    cat << EOF > "$TROLLCOIN_DIR/$CONF"
maxconnections=25
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcport=$RPC_PORT
port=$P2P_PORT
$PEERS
EOF
    echo "Created new $CONF at $TROLLCOIN_DIR"
  else
    # If config exists, only update (replace) the addnode= lines
    sed -i '/^addnode=/d' "$TROLLCOIN_DIR/$CONF"
    echo "$PEERS" >> "$TROLLCOIN_DIR/$CONF"
    echo "Updated existing $CONF with new peers."
  fi
}

active_nodes
troll_config