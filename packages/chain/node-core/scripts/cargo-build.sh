#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_CORE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "================================================"
echo "Running cargo build for Ghost Chain Node Core"
echo "================================================"
echo ""

cd "$NODE_CORE_DIR"

echo "Working directory: $(pwd)"
echo ""

# Use release mode for faster compilation in CI
if [ "${CI:-false}" = "true" ]; then
    echo "Building in release mode (CI environment)..."
    cargo build --release --locked --features wasm-random 2>&1 | tee /tmp/cargo-build.log
else
    echo "Building in debug mode..."
    cargo build --locked --features wasm-random 2>&1 | tee /tmp/cargo-build.log
fi

echo ""
echo "✅ Cargo build completed successfully!"
echo "Log saved to: /tmp/cargo-build.log"
