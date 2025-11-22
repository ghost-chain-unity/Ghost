# 🚀 Quick Test: Trigger & Download Blockchain Binary from Replit

**Status:** ✅ GitHub CLI installed and ready at `~/.local/bin/gh`

---

## ⚡ Immediate Test (2 Commands)

```bash
# 1. Authenticate (one-time only)
gh auth login
# Paste GitHub token when prompted

# 2. Trigger build & download (automated)
./scripts/trigger-and-download.sh
```

**Expected result:** 
- Workflow triggered on GitHub Actions
- Script waits for build to complete (15-30 min)
- Binary auto-downloaded to `bin/ghost-node`
- Ready to run testnet!

---

## 🧪 Manual Testing (Step-by-Step)

### Step 1: Authenticate GitHub CLI

```bash
gh auth login
```

Choose:
- **Account:** GitHub.com
- **Protocol:** HTTPS
- **Authenticate Git:** Yes
- **Method:** Paste authentication token

Get token from: https://github.com/settings/tokens/new
- Scopes needed: `repo`, `workflow`, `read:org`

Verify:
```bash
gh auth status
```

### Step 2: Trigger Build

```bash
gh workflow run blockchain-node-ci.yml
```

Expected: `✓ Created workflow_dispatch event for blockchain-node-ci.yml at main`

### Step 3: Monitor Build

```bash
# Check status
gh run list --workflow=blockchain-node-ci.yml --limit 5

# Watch live (optional)
gh run watch
```

### Step 4: Download Binary

```bash
# Auto-download (waits if still building)
./scripts/download-chain-binary.sh
```

### Step 5: Run Testnet

```bash
# Quick test
./bin/ghost-node --dev --tmp

# Or with persistent data
mkdir -p testnet-data
./bin/ghost-node --dev --base-path ./testnet-data
```

---

## 📊 Verify Installation

```bash
# Check GitHub CLI
gh --version
# Expected: gh version 2.40.1 (2023-12-13)

# Check download script
ls -lh scripts/download-chain-binary.sh
# Expected: -rwxr-xr-x ... download-chain-binary.sh

# Check automation script
ls -lh scripts/trigger-and-download.sh
# Expected: -rwxr-xr-x ... trigger-and-download.sh
```

---

## 📚 Full Documentation

- **Replit Guide:** [docs/replit-testnet-guide.md](docs/replit-testnet-guide.md)
- **Build Guide:** [docs/blockchain-node-build-guide.md](docs/blockchain-node-build-guide.md)
- **Quick Start:** [docs/QUICK-START-TESTNET.md](docs/QUICK-START-TESTNET.md)

---

## 🎯 Success Criteria

After running `./bin/ghost-node --dev --tmp`, you should see:

```
2025-11-17 10:00:00 Ghost Chain Node
2025-11-17 10:00:00 ✨ version 0.1.0-abc1234
2025-11-17 10:00:00 ❤️  by Ghost Protocol Team
2025-11-17 10:00:00 📋 Chain specification: Development
2025-11-17 10:00:00 🏷  Node name: warm-tree-1234
2025-11-17 10:00:00 👤 Role: AUTHORITY
2025-11-17 10:00:00 💾 Database: RocksDb at /tmp/...
2025-11-17 10:00:00 🔨 Initializing Genesis block/state
```

RPC accessible at: `http://localhost:9944`

---

**All set! Ready to trigger build from Replit shell.** 🎉
