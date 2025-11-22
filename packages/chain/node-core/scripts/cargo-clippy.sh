#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_CORE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "================================================"
echo "Running cargo clippy for Ghost Chain Node Core"
echo "================================================"
echo ""

cd "$NODE_CORE_DIR"

echo "Working directory: $(pwd)"
echo ""

cargo clippy --all-features --all-targets -- -D warnings 2>&1 | tee /tmp/cargo-clippy.log

echo ""
echo "✅ Cargo clippy completed successfully!"
echo "Log saved to: /tmp/cargo-clippy.log"
