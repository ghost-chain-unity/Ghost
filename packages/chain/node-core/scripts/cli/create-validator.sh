#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Generate and setup validator keys for ChainGhost node.

OPTIONS:
    -n, --name NAME         Validator name (default: MyValidator)
    -p, --base-path PATH    Base path for node data (default: /tmp/ghost-validator)
    -s, --chain SPEC        Chain specification (default: local)
    --binary PATH           Path to ghost-node binary
    --output FILE           Output file for keys (default: validator-keys.txt)
    --scheme SCHEME         Key scheme: Sr25519, Ed25519, Ecdsa (default: Sr25519)
    -h, --help              Show this help message

EXAMPLES:
    # Generate keys for validator
    $0 --name MyValidator

    # Generate keys with custom path
    $0 --name MyValidator --base-path /var/lib/ghost-validator

    # Generate Ed25519 keys
    $0 --scheme Ed25519

EOF
}

VALIDATOR_NAME="MyValidator"
BASE_PATH="/tmp/ghost-validator"
CHAIN_SPEC="local"
BINARY="${NODE_DIR}/target/release/ghost-node"
OUTPUT_FILE="validator-keys.txt"
KEY_SCHEME="Sr25519"

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            VALIDATOR_NAME="$2"
            shift 2
            ;;
        -p|--base-path)
            BASE_PATH="$2"
            shift 2
            ;;
        -s|--chain)
            CHAIN_SPEC="$2"
            shift 2
            ;;
        --binary)
            BINARY="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --scheme)
            KEY_SCHEME="$2"
            shift 2
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

if [ ! -f "$BINARY" ]; then
    echo "Error: Node binary not found at $BINARY"
    echo "Please build the node first with: cargo build --release"
    exit 1
fi

mkdir -p "$BASE_PATH"
mkdir -p "$(dirname "$OUTPUT_FILE")"

echo "==================================="
echo "ChainGhost Validator Setup"
echo "==================================="
echo ""
echo "Validator Name: $VALIDATOR_NAME"
echo "Base Path: $BASE_PATH"
echo "Chain: $CHAIN_SPEC"
echo "Key Scheme: $KEY_SCHEME"
echo ""

cat > "$OUTPUT_FILE" << EOF
ChainGhost Validator Keys
Generated: $(date)
Validator Name: $VALIDATOR_NAME
Base Path: $BASE_PATH
Chain: $CHAIN_SPEC
Key Scheme: $KEY_SCHEME

===================================
EOF

generate_and_insert_key() {
    local key_type=$1
    local key_name=$2
    
    echo "Generating $key_name key..."
    
    KEY_OUTPUT=$($BINARY key generate --scheme $KEY_SCHEME 2>&1)
    
    SECRET_PHRASE=$(echo "$KEY_OUTPUT" | grep "Secret phrase" | sed 's/.*Secret phrase: *//')
    SECRET_SEED=$(echo "$KEY_OUTPUT" | grep "Secret seed" | sed 's/.*Secret seed: *//')
    PUBLIC_KEY=$(echo "$KEY_OUTPUT" | grep "Public key (hex)" | sed 's/.*Public key (hex): *//')
    ACCOUNT_ID=$(echo "$KEY_OUTPUT" | grep "Account ID" | sed 's/.*Account ID: *//')
    SS58_ADDRESS=$(echo "$KEY_OUTPUT" | grep "SS58 Address" | sed 's/.*SS58 Address: *//')
    
    cat >> "$OUTPUT_FILE" << EOF

$key_name Key ($key_type):
  Secret phrase: $SECRET_PHRASE
  Secret seed: $SECRET_SEED
  Public key: $PUBLIC_KEY
  Account ID: $ACCOUNT_ID
  SS58 Address: $SS58_ADDRESS
EOF
    
    echo "Inserting $key_name key into keystore..."
    $BINARY key insert \
        --base-path "$BASE_PATH" \
        --chain "$CHAIN_SPEC" \
        --scheme $KEY_SCHEME \
        --suri "$SECRET_PHRASE" \
        --key-type "$key_type" > /dev/null 2>&1
    
    echo "  ✓ $key_name key generated and inserted"
    echo ""
}

generate_and_insert_key "aura" "AURA (Block Production)"
generate_and_insert_key "gran" "GRANDPA (Finality)"

cat >> "$OUTPUT_FILE" << EOF

===================================
Next Steps:
===================================

1. Start your validator node:
   $BINARY \\
     --base-path $BASE_PATH \\
     --chain $CHAIN_SPEC \\
     --validator \\
     --name "$VALIDATOR_NAME" \\
     --rpc-port 9944 \\
     --port 30333

2. If you haven't already, rotate session keys:
   curl -H "Content-Type: application/json" \\
     -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys", "params":[]}' \\
     http://localhost:9944

3. Bond tokens and set session keys on-chain using Polkadot.js UI:
   - Navigate to Developer > Extrinsics
   - Select staking > bond
   - After bonding, select session > setKeys

4. Wait for the next era to start validating

===================================
IMPORTANT SECURITY NOTES:
===================================

1. BACKUP THIS FILE SECURELY - It contains your secret keys!
2. Never share your secret phrases or seeds with anyone
3. Store backups in multiple secure locations
4. Consider using hardware wallets for production validators
5. Rotate session keys regularly for security

This file: $OUTPUT_FILE

===================================
EOF

echo "==================================="
echo "Validator Setup Complete!"
echo "==================================="
echo ""
echo "Keys generated and inserted into keystore at: $BASE_PATH"
echo "Key details saved to: $OUTPUT_FILE"
echo ""
echo "⚠️  IMPORTANT: Backup $OUTPUT_FILE securely!"
echo ""
echo "Next, run the following to view next steps:"
echo "  cat $OUTPUT_FILE"
echo ""
