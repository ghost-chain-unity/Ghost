#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BINARY="$NODE_DIR/target/release/ghost-node"

if [ ! -f "$BINARY" ]; then
    echo "Error: Node binary not found at $BINARY"
    echo "Please build the node first with: cargo build --release"
    exit 1
fi

CHAIN_SPEC_DIR="$NODE_DIR/chain-specs"
mkdir -p "$CHAIN_SPEC_DIR"

echo "Generating local testnet chain spec..."
$BINARY build-spec --chain local > "$CHAIN_SPEC_DIR/local-testnet.json"

echo "Converting to raw chain spec..."
$BINARY build-spec --chain "$CHAIN_SPEC_DIR/local-testnet.json" --raw > "$CHAIN_SPEC_DIR/local-testnet-raw.json"

echo ""
echo "Chain specs generated:"
echo "  - $CHAIN_SPEC_DIR/local-testnet.json"
echo "  - $CHAIN_SPEC_DIR/local-testnet-raw.json"
echo ""
echo "This chain spec includes 3 validators: Alice, Bob, and Charlie"
