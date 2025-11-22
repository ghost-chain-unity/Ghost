#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_CORE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "================================================"
echo "Running cargo fmt check for Ghost Chain Node Core"
echo "================================================"
echo ""

cd "$NODE_CORE_DIR"

echo "Working directory: $(pwd)"
echo ""

cargo fmt --all --check 2>&1 | tee /tmp/cargo-fmt.log

echo ""
echo "✅ Cargo fmt check completed successfully!"
echo "Log saved to: /tmp/cargo-fmt.log"
