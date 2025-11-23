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

echo "Starting Charlie (Validator 3)..."
echo "Base path: $BASE_PATH/charlie"
echo "RPC port: 9946"
echo "P2P port: 30335"
echo ""

$BINARY \
  --base-path "$BASE_PATH/charlie" \
  --chain "$CHAIN_SPEC" \
  --charlie \
  --port 30335 \
  --rpc-port 9946 \
  --node-key 0000000000000000000000000000000000000000000000000000000000000003 \
  --validator \
  --rpc-methods Unsafe \
  --rpc-cors all \
  --name "Charlie-Validator"
