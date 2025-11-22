#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================="
echo "Ghost Chain - Local Testnet Launcher"
echo "========================================="
echo ""
echo "This will start 3 validator nodes:"
echo "  - Alice   (Port 30333, RPC 9944)"
echo "  - Bob     (Port 30334, RPC 9945)"
echo "  - Charlie (Port 30335, RPC 9946)"
echo ""
echo "Block time: 3 seconds"
echo "Consensus: Aura (block production) + GRANDPA (finality)"
echo ""
echo "To stop the network, press Ctrl+C"
echo "========================================="
echo ""

trap 'echo "Stopping all nodes..."; kill 0' SIGINT SIGTERM

"$SCRIPT_DIR/start-alice.sh" &
sleep 2

"$SCRIPT_DIR/start-bob.sh" &
sleep 2

"$SCRIPT_DIR/start-charlie.sh" &

wait
