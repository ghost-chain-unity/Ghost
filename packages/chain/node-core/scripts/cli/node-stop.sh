#!/bin/bash

set -e

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Gracefully stop a running ChainGhost node.

OPTIONS:
    -n, --name NAME         Node name to stop (searches for process)
    -p, --pid PID           Process ID to stop
    -f, --force             Force kill if graceful shutdown fails
    -t, --timeout SECONDS   Timeout for graceful shutdown (default: 30)
    -h, --help              Show this help message

EXAMPLES:
    # Stop node by name
    $0 --name MyValidator

    # Stop node by PID
    $0 --pid 12345

    # Force stop if needed
    $0 --name MyValidator --force

    # Stop with custom timeout
    $0 --name MyValidator --timeout 60

EOF
}

NODE_NAME=""
PID=""
FORCE=false
TIMEOUT=30

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            NODE_NAME="$2"
            shift 2
            ;;
        -p|--pid)
            PID="$2"
            shift 2
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -t|--timeout)
            TIMEOUT="$2"
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

find_process() {
    if [ -n "$PID" ]; then
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "$PID"
            return 0
        else
            echo "Error: Process $PID not found"
            return 1
        fi
    elif [ -n "$NODE_NAME" ]; then
        FOUND_PID=$(pgrep -f "ghost-node.*--name $NODE_NAME" | head -n 1)
        if [ -z "$FOUND_PID" ]; then
            echo "Error: No process found with name '$NODE_NAME'"
            return 1
        fi
        echo "$FOUND_PID"
        return 0
    else
        FOUND_PID=$(pgrep -f "ghost-node" | head -n 1)
        if [ -z "$FOUND_PID" ]; then
            echo "Error: No ghost-node process found"
            return 1
        fi
        echo "$FOUND_PID"
        return 0
    fi
}

PROCESS_PID=$(find_process)
if [ $? -ne 0 ]; then
    echo "$PROCESS_PID"
    exit 1
fi

echo "Found ghost-node process: PID $PROCESS_PID"
ps -p "$PROCESS_PID" -o pid,cmd

echo "Sending SIGTERM to process $PROCESS_PID..."
kill -TERM "$PROCESS_PID"

echo "Waiting for graceful shutdown (timeout: ${TIMEOUT}s)..."
ELAPSED=0
while ps -p "$PROCESS_PID" > /dev/null 2>&1; do
    if [ $ELAPSED -ge $TIMEOUT ]; then
        if [ "$FORCE" = true ]; then
            echo "Timeout reached. Force killing process..."
            kill -KILL "$PROCESS_PID"
            sleep 1
            if ps -p "$PROCESS_PID" > /dev/null 2>&1; then
                echo "Error: Failed to kill process $PROCESS_PID"
                exit 1
            else
                echo "Process forcefully terminated."
                exit 0
            fi
        else
            echo "Error: Graceful shutdown timeout. Use --force to kill."
            exit 1
        fi
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
    if [ $((ELAPSED % 5)) -eq 0 ]; then
        echo "Still waiting... (${ELAPSED}s elapsed)"
    fi
done

echo "Node stopped successfully."
exit 0
