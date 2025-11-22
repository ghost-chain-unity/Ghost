#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_CORE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "================================================"
echo "Running cargo test for Ghost Chain Node Core"
echo "================================================"
echo ""

cd "$NODE_CORE_DIR"

echo "Working directory: $(pwd)"
echo ""

cargo test --all-features 2>&1 | tee /tmp/cargo-test.log

echo ""
echo "✅ Cargo test completed successfully!"
echo "Log saved to: /tmp/cargo-test.log"
