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

echo "Starting Alice (Validator 1)..."
echo "Base path: $BASE_PATH/alice"
echo "RPC port: 9944"
echo "P2P port: 30333"
echo ""

$BINARY \
  --base-path "$BASE_PATH/alice" \
  --chain "$CHAIN_SPEC" \
  --alice \
  --port 30333 \
  --rpc-port 9944 \
  --node-key 0000000000000000000000000000000000000000000000000000000000000001 \
  --validator \
  --rpc-methods Unsafe \
  --rpc-cors all \
  --name "Alice-Validator" \
  --telemetry-url "wss://telemetry.polkadot.io/submit/ 0"
