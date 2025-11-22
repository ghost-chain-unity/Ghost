# Ghost Chain Testnet - Replit Quick Guide

**Last Updated:** November 17, 2025  
**Purpose:** Complete guide to trigger builds and download blockchain node binary directly from Replit shell

---

## ⚡ Super Quick Start (2 Minutes)

```bash
# 1. Authenticate GitHub CLI (one-time setup)
gh auth login

# 2. Trigger build
gh workflow run blockchain-node-ci.yml

# 3. Download binary (auto-waits if still building)
./scripts/download-chain-binary.sh

# 4. Run testnet!
./bin/ghost-node --dev --tmp
```

---

## 📋 Prerequisites (One-Time Setup)

### Step 1: Verify GitHub CLI Installation

GitHub CLI sudah terinstall di `~/.local/bin/gh` (already in Replit PATH). Verifikasi:

```bash
gh --version
```

**Expected output:**
```
gh version 2.40.1 (2023-12-13)
```

**Note:** Di Replit, `~/.local/bin` otomatis ada di PATH, jadi Anda bisa langsung pakai `gh` tanpa full path.

---

### Step 2: Authenticate GitHub CLI

**PENTING:** Anda perlu authenticate sekali saja:

```bash
gh auth login
```

**Follow the prompts:**
1. **What account do you want to log into?** → `GitHub.com`
2. **What is your preferred protocol for Git operations?** → `HTTPS`
3. **Authenticate Git with your GitHub credentials?** → `Yes`
4. **How would you like to authenticate GitHub CLI?** → `Paste an authentication token`

**Cara dapatkan token:**
1. Buka: https://github.com/settings/tokens/new
2. Note: `Replit Ghost Protocol Access`
3. Expiration: `No expiration` (or your preference)
4. **Select scopes:**
   - ✅ `repo` (Full control of private repositories)
   - ✅ `workflow` (Update GitHub Action workflows)
   - ✅ `read:org` (Read org and team membership, read org projects)
5. Generate token → **Copy** → **Paste** di terminal Replit

**Verify authentication:**
```bash
gh auth status
```

Expected output:
```
✓ Logged in to github.com as YOUR_USERNAME (keyring)
```

---

## 🚀 Workflow: Build & Download Binary

### Method 1: Full Automation (Recommended)

**One-liner yang tunggu build selesai otomatis:**

```bash
gh workflow run blockchain-node-ci.yml && \
  echo "⏳ Build triggered! Monitoring status..." && \
  sleep 60 && \
  ./scripts/download-chain-binary.sh
```

Or use the automated script:

```bash
./scripts/trigger-and-download.sh
```

**What it does:**
1. Trigger GitHub Actions build
2. Wait 60 detik (untuk workflow mulai)
3. Auto-download binary (script akan tunggu kalau masih building)

---

### Method 2: Manual Control (Step-by-Step)

**Step 1: Trigger Build**

```bash
gh workflow run blockchain-node-ci.yml
```

Expected output:
```
✓ Created workflow_dispatch event for blockchain-node-ci.yml at main
```

**Step 2: Monitor Status**

```bash
gh run list --workflow=blockchain-node-ci.yml --limit 5
```

Expected output:
```
STATUS     TITLE                    WORKFLOW              BRANCH  EVENT              ID          
✓          Blockchain Node CI       blockchain-node-ci    main    workflow_dispatch  123456789
```

**Status indicators:**
- ⏳ `queued` - Menunggu runner
- ▶️ `in_progress` - Sedang build (15-30 menit)
- ✅ `completed` - Selesai (check conclusion)

**Step 3: Watch Build Progress (Optional)**

```bash
gh run watch
```

Ini akan show real-time logs. Press `Ctrl+C` untuk keluar kapan saja.

**Step 4: Download Binary**

```bash
./scripts/download-chain-binary.sh
```

Script ini **automatic wait** kalau build masih in-progress!

---

## 🎮 Running Testnet

### Quick Test (Temporary Database)

```bash
# Start development node
./bin/ghost-node --dev --tmp
```

**Expected output:**
```
2025-11-17 10:00:00 Ghost Chain Node
2025-11-17 10:00:00 ✨ version 0.1.0-abc1234
2025-11-17 10:00:00 ❤️  by Ghost Protocol Team
2025-11-17 10:00:00 📋 Chain specification: Development
2025-11-17 10:00:00 🏷  Node name: warm-tree-1234
2025-11-17 10:00:00 👤 Role: AUTHORITY
2025-11-17 10:00:00 💾 Database: RocksDb at /tmp/...
2025-11-17 10:00:00 🔨 Initializing Genesis block/state
2025-11-17 10:00:00 🏷  Local node identity is: 12D3KooW...
2025-11-17 10:00:00 💤 Idle (0 peers), best: #0 (0x...)
```

**Access node:**
- HTTP RPC: `http://localhost:9944`
- WebSocket: `ws://localhost:9944`

---

### Persistent Database (Keep Blockchain Data)

```bash
# Create data directory
mkdir -p testnet-data

# Start with persistent storage
./bin/ghost-node --dev --base-path ./testnet-data
```

---

### Stop Node

Press `Ctrl+C` in the terminal.

---

## 🔧 Common Commands

```bash
# Check binary version
./bin/ghost-node --version

# Purge chain data (reset blockchain)
./bin/ghost-node purge-chain --dev

# Export chain spec to JSON
./bin/ghost-node build-spec --dev > chain-spec.json

# Start with custom RPC port
./bin/ghost-node --dev --tmp --rpc-port 9955

# Start with RPC exposed to network (for frontend)
./bin/ghost-node --dev --tmp --rpc-external --rpc-cors all

# Show all options
./bin/ghost-node --help
```

---

## 🧪 Test RPC Connection

```bash
# Check node health
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_health"}' \
  http://localhost:9944

# Get chain name
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_chain"}' \
  http://localhost:9944

# Get node version
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_version"}' \
  http://localhost:9944
```

---

## 🔄 Update to Latest Build

Kalau ada code changes baru di repository:

```bash
# Trigger new build
gh workflow run blockchain-node-ci.yml

# Wait for completion (15-30 min)
gh run list --workflow=blockchain-node-ci.yml --limit 3

# Download updated binary
./scripts/download-chain-binary.sh

# Restart node with new binary
./bin/ghost-node --dev --tmp
```

---

## 🐛 Troubleshooting

### Issue: `gh: command not found`

**Cause:** PATH not loaded yet

**Solution:**
```bash
# Option 1: Use full path
gh --version

# Option 2: Reload shell
source ~/.bashrc

# Option 3: Restart Replit shell
```

---

### Issue: `Authentication required`

**Cause:** GitHub CLI not authenticated

**Solution:**
```bash
gh auth login
# Follow authentication steps above
```

---

### Issue: `No artifacts found`

**Cause:** Build belum selesai atau failed

**Solution:**
```bash
# Check build status
gh run list --workflow=blockchain-node-ci.yml --limit 5

# If in_progress: wait
# If failed: check logs
gh run view <run-id> --log
```

---

### Issue: `Permission denied` when running node

**Solution:**
```bash
chmod +x ./bin/ghost-node
./bin/ghost-node --version
```

---

### Issue: Build takes too long

**Expected:** 15-30 minutes (normal for Substrate compilation)

**Check progress:**
```bash
gh run watch
```

---

## 📊 Workflow Status Commands

```bash
# List recent runs
gh run list --workflow=blockchain-node-ci.yml --limit 10

# View specific run
gh run view <run-id>

# Watch running workflow
gh run watch

# Download logs
gh run view <run-id> --log > workflow-logs.txt

# Cancel running workflow
gh run cancel <run-id>
```

---

## 🎯 Complete Workflow Example

Here's complete workflow dari trigger sampai running node:

```bash
# === AUTHENTICATION (Once Only) ===
gh auth login
# Paste your GitHub token

# === BUILD & DOWNLOAD ===
# Trigger build
gh workflow run blockchain-node-ci.yml

# Monitor (optional)
gh run list --workflow=blockchain-node-ci.yml --limit 3

# Download (auto-waits if building)
./scripts/download-chain-binary.sh

# === RUN NODE ===
# Quick test
./bin/ghost-node --dev --tmp

# Or with persistent data
mkdir -p testnet-data
./bin/ghost-node --dev --base-path ./testnet-data

# === TEST RPC ===
# Open new Replit shell tab and test
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_health"}' \
  http://localhost:9944
```

---

## 💡 Pro Tips

1. **Alias untuk convenience:**
   ```bash
   # Add to ~/.bashrc
   alias ghw='gh workflow run blockchain-node-ci.yml'
   alias ghr='gh run list --workflow=blockchain-node-ci.yml --limit 5'
   alias node-dl='./scripts/download-chain-binary.sh'
   alias node-dev='./bin/ghost-node --dev --tmp'
   
   # Reload
   source ~/.bashrc
   
   # Now you can use:
   ghw              # Trigger build
   ghr              # Check status
   node-dl          # Download binary
   node-dev         # Run node
   ```

2. **Auto-trigger on push:**
   Workflow otomatis trigger kalau Anda push ke `main` atau `develop`:
   ```bash
   git add packages/chain/
   git commit -m "feat(chain): update runtime"
   git push origin develop
   # Build starts automatically!
   ```

3. **Check artifacts without downloading:**
   ```bash
   gh run view <run-id> --json artifacts --jq '.artifacts[].name'
   ```

4. **Multi-window setup:**
   - **Shell 1:** Run node (`./bin/ghost-node --dev --tmp`)
   - **Shell 2:** Test RPC calls
   - **Shell 3:** Monitor logs

---

## 🆘 Quick Reference Card

```bash
# Authentication (once)
gh auth login

# Build workflow
gh workflow run blockchain-node-ci.yml     # Trigger
gh run list --workflow=blockchain-node-ci.yml  # Status
gh run watch                                # Watch live

# Download & run
./scripts/download-chain-binary.sh               # Download
./bin/ghost-node --dev --tmp                     # Run

# Common tasks
./bin/ghost-node --version                       # Version
./bin/ghost-node purge-chain --dev               # Reset
curl -X POST -H "Content-Type: application/json" \
  -d '{"id":1,"jsonrpc":"2.0","method":"system_health"}' \
  http://localhost:9944                          # Test RPC
```

---

## 📚 Additional Resources

- **Full Build Guide:** [docs/blockchain-node-build-guide.md](./blockchain-node-build-guide.md)
- **Quick Start:** [docs/QUICK-START-TESTNET.md](./QUICK-START-TESTNET.md)
- **Architecture:** [docs/adr/ADR-20251116-006-chain-ghost-node-architecture.md](../docs/adr/ADR-20251116-006-chain-ghost-node-architecture.md)

---

## 🎓 Next Steps

Setelah node running:

1. **Connect Frontend:** Point ChainGhost UI ke `ws://localhost:9944`
2. **Deploy Smart Contracts:** Use node untuk contract testing
3. **Multi-Node Setup:** See full testnet guide
4. **Production Deploy:** Use Docker images from workflow

---

**Happy Building! 🚀**

Questions? Check GitHub Issues or workflow logs.
