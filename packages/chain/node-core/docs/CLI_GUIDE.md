# ChainGhost Node CLI Guide

This guide provides comprehensive documentation for the ChainGhost node command-line interface (CLI).

## Table of Contents

1. [Installation](#installation)
2. [CLI Commands Overview](#cli-commands-overview)
3. [Node Operations](#node-operations)
4. [Key Management](#key-management)
5. [Chain Operations](#chain-operations)
6. [Validator Operations](#validator-operations)
7. [Benchmarking](#benchmarking)
8. [Common Workflows](#common-workflows)
9. [Configuration Options](#configuration-options)
10. [Troubleshooting](#troubleshooting)

## Installation

Build the ChainGhost node binary:

```bash
cd packages/chain/node-core
cargo build --release
```

The binary will be located at `target/release/ghost-node`.

## CLI Commands Overview

The ChainGhost node CLI provides the following subcommands:

```bash
ghost-node [OPTIONS] [SUBCOMMAND]
```

### Available Subcommands

- `key` - Key management utilities
- `build-spec` - Build chain specification
- `check-block` - Validate blocks
- `export-blocks` - Export blocks to file
- `import-blocks` - Import blocks from file
- `export-state` - Export state as chain spec
- `purge-chain` - Remove all chain data
- `revert` - Revert chain to previous state
- `benchmark` - Run benchmarks
- `chain-info` - Display database metadata

Without a subcommand, the node starts in full node mode.

## Node Operations

### Starting a Node

#### Development Node

Start a single-node development chain:

```bash
ghost-node --dev
```

This starts a node with:
- Pre-funded development accounts (Alice, Bob, etc.)
- Instant block production
- Data stored in temporary directory

#### Full Node (Testnet/Mainnet)

Start a full node connecting to a network:

```bash
ghost-node \
  --chain <CHAIN_SPEC> \
  --base-path /var/lib/ghost-node \
  --name "MyNode" \
  --rpc-port 9944 \
  --port 30333
```

#### Validator Node

Start a validator node:

```bash
ghost-node \
  --chain <CHAIN_SPEC> \
  --base-path /var/lib/ghost-validator \
  --validator \
  --name "MyValidator" \
  --rpc-port 9944 \
  --port 30333
```

#### Archive Node

Archive nodes keep all historical state:

```bash
ghost-node \
  --chain <CHAIN_SPEC> \
  --base-path /var/lib/ghost-archive \
  --pruning archive \
  --name "MyArchive"
```

### Node Configuration Flags

#### Network Configuration

- `--chain <SPEC>` - Chain specification to use (dev, local, or path to JSON)
- `--port <PORT>` - P2P network port (default: 30333)
- `--bootnodes <NODES>` - Comma-separated list of bootnode addresses
- `--reserved-nodes <NODES>` - Reserved peer nodes
- `--public-addr <ADDR>` - Public address to advertise

#### Storage Configuration

- `--base-path <PATH>` - Base directory for node data
- `--pruning <MODE>` - State pruning mode (archive, or number of blocks)
- `--database <TYPE>` - Database backend (rocksdb, paritydb)

#### RPC Configuration

- `--rpc-port <PORT>` - HTTP RPC port (default: 9944)
- `--rpc-methods <TYPE>` - RPC methods (Safe, Unsafe, Auto)
- `--rpc-cors <ORIGINS>` - CORS allowed origins (all, or comma-separated)
- `--rpc-external` - Listen on all network interfaces
- `--rpc-max-connections <N>` - Maximum RPC connections

#### Validator Configuration

- `--validator` - Enable validator mode
- `--node-key <KEY>` - Network identity key
- `--node-key-file <FILE>` - File containing network identity key

#### Logging

- `-l, --log <TARGETS>` - Set log filter (e.g., info, debug, runtime=debug)
- `--log-pattern <PATTERN>` - Custom log pattern

## Key Management

### Generate Keys

Generate a new keypair:

```bash
ghost-node key generate
```

Output includes:
- Secret phrase (mnemonic)
- Secret seed (hex)
- Public key (hex)
- Account ID
- SS58 Address

#### Generate Specific Key Type

```bash
ghost-node key generate --scheme Sr25519
ghost-node key generate --scheme Ed25519
ghost-node key generate --scheme Ecdsa
```

#### With Custom Output Format

```bash
ghost-node key generate --output-type json
```

### Inspect Keys

Inspect a key from secret phrase or seed:

```bash
ghost-node key inspect "bottom drive obey lake curtain smoke basket hold race lonely fit walk"
```

From hex seed:

```bash
ghost-node key inspect 0xe5be9a5092b81bca64be81d212e7f2f9eba183bb7a90954f7b76361f6edb5c0a
```

With specific scheme:

```bash
ghost-node key inspect --scheme Sr25519 "secret phrase..."
```

### Insert Keys

Insert a key into the node's keystore:

```bash
ghost-node key insert \
  --base-path /var/lib/ghost-node \
  --chain <CHAIN_SPEC> \
  --scheme Sr25519 \
  --suri "secret phrase..." \
  --key-type aura
```

Common key types:
- `aura` - Block production (AURA)
- `gran` - Finality (GRANDPA)
- `imon` - I'm Online
- `babe` - Block production (BABE)

## Chain Operations

### Build Chain Specification

Generate a chain spec file:

```bash
ghost-node build-spec --chain local > chain-spec.json
```

Convert to raw format (required for production):

```bash
ghost-node build-spec --chain chain-spec.json --raw > chain-spec-raw.json
```

Disable default bootnode:

```bash
ghost-node build-spec --chain local --disable-default-bootnode > chain-spec.json
```

### Export Blocks

Export blocks to a file:

```bash
ghost-node export-blocks \
  --base-path /var/lib/ghost-node \
  --chain <CHAIN_SPEC> \
  blocks.bin
```

Export specific range:

```bash
ghost-node export-blocks \
  --base-path /var/lib/ghost-node \
  --chain <CHAIN_SPEC> \
  --from 1 \
  --to 1000 \
  blocks-1-1000.bin
```

### Import Blocks

Import blocks from a file:

```bash
ghost-node import-blocks \
  --base-path /var/lib/ghost-node \
  --chain <CHAIN_SPEC> \
  blocks.bin
```

### Export State

Export state at specific block:

```bash
ghost-node export-state \
  --base-path /var/lib/ghost-node \
  --chain <CHAIN_SPEC> \
  state-export.json
```

At specific block:

```bash
ghost-node export-state \
  --base-path /var/lib/ghost-node \
  --chain <CHAIN_SPEC> \
  --at <BLOCK_HASH> \
  state-export.json
```

### Check Block

Validate a specific block:

```bash
ghost-node check-block \
  --base-path /var/lib/ghost-node \
  --chain <CHAIN_SPEC> \
  <BLOCK_HASH>
```

### Purge Chain

Remove all chain data:

```bash
ghost-node purge-chain \
  --base-path /var/lib/ghost-node \
  --chain <CHAIN_SPEC>
```

With confirmation:

```bash
ghost-node purge-chain \
  --base-path /var/lib/ghost-node \
  --chain <CHAIN_SPEC> \
  -y
```

### Revert Chain

Revert to a previous block:

```bash
ghost-node revert \
  --base-path /var/lib/ghost-node \
  --chain <CHAIN_SPEC> \
  --num <BLOCKS>
```

## Validator Operations

### Setup Validator

1. **Generate Session Keys**

```bash
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys", "params":[]}' \
  http://localhost:9944
```

2. **Insert Keys into Keystore**

For each key type (aura, grandpa, etc.):

```bash
ghost-node key insert \
  --base-path /var/lib/ghost-validator \
  --chain <CHAIN_SPEC> \
  --scheme Sr25519 \
  --suri "<SECRET_PHRASE>" \
  --key-type aura
```

3. **Bond and Set Session Keys**

Use the Polkadot.js UI to:
- Bond tokens
- Set session keys (from step 1)
- Start validating

### Rotate Session Keys

```bash
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys"}' \
  http://localhost:9944
```

### Check Validator Status

Check if node is validating:

```bash
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_health"}' \
  http://localhost:9944
```

## Benchmarking

### Benchmark Pallets

Run pallet benchmarks:

```bash
ghost-node benchmark pallet \
  --chain dev \
  --pallet pallet_balances \
  --extrinsic '*' \
  --steps 50 \
  --repeat 20
```

### Benchmark Storage

```bash
ghost-node benchmark storage \
  --chain dev \
  --base-path /tmp/benchmark
```

### Benchmark Block

```bash
ghost-node benchmark block \
  --chain dev \
  --base-path /tmp/benchmark
```

### Benchmark Overhead

```bash
ghost-node benchmark overhead \
  --chain dev \
  --base-path /tmp/benchmark
```

### Machine Benchmark

Test hardware performance:

```bash
ghost-node benchmark machine
```

## Common Workflows

### Workflow 1: Start Local Development Network

```bash
# Generate chain spec
./scripts/generate-chain-spec.sh

# Start Alice (validator)
./scripts/start-alice.sh &

# Start Bob (validator)
./scripts/start-bob.sh &

# Start Charlie (validator)
./scripts/start-charlie.sh &
```

### Workflow 2: Become a Validator

```bash
# 1. Ensure node is synced
ghost-node --chain <CHAIN_SPEC> --validator --base-path /var/lib/validator

# 2. Generate and rotate session keys
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys"}' \
  http://localhost:9944

# 3. Bond tokens and set session keys via UI

# 4. Wait for next era to start validating
```

### Workflow 3: Backup and Restore Node

**Backup:**

```bash
# Stop node first
systemctl stop ghost-node

# Backup database
tar -czf ghost-backup-$(date +%Y%m%d).tar.gz /var/lib/ghost-node

# Restart node
systemctl start ghost-node
```

**Restore:**

```bash
# Stop node
systemctl stop ghost-node

# Restore database
tar -xzf ghost-backup-20241121.tar.gz -C /

# Restart node
systemctl start ghost-node
```

### Workflow 4: Network Upgrade

```bash
# 1. Build new binary
cargo build --release

# 2. Stop node
systemctl stop ghost-node

# 3. Replace binary
cp target/release/ghost-node /usr/local/bin/

# 4. Start node
systemctl start ghost-node

# 5. Monitor logs
journalctl -u ghost-node -f
```

## Configuration Options

### Environment Variables

- `RUST_LOG` - Set logging level (e.g., `RUST_LOG=info`)
- `RUST_BACKTRACE` - Enable backtraces (1 or full)

### Configuration File

While the node doesn't use a traditional config file, you can create wrapper scripts with your preferred settings.

Example validator config script:

```bash
#!/bin/bash
ghost-node \
  --chain mainnet \
  --base-path /var/lib/ghost-validator \
  --validator \
  --name "MyValidator" \
  --rpc-port 9944 \
  --port 30333 \
  --telemetry-url "wss://telemetry.polkadot.io/submit/ 0" \
  --prometheus-external \
  --prometheus-port 9615
```

## Troubleshooting

### Node Won't Start

**Problem:** Binary not found

```bash
# Solution: Ensure binary is built
cargo build --release
export PATH=$PATH:$(pwd)/target/release
```

**Problem:** Chain spec not found

```bash
# Solution: Generate chain spec
ghost-node build-spec --chain local > chain-spec.json
```

**Problem:** Port already in use

```bash
# Solution: Check what's using the port
lsof -i :9944
# Kill the process or use different port
ghost-node --rpc-port 9945
```

### Sync Issues

**Problem:** Node not syncing

```bash
# Check peer count
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_health"}' \
  http://localhost:9944

# Add bootnodes
ghost-node --bootnodes /ip4/x.x.x.x/tcp/30333/p2p/<PEER_ID>
```

**Problem:** Node stuck at specific block

```bash
# Revert to previous block
ghost-node revert --num 10

# Or purge and resync
ghost-node purge-chain -y
```

### Validator Issues

**Problem:** Not producing blocks

```bash
# 1. Check session keys are set
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "author_hasSessionKeys", "params":["<YOUR_KEYS>"]}' \
  http://localhost:9944

# 2. Check validator is in active set
# Use block explorer or Polkadot.js UI

# 3. Check node is synced
# Should show "isSyncing: false" in system_health
```

**Problem:** Session keys lost

```bash
# Re-generate keys
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys"}' \
  http://localhost:9944

# Update on chain via setKeys extrinsic
```

### Database Corruption

**Problem:** Database errors on startup

```bash
# Try reverting
ghost-node revert --num 100

# If that fails, purge and resync
ghost-node purge-chain -y
ghost-node import-blocks backup-blocks.bin
```

### Performance Issues

**Problem:** High CPU/Memory usage

```bash
# Check system resources
htop

# Reduce pruning window
ghost-node --pruning 256

# Limit database cache
ghost-node --database-cache 128

# Use faster database backend
ghost-node --database paritydb
```

### RPC Issues

**Problem:** RPC calls timing out

```bash
# Increase max connections
ghost-node --rpc-max-connections 500

# Use unsafe methods for development only
ghost-node --rpc-methods Unsafe

# Enable CORS for web apps
ghost-node --rpc-cors all
```

### Log Analysis

**Check logs for errors:**

```bash
# With systemd
journalctl -u ghost-node -n 100 --no-pager

# Direct node logs
ghost-node -l runtime=debug,consensus=trace
```

**Common log patterns:**

- `Imported #` - Block import successful
- `Idle` - Waiting for blocks
- `Starting consensus session` - Validator starting block production
- `Pre-sealed block for proposal` - Block produced

## Additional Resources

- [Substrate Documentation](https://docs.substrate.io/)
- [Polkadot Wiki](https://wiki.polkadot.network/)
- [ChainGhost GitHub](https://github.com/your-org/chainghost)

## Helper Scripts

The `scripts/cli/` directory contains helper scripts for common operations:

- `node-start.sh` - Start node with configuration
- `node-stop.sh` - Gracefully stop node
- `node-status.sh` - Check node status
- `create-validator.sh` - Setup validator keys
- `rotate-session-keys.sh` - Rotate validator keys
- `inspect-chain.sh` - Quick chain inspection

See individual script documentation for usage.
