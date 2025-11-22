#!/bin/bash

set -e

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Rotate session keys for a ChainGhost validator node.

OPTIONS:
    -r, --rpc-url URL       RPC endpoint URL (default: http://localhost:9944)
    -o, --output FILE       Output file for new keys (default: session-keys.txt)
    -v, --verbose           Show detailed information
    -h, --help              Show this help message

EXAMPLES:
    # Rotate keys on local node
    $0

    # Rotate keys on remote node
    $0 --rpc-url http://validator.example.com:9944

    # Save to custom file
    $0 --output my-session-keys.txt

EOF
}

RPC_URL="http://localhost:9944"
OUTPUT_FILE="session-keys.txt"
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--rpc-url)
            RPC_URL="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "Error: $1 is required but not installed"
        exit 1
    fi
}

check_command curl
check_command jq

echo "==================================="
echo "Rotating Session Keys"
echo "==================================="
echo ""
echo "RPC URL: $RPC_URL"
echo ""

if [ "$VERBOSE" = true ]; then
    echo "Checking node health..."
    HEALTH=$(curl -s -H "Content-Type: application/json" \
        -d '{"id":1, "jsonrpc":"2.0", "method": "system_health"}' \
        "$RPC_URL")
    
    if echo "$HEALTH" | jq -e '.error' > /dev/null 2>&1; then
        echo "Error: Failed to connect to node"
        echo "$HEALTH" | jq '.error'
        exit 1
    fi
    
    IS_SYNCING=$(echo "$HEALTH" | jq -r '.result.isSyncing')
    PEERS=$(echo "$HEALTH" | jq -r '.result.peers')
    
    echo "Node Status:"
    echo "  Syncing: $IS_SYNCING"
    echo "  Peers: $PEERS"
    echo ""
fi

echo "Rotating session keys..."
RESPONSE=$(curl -s -H "Content-Type: application/json" \
    -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys", "params":[]}' \
    "$RPC_URL")

if echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
    echo "Error: Failed to rotate keys"
    echo "$RESPONSE" | jq '.error'
    exit 1
fi

NEW_KEYS=$(echo "$RESPONSE" | jq -r '.result')

if [ -z "$NEW_KEYS" ] || [ "$NEW_KEYS" = "null" ]; then
    echo "Error: No keys returned from rotation"
    exit 1
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"

cat > "$OUTPUT_FILE" << EOF
ChainGhost Session Keys
Rotated: $(date)
RPC URL: $RPC_URL

===================================
Session Keys:
===================================

$NEW_KEYS

===================================
Next Steps:
===================================

1. Copy the session keys above

2. Set session keys on-chain using Polkadot.js UI:
   a. Navigate to Developer > Extrinsics
   b. Select your validator account
   c. Choose session > setKeys
   d. Paste the session keys: $NEW_KEYS
   e. Set proof to 0x00
   f. Submit the transaction

3. Alternative - Use session.setKeys extrinsic directly:
   curl -H "Content-Type: application/json" \\
     -d '{"id":1, "jsonrpc":"2.0", "method": "author_submitExtrinsic", "params":["0x..."]}' \\
     $RPC_URL

4. Verify keys are set:
   curl -H "Content-Type: application/json" \\
     -d '{"id":1, "jsonrpc":"2.0", "method": "author_hasSessionKeys", "params":["$NEW_KEYS"]}' \\
     $RPC_URL

5. Wait for the next session/era for keys to take effect

===================================
IMPORTANT NOTES:
===================================

1. The new keys are now in your node's keystore
2. You must set these keys on-chain for them to take effect
3. Old keys will remain valid until the next session
4. Backup your node's keystore directory
5. Keep this file secure

Output file: $OUTPUT_FILE

===================================
EOF

echo ""
echo "==================================="
echo "Session Keys Rotated Successfully!"
echo "==================================="
echo ""
echo "New Session Keys:"
echo "$NEW_KEYS"
echo ""
echo "Keys saved to: $OUTPUT_FILE"
echo ""
echo "⚠️  IMPORTANT: You must set these keys on-chain using the Polkadot.js UI"
echo "               or the session.setKeys extrinsic."
echo ""
echo "For instructions, run:"
echo "  cat $OUTPUT_FILE"
echo ""
