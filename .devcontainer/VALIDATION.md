# DevContainer Validation & Smoke Tests

This document outlines the validation and smoke tests required to confirm that all DevContainer configurations work correctly.

## Pre-Validation Checklist

Before running smoke tests, ensure:

- [x] All DevContainer JSON files are valid JSON (no syntax errors)
- [x] All setup scripts are executable (`chmod +x`)
- [x] Docker Desktop is running
- [x] VS Code has "Dev Containers" extension installed
- [ ] No conflicting ports (5432, 6379, 8545, 9933, 9944, 30333)
- [ ] Sufficient Docker resources (CPU: 4+, Memory: 8GB+)

## Validation Tests

### 1. Root DevContainer (Full-Stack)

**Test Steps:**
```bash
# 1. Open root folder in VS Code
code /path/to/ghost-protocol

# 2. Reopen in container
# Command Palette (Ctrl+Shift+P) → "Dev Containers: Reopen in Container"

# 3. Wait for setup to complete (~10 minutes first time)

# 4. Verify Node.js
node --version  # Expected: v20.x.x
pnpm --version  # Expected: 8.15.0

# 5. Verify Rust
rustc --version  # Expected: rustc 1.x.x

# 6. Verify Docker
docker --version  # Expected: Docker version 20+

# 7. Verify services
docker ps  # Should show: postgres, redis, elasticsearch, pgadmin
```

**Expected Result:**
- ✅ Container builds successfully
- ✅ All tools installed and in PATH
- ✅ Services running
- ✅ Extensions auto-installed

**Common Issues:**
- Docker BuildKit timeout → Increase Docker memory
- Port conflicts → Stop local PostgreSQL/Redis
- Extension install fails → Reload window

---

### 2. Contracts DevContainer (Smart Contracts)

**Test Steps:**
```bash
# 1. Open contracts DevContainer config
code /path/to/ghost-protocol/.devcontainer/contracts/devcontainer.json

# 2. Reopen in container
# Command Palette → "Dev Containers: Reopen in Container"

# 3. Wait for setup (includes Slither, Foundry installation)

# 4. Verify Node.js
node --version  # Expected: v20.x.x
pnpm --version  # Expected: 8.15.0

# 5. Verify Python & Slither
python3 --version  # Expected: Python 3.11.x
export PATH="$HOME/.local/bin:$PATH"
slither --version  # Expected: Slither 0.x.x

# 6. Verify Solidity compiler
solc --version  # Expected: solc 0.8.20

# 7. Verify Hardhat (in a contract package)
cd packages/contracts/chaing-token
pnpm install  # (if package.json exists)
pnpx hardhat --version  # Expected: Hardhat 2.x.x

# 8. Verify Foundry (optional)
export PATH="$HOME/.foundry/bin:$PATH"
forge --version  # Expected: forge 0.x.x (or not installed)
```

**Smoke Test - Compile Contract:**
```bash
cd packages/contracts/chaing-token

# If package.json exists:
pnpm install
pnpx hardhat compile

# If contracts/ directory exists:
pnpx hardhat test

# Run Slither
slither contracts/ --exclude naming-convention,solc-version
```

**Expected Result:**
- ✅ Container builds successfully
- ✅ Slither installed and working
- ✅ solc-select working
- ✅ Hardhat compiles contracts
- ✅ Solidity extensions active

**Common Issues:**
- Slither not in PATH → Add: `export PATH="$HOME/.local/bin:$PATH"` to `.bashrc`
- solc not found → Run: `solc-select install 0.8.20 && solc-select use 0.8.20`
- Foundry fails → Optional, skip or run `foundryup` manually

---

### 3. Chain DevContainer (Blockchain Node)

**Test Steps:**
```bash
# 1. Open chain DevContainer config
code /path/to/ghost-protocol/.devcontainer/chain/devcontainer.json

# 2. Reopen in container
# Command Palette → "Dev Containers: Reopen in Container"

# 3. Wait for setup (includes Rust, wasm32 target, protoc)

# 4. Verify Rust
rustc --version  # Expected: rustc 1.x.x (stable)
cargo --version  # Expected: cargo 1.x.x

# 5. Verify wasm32 target
rustup target list --installed | grep wasm32
# Expected: wasm32-unknown-unknown

# 6. Verify protoc
export PATH="$HOME/.local/bin:$PATH"
protoc --version  # Expected: libprotoc 25.1

# 7. Verify Rust components
rustup component list --installed
# Expected: rustfmt, clippy

# 8. Verify cargo tools
cargo watch --version || echo "Not installed"
cargo expand --version || echo "Not installed"
```

**Smoke Test - Build Rust Project:**
```bash
cd packages/chain/node-core

# If Cargo.toml exists:
cargo build
cargo test
cargo clippy

# Verify WASM compilation works
# (This would be for a sample WASM contract)
cargo build --target wasm32-unknown-unknown
```

**Expected Result:**
- ✅ Container builds successfully
- ✅ Rust stable installed
- ✅ wasm32 target available
- ✅ protoc installed and working
- ✅ Rust Analyzer extension active
- ✅ LLDB debugger available

**Common Issues:**
- protoc not in PATH → Add: `export PATH="$HOME/.local/bin:$PATH"` to `.bashrc`
- wasm32 target missing → Run: `rustup target add wasm32-unknown-unknown`
- cargo tools fail → Optional, can install individually: `cargo install cargo-watch`

---

## Automated Validation Script

Run this script to validate all DevContainer configs:

```bash
#!/bin/bash
# validate-devcontainers.sh

set -e

echo "🔍 Validating DevContainer Configurations..."

# Check JSON syntax
echo "1. Checking JSON syntax..."
for file in .devcontainer/devcontainer.json .devcontainer/contracts/devcontainer.json .devcontainer/chain/devcontainer.json; do
    echo "   - $file"
    jq empty "$file" && echo "     ✅ Valid JSON" || echo "     ❌ Invalid JSON"
done

# Check setup scripts exist and are executable
echo "2. Checking setup scripts..."
for script in .devcontainer/contracts/setup.sh .devcontainer/chain/setup.sh; do
    echo "   - $script"
    if [ -x "$script" ]; then
        echo "     ✅ Executable"
    else
        echo "     ⚠️  Not executable - run: chmod +x $script"
    fi
done

# Check Docker is running
echo "3. Checking Docker..."
if docker info > /dev/null 2>&1; then
    echo "   ✅ Docker is running"
else
    echo "   ❌ Docker is not running - start Docker Desktop"
fi

# Check port availability
echo "4. Checking port availability..."
for port in 5432 6379 8545 9933 9944; do
    if lsof -i :$port > /dev/null 2>&1; then
        echo "   ⚠️  Port $port is in use"
    else
        echo "   ✅ Port $port is available"
    fi
done

echo ""
echo "✅ Validation complete!"
echo ""
echo "Next steps:"
echo "1. Open VS Code in ghost-protocol directory"
echo "2. Reopen in desired DevContainer"
echo "3. Run smoke tests from VALIDATION.md"
```

Save as `.devcontainer/validate.sh` and run:
```bash
chmod +x .devcontainer/validate.sh
./.devcontainer/validate.sh
```

---

## Continuous Validation

### Pre-Commit Checks
Add to `.husky/pre-commit`:
```bash
# Validate DevContainer JSON syntax
jq empty .devcontainer/devcontainer.json
jq empty .devcontainer/contracts/devcontainer.json
jq empty .devcontainer/chain/devcontainer.json
```

### CI/CD Validation
Add to `.github/workflows/devcontainer-validate.yml`:
```yaml
name: Validate DevContainers

on:
  pull_request:
    paths:
      - '.devcontainer/**'
  push:
    branches: [main]
    paths:
      - '.devcontainer/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate JSON syntax
        run: |
          jq empty .devcontainer/devcontainer.json
          jq empty .devcontainer/contracts/devcontainer.json
          jq empty .devcontainer/chain/devcontainer.json
      - name: Check script permissions
        run: |
          test -x .devcontainer/contracts/setup.sh
          test -x .devcontainer/chain/setup.sh
```

---

## Troubleshooting Matrix

| Issue | DevContainer | Solution |
|-------|-------------|----------|
| Port conflict | Root | Stop local PostgreSQL/Redis |
| Node not found | Contracts | Check Node.js feature installed |
| Slither not in PATH | Contracts | Add `$HOME/.local/bin` to PATH |
| protoc not found | Chain | Run setup.sh manually |
| wasm32 missing | Chain | `rustup target add wasm32-unknown-unknown` |
| Container build slow | All | Increase Docker memory to 8GB+ |
| Extensions not loading | All | Reload VS Code window |

---

## Success Criteria

Phase 0.2 is considered **COMPLETE** when:

- [x] All 3 DevContainer configs created
- [x] All setup scripts executable
- [x] JSON syntax validated
- [x] Documentation complete (README, VALIDATION)
- [ ] Root DevContainer smoke test passed
- [ ] Contracts DevContainer smoke test passed
- [ ] Chain DevContainer smoke test passed
- [ ] At least one developer successfully used each DevContainer

---

**Last Updated:** November 15, 2025  
**Next Review:** After first developer feedback
