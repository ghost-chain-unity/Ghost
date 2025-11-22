#!/bin/bash

set -e

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Quick inspection of ChainGhost blockchain status.

OPTIONS:
    -r, --rpc-url URL       RPC endpoint URL (default: http://localhost:9944)
    -b, --blocks NUM        Number of recent blocks to show (default: 5)
    -v, --verbose           Show detailed information
    -j, --json              Output in JSON format
    -h, --help              Show this help message

EXAMPLES:
    # Inspect local chain
    $0

    # Inspect remote chain
    $0 --rpc-url http://node.example.com:9944

    # Show last 10 blocks
    $0 --blocks 10

    # Verbose output
    $0 --verbose

    # JSON output
    $0 --json

EOF
}

RPC_URL="http://localhost:9944"
BLOCKS_TO_SHOW=5
VERBOSE=false
JSON_OUTPUT=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--rpc-url)
            RPC_URL="$2"
            shift 2
            ;;
        -b|--blocks)
            BLOCKS_TO_SHOW="$2"
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

CHAIN=$(rpc_call "system_chain")
CHAIN_NAME=$(echo $CHAIN | jq -r '.result')

HEALTH=$(rpc_call "system_health")
IS_SYNCING=$(echo $HEALTH | jq -r '.result.isSyncing')
PEERS=$(echo $HEALTH | jq -r '.result.peers')

SYNC_STATE=$(rpc_call "system_syncState")
CURRENT_BLOCK=$(echo $SYNC_STATE | jq -r '.result.currentBlock')
HIGHEST_BLOCK=$(echo $SYNC_STATE | jq -r '.result.highestBlock')

FINALIZED_HASH=$(rpc_call "chain_getFinalizedHead")
FINALIZED_HASH_VAL=$(echo $FINALIZED_HASH | jq -r '.result')

FINALIZED_HEADER=$(rpc_call "chain_getHeader" "[\"$FINALIZED_HASH_VAL\"]")
FINALIZED_BLOCK_NUM=$(echo $FINALIZED_HEADER | jq -r '.result.number' | xargs printf "%d\n")

BEST_HASH=$(rpc_call "chain_getBlockHash")
BEST_HASH_VAL=$(echo $BEST_HASH | jq -r '.result')

BEST_HEADER=$(rpc_call "chain_getHeader" "[\"$BEST_HASH_VAL\"]")
BEST_BLOCK_NUM=$(echo $BEST_HEADER | jq -r '.result.number' | xargs printf "%d\n")

if [ "$JSON_OUTPUT" = true ]; then
    PEERS_LIST=$(rpc_call "system_peers")
    
    cat << EOF
{
  "chain": "$CHAIN_NAME",
  "sync": {
    "isSyncing": $IS_SYNCING,
    "currentBlock": $CURRENT_BLOCK,
    "highestBlock": $HIGHEST_BLOCK
  },
  "blocks": {
    "best": {
      "number": $BEST_BLOCK_NUM,
      "hash": "$BEST_HASH_VAL"
    },
    "finalized": {
      "number": $FINALIZED_BLOCK_NUM,
      "hash": "$FINALIZED_HASH_VAL"
    }
  },
  "network": {
    "peers": $PEERS,
    "peerDetails": $(echo $PEERS_LIST | jq '.result')
  }
}
EOF
else
    echo "==================================="
    echo "ChainGhost Chain Inspection"
    echo "==================================="
    echo ""
    echo "Chain: $CHAIN_NAME"
    echo "RPC URL: $RPC_URL"
    echo ""
    
    echo "Sync Status:"
    echo "  Syncing: $IS_SYNCING"
    if [ "$CURRENT_BLOCK" != "null" ] && [ "$HIGHEST_BLOCK" != "null" ]; then
        echo "  Current Block: $CURRENT_BLOCK"
        echo "  Highest Block: $HIGHEST_BLOCK"
        if [ "$HIGHEST_BLOCK" -gt 0 ]; then
            PROGRESS=$(awk "BEGIN {printf \"%.2f\", ($CURRENT_BLOCK / $HIGHEST_BLOCK) * 100}")
            echo "  Progress: ${PROGRESS}%"
        fi
    fi
    echo ""
    
    echo "Block Information:"
    echo "  Best Block: #$BEST_BLOCK_NUM"
    echo "  Best Hash: $BEST_HASH_VAL"
    echo "  Finalized Block: #$FINALIZED_BLOCK_NUM"
    echo "  Finalized Hash: $FINALIZED_HASH_VAL"
    PENDING_BLOCKS=$((BEST_BLOCK_NUM - FINALIZED_BLOCK_NUM))
    echo "  Pending Finalization: $PENDING_BLOCKS blocks"
    echo ""
    
    echo "Network:"
    echo "  Connected Peers: $PEERS"
    
    if [ "$VERBOSE" = true ]; then
        echo ""
        echo "Recent Blocks (last $BLOCKS_TO_SHOW):"
        echo "-----------------------------------"
        
        for ((i=0; i<$BLOCKS_TO_SHOW; i++)); do
            BLOCK_NUM=$((BEST_BLOCK_NUM - i))
            if [ $BLOCK_NUM -lt 0 ]; then
                break
            fi
            
            BLOCK_HASH=$(rpc_call "chain_getBlockHash" "[$BLOCK_NUM]")
            HASH=$(echo $BLOCK_HASH | jq -r '.result')
            
            BLOCK=$(rpc_call "chain_getBlock" "[\"$HASH\"]")
            EXTRINSICS=$(echo $BLOCK | jq '.result.block.extrinsics | length')
            
            PARENT_HASH=$(echo $BLOCK | jq -r '.result.block.header.parentHash')
            
            echo "  Block #$BLOCK_NUM"
            echo "    Hash: $HASH"
            echo "    Parent: $PARENT_HASH"
            echo "    Extrinsics: $EXTRINSICS"
            
            if [ $BLOCK_NUM -eq $FINALIZED_BLOCK_NUM ]; then
                echo "    [FINALIZED]"
            fi
            echo ""
        done
        
        echo "Connected Peers:"
        echo "-----------------------------------"
        PEERS_LIST=$(rpc_call "system_peers")
        PEER_DETAILS=$(echo $PEERS_LIST | jq -r '.result[] | "  \(.peerId)\n    Role: \(.roles)\n    Best: #\(.bestNumber)\n    Best Hash: \(.bestHash)\n"')
        
        if [ -z "$PEER_DETAILS" ]; then
            echo "  No peers connected"
        else
            echo "$PEER_DETAILS"
        fi
    fi
    
    echo "==================================="
fi

exit 0
