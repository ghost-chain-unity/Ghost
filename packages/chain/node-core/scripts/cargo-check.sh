#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_CORE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "================================================"
echo "Running cargo check for Ghost Chain Node Core"
echo "================================================"
echo ""

cd "$NODE_CORE_DIR"

echo "Working directory: $(pwd)"
echo ""

cargo check --all-features --locked 2>&1 | tee /tmp/cargo-check.log

echo ""
echo "✅ Cargo check completed successfully!"
echo "Log saved to: /tmp/cargo-check.log"
