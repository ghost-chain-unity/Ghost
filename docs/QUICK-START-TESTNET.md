# Quick Start: Ghost Chain Testnet Binary

**Last Updated:** November 17, 2025  
**Purpose:** Fast track guide to get Ghost Chain node binary for testing

---

## ⚡ TL;DR (30 Seconds)

```bash
# 1. Trigger GitHub Actions build
gh workflow run blockchain-node-ci.yml

# 2. Wait for completion (15-30 minutes) - optional, can check status
gh run list --workflow=blockchain-node-ci.yml --limit 5

# 3. Download binary when ready
./scripts/download-chain-binary.sh

# 4. Test it
./bin/ghost-node --dev --tmp
```

---

## 🎯 Why This Approach?

**Problem:** Replit environment cannot compile Substrate blockchain (requires full Rust/WASM toolchain + heavy compilation)

**Solution:** Use GitHub Actions as build server → Download pre-built binary → Test in Replit

**Benefits:**
- ✅ No local compilation needed
- ✅ Consistent build environment
- ✅ Multi-platform binaries (Linux AMD64/ARM64, macOS)
- ✅ Automatic checksums for security
- ✅ Docker images for production

---

## 📋 Prerequisites

Install GitHub CLI (one-time setup):

```bash
# Check if installed
gh --version

# If not installed, install it
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
&& echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
&& sudo apt update \
&& sudo apt install gh -y

# Authenticate (first time only)
gh auth login
```

---

## 🚀 Step-by-Step Guide

### Step 1: Trigger Build (2 minutes)

```bash
# Option A: Using GitHub CLI (recommended)
gh workflow run blockchain-node-ci.yml

# Option B: Using GitHub Web UI
# 1. Go to: https://github.com/YOUR_ORG/ghost-protocol/actions
# 2. Click "Blockchain Node CI" workflow
# 3. Click "Run workflow" button → Select branch → "Run workflow"

# Check status
gh run list --workflow=blockchain-node-ci.yml --limit 5
```

**Expected Output:**
```
✓ Blockchain Node CI  main  push  <run-id>  Completed  15m ago
```

---

### Step 2: Download Binary (1 minute)

After workflow completes (15-30 minutes):

```bash
# Automated download (recommended)
./scripts/download-chain-binary.sh

# Or download specific run
./scripts/download-chain-binary.sh <run-id>

# Or download with checksum verification
./scripts/download-chain-binary.sh --verify
```

**Expected Output:**
```
✅ Download complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Binary Location: bin/ghost-node-linux-amd64
   Symlink:         bin/ghost-node
   Run ID:          123456789
   Branch:          develop
   Commit:          abc1234
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

### Step 3: Test Binary (30 seconds)

```bash
# Check version
./bin/ghost-node --version

# Run development node (single validator, temporary database)
./bin/ghost-node --dev --tmp
```

**Expected Output:**
```
2025-11-17 10:00:00 Ghost Chain Node
2025-11-17 10:00:00 ✨ version 0.1.0-abc1234
2025-11-17 10:00:00 ❤️  by Ghost Protocol Team
2025-11-17 10:00:00 📋 Chain specification: Development
2025-11-17 10:00:00 🏷  Node name: warm-tree-1234
2025-11-17 10:00:00 👤 Role: AUTHORITY
2025-11-17 10:00:00 💾 Database: RocksDb at /tmp/...
2025-11-17 10:00:00 🔨 Initializing Genesis block/state
2025-11-17 10:00:00 👶 Creating empty GRANDPA voter set for genesis.
2025-11-17 10:00:00 🏷  Local node identity is: 12D3KooW...
2025-11-17 10:00:00 💤 Idle (0 peers), best: #0 (0x...), finalized #0 (0x...), ⬇ 0 ⬆ 0
```

---

## 🌐 Access Node (After Starting)

Default ports (when running `--dev`):

| Service | Port | URL | Purpose |
|---------|------|-----|---------|
| HTTP RPC | 9944 | `http://localhost:9944` | JSON-RPC calls |
| WebSocket RPC | 9944 | `ws://localhost:9944` | Real-time subscriptions |
| P2P | 30333 | - | Peer-to-peer networking |

**Test RPC:**
```bash
# Check node health
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_health"}' \
  http://localhost:9944

# Get chain info
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_chain"}' \
  http://localhost:9944
```

---

## 🛠️ Common Commands

```bash
# Start with persistent database
./bin/ghost-node --dev --base-path ./testnet-data

# Start with custom ports
./bin/ghost-node --dev --tmp \
  --rpc-port 9955 \
  --port 30444

# Start with RPC exposed to network (for Replit webview)
./bin/ghost-node --dev --tmp \
  --rpc-external \
  --rpc-cors all

# Purge chain data (reset blockchain)
./bin/ghost-node purge-chain --dev

# Export chain spec
./bin/ghost-node build-spec --dev > chain-spec.json

# Show all options
./bin/ghost-node --help
```

---

## 🐛 Troubleshooting

### Issue: "Workflow still running"

**Solution:** Wait for completion or watch in real-time:
```bash
gh run watch
```

---

### Issue: "No artifacts found"

**Cause:** Workflow failed before artifact upload

**Solution:**
1. Check workflow logs: `gh run view <run-id> --log`
2. Re-trigger: `gh workflow run blockchain-node-ci.yml`

---

### Issue: "Permission denied" when running binary

**Solution:**
```bash
chmod +x bin/ghost-node
./bin/ghost-node --version
```

---

### Issue: "cannot execute binary file"

**Cause:** Wrong architecture (ARM64 instead of AMD64)

**Solution:** Ensure you downloaded `ghost-node-linux-amd64`
```bash
file bin/ghost-node
# Should show: ELF 64-bit LSB executable, x86-64
```

---

### Issue: Node fails to start

**Check logs for common issues:**

```bash
# Port already in use
Error: IO error: While lock file: /tmp/.../db/LOCK: Resource temporarily unavailable
→ Kill existing process: pkill ghost-node

# Database corruption
Error: Database error: Corruption
→ Purge database: ./bin/ghost-node purge-chain --dev
```

---

## 📊 Workflow Status Reference

| Status | Meaning | Action |
|--------|---------|--------|
| ⏳ `queued` | Waiting for runner | Wait |
| ▶️ `in_progress` | Currently building | Wait (~15-30 min) |
| ✅ `completed` + `success` | Build successful | Download artifact |
| ❌ `completed` + `failure` | Build failed | Check logs, fix code, re-trigger |
| 🚫 `cancelled` | Manually cancelled | Re-trigger if needed |

Check anytime:
```bash
gh run list --workflow=blockchain-node-ci.yml --limit 10
```

---

## 🎓 Next Steps

After getting node running:

1. **Connect Frontend:** Point ChainGhost frontend to `ws://localhost:9944`
2. **Deploy Contracts:** Use node for smart contract testing
3. **Multi-Node Testnet:** See [Testnet Setup Guide](./testnet-setup.md)
4. **Production Deploy:** Use Docker images from GHCR

---

## 📚 Full Documentation

For detailed information:
- [Complete Build Guide](./blockchain-node-build-guide.md) - All build methods and troubleshooting
- [ADR-006: Node Architecture](../docs/adr/ADR-20251116-006-chain-ghost-node-architecture.md) - Design decisions
- [Testnet Setup](./testnet-setup.md) - Multi-validator configuration
- [Runtime Development](./runtime-development.md) - Modifying blockchain runtime

---

## 🆘 Quick Help

```bash
# Full workflow: Trigger → Download → Test
gh workflow run blockchain-node-ci.yml && \
  sleep 1800 && \  # Wait 30 min (adjust based on build time)
  ./scripts/download-chain-binary.sh && \
  ./bin/ghost-node --dev --tmp

# Manual workflow
gh workflow run blockchain-node-ci.yml        # 1. Trigger
gh run list --workflow=blockchain-node-ci.yml # 2. Check status
./scripts/download-chain-binary.sh            # 3. Download when ready
./bin/ghost-node --dev --tmp                  # 4. Run
```

**Support Channels:**
- GitHub Issues: Technical bugs
- GitHub Discussions: Questions and ideas
- Workflow Logs: `gh run view <run-id> --log`

---

**Remember:**
- ⏱️ Build takes 15-30 minutes (be patient!)
- 🔄 Artifacts expire after 30 days (re-trigger if needed)
- 🔒 Always verify checksums for production use
- 📦 Download once, use multiple times
