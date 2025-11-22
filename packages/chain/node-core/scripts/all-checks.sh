#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "========================================"
echo "Running all cargo checks in sequence"
echo "========================================"
echo ""

FAILED=0

echo "Step 1/4: Running cargo fmt check..."
if bash "$SCRIPT_DIR/cargo-fmt.sh"; then
    echo "✅ Formatting check passed"
else
    echo "❌ Formatting check failed"
    FAILED=1
fi
echo ""

echo "Step 2/4: Running cargo clippy..."
if bash "$SCRIPT_DIR/cargo-clippy.sh"; then
    echo "✅ Clippy check passed"
else
    echo "❌ Clippy check failed"
    FAILED=1
fi
echo ""

echo "Step 3/4: Running cargo check..."
if bash "$SCRIPT_DIR/cargo-check.sh"; then
    echo "✅ Cargo check passed"
else
    echo "❌ Cargo check failed"
    FAILED=1
fi
echo ""

echo "Step 4/4: Running cargo test..."
if bash "$SCRIPT_DIR/cargo-test.sh"; then
    echo "✅ Tests passed"
else
    echo "❌ Tests failed"
    FAILED=1
fi
echo ""

echo "========================================"
if [ $FAILED -eq 0 ]; then
    echo "✅ All checks passed successfully!"
    exit 0
else
    echo "❌ Some checks failed. Review logs in /tmp/"
    exit 1
fi
