#!/bin/bash

set -e

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Check the status of a running ChainGhost node.

OPTIONS:
    -r, --rpc-url URL       RPC endpoint URL (default: http://localhost:9944)
    -n, --name NAME         Node name to check (searches for process)
    -p, --pid PID           Process ID to check
    -v, --verbose           Show detailed information
    -j, --json              Output in JSON format
    -h, --help              Show this help message

EXAMPLES:
    # Check status of local node
    $0

    # Check specific node by name
    $0 --name MyValidator

    # Check with verbose output
    $0 --verbose

    # Get status as JSON
    $0 --json

EOF
}

RPC_URL="http://localhost:9944"
NODE_NAME=""
PID=""
VERBOSE=false
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--rpc-url)
            RPC_URL="$2"
            shift 2
            ;;
        -n|--name)
            NODE_NAME="$2"
            shift 2
            ;;
        -p|--pid)
            PID="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -j|--json)
            JSON_OUTPUT=true
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

rpc_call() {
    local method=$1
    local params=${2:-[]}
    
    curl -s -H "Content-Type: application/json" \
        -d "{\"id\":1, \"jsonrpc\":\"2.0\", \"method\": \"$method\", \"params\":$params}" \
        "$RPC_URL"
}

find_process() {
    if [ -n "$PID" ]; then
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "$PID"
        else
            echo ""
        fi
    elif [ -n "$NODE_NAME" ]; then
        pgrep -f "ghost-node.*--name $NODE_NAME" | head -n 1
    else
        pgrep -f "ghost-node" | head -n 1
    fi
}

PROCESS_PID=$(find_process)

if [ -z "$PROCESS_PID" ]; then
    echo "Status: NOT RUNNING"
    exit 1
fi

HEALTH=$(rpc_call "system_health")
CHAIN=$(rpc_call "system_chain")
NODE_NAME_RPC=$(rpc_call "system_name")
VERSION=$(rpc_call "system_version")
PEERS=$(rpc_call "system_peers")
SYNC_STATE=$(rpc_call "system_syncState")

if [ "$JSON_OUTPUT" = true ]; then
    cat << EOF
{
  "status": "running",
  "pid": $PROCESS_PID,
  "health": $(echo $HEALTH | jq '.result'),
  "chain": $(echo $CHAIN | jq '.result'),
  "name": $(echo $NODE_NAME_RPC | jq '.result'),
  "version": $(echo $VERSION | jq '.result'),
  "peers": $(echo $PEERS | jq '.result | length'),
  "syncState": $(echo $SYNC_STATE | jq '.result')
}
EOF
else
    echo "==================================="
    echo "ChainGhost Node Status"
    echo "==================================="
    echo ""
    echo "Process Information:"
    echo "  Status: RUNNING"
    echo "  PID: $PROCESS_PID"
    echo ""
    
    echo "Node Information:"
    echo "  Chain: $(echo $CHAIN | jq -r '.result')"
    echo "  Name: $(echo $NODE_NAME_RPC | jq -r '.result')"
    echo "  Version: $(echo $VERSION | jq -r '.result')"
    echo ""
    
    echo "Health:"
    IS_SYNCING=$(echo $HEALTH | jq -r '.result.isSyncing')
    PEERS_COUNT=$(echo $HEALTH | jq -r '.result.peers')
    SHOULD_HAVE_PEERS=$(echo $HEALTH | jq -r '.result.shouldHavePeers')
    
    echo "  Syncing: $IS_SYNCING"
    echo "  Peers: $PEERS_COUNT"
    echo "  Should Have Peers: $SHOULD_HAVE_PEERS"
    echo ""
    
    if [ "$VERBOSE" = true ]; then
        echo "Sync State:"
        CURRENT_BLOCK=$(echo $SYNC_STATE | jq -r '.result.currentBlock')
        HIGHEST_BLOCK=$(echo $SYNC_STATE | jq -r '.result.highestBlock')
        STARTING_BLOCK=$(echo $SYNC_STATE | jq -r '.result.startingBlock')
        
        echo "  Current Block: $CURRENT_BLOCK"
        echo "  Highest Block: $HIGHEST_BLOCK"
        echo "  Starting Block: $STARTING_BLOCK"
        
        if [ "$CURRENT_BLOCK" != "null" ] && [ "$HIGHEST_BLOCK" != "null" ] && [ "$HIGHEST_BLOCK" -gt 0 ]; then
            PROGRESS=$(awk "BEGIN {printf \"%.2f\", ($CURRENT_BLOCK / $HIGHEST_BLOCK) * 100}")
            echo "  Progress: ${PROGRESS}%"
        fi
        echo ""
        
        echo "Connected Peers:"
        PEER_LIST=$(echo $PEERS | jq -r '.result[] | "  - \(.peerId) (\(.roles))"')
        if [ -z "$PEER_LIST" ]; then
            echo "  No peers connected"
        else
            echo "$PEER_LIST"
        fi
        echo ""
        
        echo "Process Details:"
        ps -p "$PROCESS_PID" -o pid,ppid,%cpu,%mem,vsz,rss,etime,cmd | tail -n +2
    fi
    
    echo "==================================="
fi

exit 0
