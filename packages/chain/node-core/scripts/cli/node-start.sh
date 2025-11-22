#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Start a ChainGhost node with configurable options.

OPTIONS:
    -c, --config FILE       Configuration file (validator.toml, full-node.toml, or archive-node.toml)
    -m, --mode MODE         Node mode: dev, validator, full, archive (default: full)
    -n, --name NAME         Node name (default: ChainGhostNode)
    -p, --base-path PATH    Base path for node data (default: /tmp/ghost-chain)
    -s, --chain SPEC        Chain specification (default: local)
    --binary PATH           Path to ghost-node binary
    --rpc-port PORT         RPC port (default: 9944)
    --p2p-port PORT         P2P port (default: 30333)
    --bootnodes NODES       Comma-separated bootnode addresses
    --pruning MODE          Pruning mode (archive or number of blocks)
    --validator             Enable validator mode
    --rpc-external          Expose RPC externally
    --unsafe-rpc            Enable unsafe RPC methods (development only)
    -h, --help              Show this help message

EXAMPLES:
    # Start development node
    $0 --mode dev

    # Start validator node
    $0 --mode validator --name MyValidator

    # Start full node with custom path
    $0 --mode full --base-path /var/lib/ghost-node --name MyFullNode

    # Start archive node
    $0 --mode archive --pruning archive

EOF
}

MODE="full"
NODE_NAME="ChainGhostNode"
BASE_PATH="/tmp/ghost-chain"
CHAIN_SPEC="local"
BINARY="${NODE_DIR}/target/release/ghost-node"
RPC_PORT="9944"
P2P_PORT="30333"
BOOTNODES=""
PRUNING=""
VALIDATOR_FLAG=""
RPC_EXTERNAL_FLAG=""
UNSAFE_RPC_FLAG=""
CONFIG_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        -n|--name)
            NODE_NAME="$2"
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
        --rpc-port)
            RPC_PORT="$2"
            shift 2
            ;;
        --p2p-port)
            P2P_PORT="$2"
            shift 2
            ;;
        --bootnodes)
            BOOTNODES="$2"
            shift 2
            ;;
        --pruning)
            PRUNING="$2"
            shift 2
            ;;
        --validator)
            VALIDATOR_FLAG="--validator"
            shift
            ;;
        --rpc-external)
            RPC_EXTERNAL_FLAG="--rpc-external"
            shift
            ;;
        --unsafe-rpc)
            UNSAFE_RPC_FLAG="--rpc-methods Unsafe"
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

if [ ! -f "$BINARY" ]; then
    echo "Error: Node binary not found at $BINARY"
    echo "Please build the node first with: cargo build --release"
    exit 1
fi

mkdir -p "$BASE_PATH"

case $MODE in
    dev)
        echo "Starting development node..."
        $BINARY --dev \
            --base-path "$BASE_PATH" \
            --name "$NODE_NAME" \
            --rpc-port "$RPC_PORT" \
            --port "$P2P_PORT" \
            $RPC_EXTERNAL_FLAG \
            $UNSAFE_RPC_FLAG
        ;;
    validator)
        echo "Starting validator node..."
        echo "Base path: $BASE_PATH"
        echo "Chain: $CHAIN_SPEC"
        echo "RPC port: $RPC_PORT"
        echo "P2P port: $P2P_PORT"
        echo ""
        
        EXTRA_ARGS=""
        [ -n "$BOOTNODES" ] && EXTRA_ARGS="$EXTRA_ARGS --bootnodes $BOOTNODES"
        [ -n "$PRUNING" ] && EXTRA_ARGS="$EXTRA_ARGS --pruning $PRUNING"
        
        $BINARY \
            --base-path "$BASE_PATH" \
            --chain "$CHAIN_SPEC" \
            --validator \
            --name "$NODE_NAME" \
            --rpc-port "$RPC_PORT" \
            --port "$P2P_PORT" \
            --telemetry-url "wss://telemetry.polkadot.io/submit/ 0" \
            --prometheus-external \
            --prometheus-port 9615 \
            $RPC_EXTERNAL_FLAG \
            $EXTRA_ARGS
        ;;
    full)
        echo "Starting full node..."
        echo "Base path: $BASE_PATH"
        echo "Chain: $CHAIN_SPEC"
        echo "RPC port: $RPC_PORT"
        echo "P2P port: $P2P_PORT"
        echo ""
        
        EXTRA_ARGS=""
        [ -n "$BOOTNODES" ] && EXTRA_ARGS="$EXTRA_ARGS --bootnodes $BOOTNODES"
        [ -n "$PRUNING" ] && EXTRA_ARGS="$EXTRA_ARGS --pruning $PRUNING"
        
        $BINARY \
            --base-path "$BASE_PATH" \
            --chain "$CHAIN_SPEC" \
            --name "$NODE_NAME" \
            --rpc-port "$RPC_PORT" \
            --port "$P2P_PORT" \
            $RPC_EXTERNAL_FLAG \
            $UNSAFE_RPC_FLAG \
            $EXTRA_ARGS
        ;;
    archive)
        echo "Starting archive node..."
        echo "Base path: $BASE_PATH"
        echo "Chain: $CHAIN_SPEC"
        echo "RPC port: $RPC_PORT"
        echo "P2P port: $P2P_PORT"
        echo "Pruning: archive"
        echo ""
        
        EXTRA_ARGS=""
        [ -n "$BOOTNODES" ] && EXTRA_ARGS="$EXTRA_ARGS --bootnodes $BOOTNODES"
        
        $BINARY \
            --base-path "$BASE_PATH" \
            --chain "$CHAIN_SPEC" \
            --name "$NODE_NAME" \
            --pruning archive \
            --rpc-port "$RPC_PORT" \
            --port "$P2P_PORT" \
            $RPC_EXTERNAL_FLAG \
            $EXTRA_ARGS
        ;;
    *)
        echo "Error: Invalid mode '$MODE'"
        echo "Valid modes: dev, validator, full, archive"
        exit 1
        ;;
esac
