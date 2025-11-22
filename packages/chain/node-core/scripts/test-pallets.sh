#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_CORE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=========================================================="
echo "Running tests for Ghost Protocol custom pallets"
echo "=========================================================="
echo ""

cd "$NODE_CORE_DIR"

echo "Working directory: $(pwd)"
echo ""

FAILED=0

echo "Test 1/3: Testing pallet-chainghost..."
if cargo test -p pallet-chainghost --all-features 2>&1 | tee /tmp/test-chainghost.log; then
    echo "✅ ChainGhost pallet tests passed"
else
    echo "❌ ChainGhost pallet tests failed"
    FAILED=1
fi
echo ""

echo "Test 2/3: Testing pallet-g3mail..."
if cargo test -p pallet-g3mail --all-features 2>&1 | tee /tmp/test-g3mail.log; then
    echo "✅ G3Mail pallet tests passed"
else
    echo "❌ G3Mail pallet tests failed"
    FAILED=1
fi
echo ""

echo "Test 3/3: Testing pallet-ghonity..."
if cargo test -p pallet-ghonity --all-features 2>&1 | tee /tmp/test-ghonity.log; then
    echo "✅ Ghonity pallet tests passed"
else
    echo "❌ Ghonity pallet tests failed"
    FAILED=1
fi
echo ""

echo "=========================================================="
if [ $FAILED -eq 0 ]; then
    echo "✅ All custom pallet tests passed successfully!"
    exit 0
else
    echo "❌ Some pallet tests failed. Review logs in /tmp/"
    exit 1
fi
