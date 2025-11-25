#!/bin/bash
# This script cleans the cargo cache and WASM build artifacts.

# Clean the cargo cache
cargo cache -c

# Remove WASM build artifacts
rm -rf target/wasm32-unknown-unknown/release/*.wasm

echo "Cargo cache and WASM build artifacts cleaned."