# Ghost Testnet - Quick Start (30 seconds)

## 1️⃣ Download Binary (if needed)
```bash
cd packages/chain/node-core

# Option A: Using script (auto-detects x86_64/ARM64)
chmod +x scripts/download-binary.sh
./scripts/download-binary.sh

# Option B: Manual download
# Get v0.1.0 binary for your OS from:
# https://github.com/Ghost-unity-chain/Ghost/releases/tag/v0.1.0
```

## 2️⃣ Generate Chain Spec (1st time only)
```bash
./scripts/generate-chain-spec.sh
```

## 3️⃣ Start Testnet (3 validators)
```bash
./scripts/start-testnet.sh
```

## 4️⃣ Query Testnet
```bash
# Check latest block (in new terminal)
curl http://localhost:9944 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"chain_getHeader"}'

# Or use Polkadot.js Portal:
# https://polkadot.js.org/apps
# Connect to: ws://localhost:9944
```

## 5️⃣ Stop Testnet
```bash
pkill -f "ghost-node"
```

---

## Node Endpoints

| Node | P2P Port | RPC Port | WebSocket |
|------|----------|----------|-----------|
| Alice | 30333 | 9944 | ws://localhost:9944 |
| Bob | 30334 | 9945 | ws://localhost:9945 |
| Charlie | 30335 | 9946 | ws://localhost:9946 |

---

## Logs
```bash
tail -f /tmp/ghost-chain/alice/chains/local_testnet/*/logs/*
```

## Reset
```bash
pkill -f "ghost-node"
rm -rf /tmp/ghost-chain
./scripts/generate-chain-spec.sh
./scripts/start-testnet.sh
```

---

**Status:** ✅ TESTED & WORKING  
**Block Time:** 3 seconds  
**Consensus:** Aura (production) + GRANDPA (finality)
