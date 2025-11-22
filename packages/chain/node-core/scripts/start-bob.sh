#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BINARY="$NODE_DIR/target/release/ghost-node"
CHAIN_SPEC="$NODE_DIR/chain-specs/local-testnet-raw.json"

if [ ! -f "$BINARY" ]; then
    echo "Error: Node binary not found at $BINARY"
    echo "Please build the node first with: cargo build --release"
    exit 1
fi

if [ ! -f "$CHAIN_SPEC" ]; then
    echo "Error: Chain spec not found. Running generate-chain-spec.sh..."
    "$SCRIPT_DIR/generate-chain-spec.sh"
fi

BASE_PATH="${BASE_PATH:-/tmp/ghost-chain}"
mkdir -p "$BASE_PATH"

echo "Starting Bob (Validator 2)..."
echo "Base path: $BASE_PATH/bob"
echo "RPC port: 9945"
echo "P2P port: 30334"
echo ""

$BINARY \
  --base-path "$BASE_PATH/bob" \
  --chain "$CHAIN_SPEC" \
  --bob \
  --port 30334 \
  --rpc-port 9945 \
  --node-key 0000000000000000000000000000000000000000000000000000000000000002 \
  --validator \
  --bootnodes /ip4/127.0.0.1/tcp/30333/p2p/12D3KooWEyoppNCUx8Yx66oV9fJnriXwCcXwDDUA2kj6vnc6iDEp \
  --rpc-methods Unsafe \
  --rpc-cors all \
  --name "Bob-Validator"
