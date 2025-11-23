# Ghost Protocol Testnet Setup Guide

## Quick Start

### Prerequisites
- Binary for your system (x86_64 or ARM64)
- ~500MB disk space for chain data
- Ports: 30333-30335 (P2P), 9944-9946 (RPC)

### Option 1: Download Binary (Recommended)

**Linux x86_64:**
```bash
cd packages/chain/node-core
chmod +x scripts/download-binary.sh
./scripts/download-binary.sh

# Generate chain spec
./scripts/generate-chain-spec.sh

# Start 3-validator testnet
./scripts/start-testnet.sh
```

**Get binary from:** https://github.com/Ghost-unity-chain/Ghost/releases/tag/v0.1.0

### Option 2: Build from Source

```bash
cd packages/chain/node-core

# Build release binary (takes 10-15 minutes)
cargo build --release --locked

# Generate chain spec
./scripts/generate-chain-spec.sh

# Start testnet
./scripts/start-testnet.sh
```

---

## Testnet Validators

### Alice (Primary)
- **Node Key:** 0x0001...
- **P2P Port:** 30333
- **RPC Port:** 9944 (Unsafe)
- **Base Path:** `/tmp/ghost-chain/alice`

```bash
./scripts/start-alice.sh
```

### Bob (Secondary)
- **Node Key:** 0x0002...
- **P2P Port:** 30334
- **RPC Port:** 9945 (Unsafe)
- **Base Path:** `/tmp/ghost-chain/bob`

```bash
./scripts/start-bob.sh
```

### Charlie (Tertiary)
- **Node Key:** 0x0003...
- **P2P Port:** 30335
- **RPC Port:** 9946 (Unsafe)
- **Base Path:** `/tmp/ghost-chain/charlie`

```bash
./scripts/start-charlie.sh
```

---

## Query Testnet

### Using curl

**Block number:**
```bash
curl http://localhost:9944 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"chain_getHeader"}'
```

**Account balance:**
```bash
curl http://localhost:9944 -X POST -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "state_getStorage",
    "params": ["<storage_key>"]
  }'
```

### Using Polkadot.js Portal

1. Go to https://polkadot.js.org/apps
2. Connect to: `ws://localhost:9944` (Alice)
3. Monitor:
   - Block production (3 sec/block)
   - Finality (GRANDPA)
   - Validators (Alice, Bob, Charlie)

---

## Logs & Troubleshooting

### View logs
```bash
# Alice
tail -f /tmp/ghost-chain/alice/*/logs/

# Bob
tail -f /tmp/ghost-chain/bob/*/logs/

# Charlie
tail -f /tmp/ghost-chain/charlie/*/logs/
```

### Common Issues

**"Port already in use"**
```bash
# Clean previous state
rm -rf /tmp/ghost-chain
./scripts/start-testnet.sh
```

**"Binary not found"**
```bash
# Rebuild
cargo build --release --locked

# OR download from release
./scripts/download-binary.sh
```

**"RPC connection refused"**
- Check ports: `netstat -tlnp | grep 9944`
- Verify node started: `ps aux | grep ghost-node`
- Check logs for errors

---

## Architecture

```
┌─────────────────────────────────────────┐
│      Ghost Testnet (3 Validators)       │
├─────────────────────────────────────────┤
│                                         │
│  Alice ←→ Bob ←→ Charlie                │
│ (Port 30333)  (30334)  (30335)         │
│   RPC 9944    RPC 9945  RPC 9946       │
│                                         │
│  Consensus: Aura (block production)    │
│  Finality:  GRANDPA (Byzantine)        │
│  Block Time: 3 seconds                 │
│  Era:       Mortal (8 blocks)          │
│                                         │
└─────────────────────────────────────────┘
```

---

## Performance

- **Block Time:** 3 seconds (fast testnet)
- **Finality:** ~12 seconds (GRANDPA in good conditions)
- **Storage:** RocksDB (local)
- **Network:** P2P (Substrate)
- **Telemetry:** Optional (disabled by default)

---

## Reset & Cleanup

```bash
# Stop all nodes
pkill -f "ghost-node"

# Delete chain data
rm -rf /tmp/ghost-chain

# Regenerate chain spec
./scripts/generate-chain-spec.sh

# Restart testnet
./scripts/start-testnet.sh
```

---

## Documentation

- **Configuration:** See `CONFIGURATION.md`
- **Chain Spec:** `chain-specs/local-testnet.json`
- **Binary Build:** `Dockerfile` (for Docker build)
- **Scripts:** `scripts/README.md`

---

**Status:** ✅ Testnet Ready  
**Last Updated:** November 23, 2025
