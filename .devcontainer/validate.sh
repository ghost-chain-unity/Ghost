#!/bin/bash
set -e

echo "🔍 Validating DevContainer Configurations..."
echo ""

# Check JSON syntax
echo "1. Checking JSON syntax..."
for file in .devcontainer/devcontainer.json .devcontainer/contracts/devcontainer.json .devcontainer/chain/devcontainer.json; do
    echo "   - $file"
    # Try jq first, fallback to python, fallback to node
    if command -v jq &> /dev/null; then
        jq empty "$file" && echo "     ✅ Valid JSON" || echo "     ❌ Invalid JSON"
    elif command -v python3 &> /dev/null; then
        python3 -m json.tool "$file" > /dev/null 2>&1 && echo "     ✅ Valid JSON" || echo "     ❌ Invalid JSON"
    elif command -v node &> /dev/null; then
        node -e "JSON.parse(require('fs').readFileSync('$file', 'utf8'))" && echo "     ✅ Valid JSON" || echo "     ❌ Invalid JSON"
    else
        echo "     ❌ No JSON validator available (install jq, python3, or node)"
        exit 1
    fi
done

echo ""

# Check setup scripts exist and are executable
echo "2. Checking setup scripts..."
for script in .devcontainer/contracts/setup.sh .devcontainer/chain/setup.sh; do
    echo "   - $script"
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo "     ✅ Executable"
        else
            echo "     ⚠️  Not executable - run: chmod +x $script"
        fi
    else
        echo "     ❌ File not found"
    fi
done

echo ""

# Check Docker is running
echo "3. Checking Docker..."
if command -v docker &> /dev/null; then
    if docker info > /dev/null 2>&1; then
        echo "   ✅ Docker is running"
    else
        echo "   ❌ Docker is not running - start Docker Desktop"
    fi
else
    echo "   ⚠️  Docker not installed"
fi

echo ""

# Check port availability (optional - might not have lsof)
echo "4. Checking port availability..."
if command -v lsof &> /dev/null; then
    for port in 5432 6379 8545 9933 9944; do
        if lsof -i :$port > /dev/null 2>&1; then
            echo "   ⚠️  Port $port is in use"
        else
            echo "   ✅ Port $port is available"
        fi
    done
else
    echo "   ⚠️  lsof not available - skipping port check"
fi

echo ""
echo "✅ Static validation complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Open VS Code in ghost-protocol directory"
echo "   2. Choose a DevContainer configuration:"
echo "      - Root: Full-stack development"
echo "      - Contracts: Smart contract development"
echo "      - Chain: Blockchain node development"
echo "   3. Reopen in Container (Ctrl+Shift+P → Dev Containers: Reopen in Container)"
echo "   4. Run smoke tests from .devcontainer/VALIDATION.md"
echo ""
