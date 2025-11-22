#!/bin/bash

BASE_PATH="${BASE_PATH:-/tmp/ghost-chain}"

echo "Cleaning up Ghost Chain testnet data..."
echo "Removing: $BASE_PATH"

rm -rf "$BASE_PATH/alice"
rm -rf "$BASE_PATH/bob"
rm -rf "$BASE_PATH/charlie"

echo "Cleanup complete!"
echo ""
echo "Note: This removes all blockchain data for the local testnet."
echo "Chain specs in chain-specs/ directory are preserved."
