# Ghost Chain Configuration Summary

## PHASE 1 Implementation - Substrate Baseline Node

**Date**: November 16, 2025  
**Task**: TASK-1.1.2 PHASE 1  
**Status**: ✅ Configuration Complete, ⏳ Build In Progress

---

## Configuration Changes

### 1. Runtime Configuration (runtime/src/lib.rs)

#### Block Time: 6s → 3s
```rust
// Before:
pub const MILLI_SECS_PER_BLOCK: u64 = 6000;

// After:
pub const MILLI_SECS_PER_BLOCK: u64 = 3000;  // 3 seconds
```

#### Runtime Identity
```rust
// Runtime Package Name:
// Before: solochain-template-runtime
// After: ghost-runtime

// Runtime Spec (runtime/src/lib.rs):
spec_name: "ghost-chain-runtime"
impl_name: "ghost-chain-runtime"
```

### 2. Genesis Configuration (runtime/src/genesis_config_presets.rs)

#### Validators: 2 → 3 (Added Charlie)
```rust
// Before (local_config_genesis):
initial_authorities: vec![
    (Alice_Aura, Alice_Grandpa),
    (Bob_Aura, Bob_Grandpa),
]

// After:
initial_authorities: vec![
    (Alice_Aura, Alice_Grandpa),
    (Bob_Aura, Bob_Grandpa),
    (Charlie_Aura, Charlie_Grandpa),  // ADDED
]
```

### 3. Launch Scripts Created

#### Scripts Directory: `scripts/`

1. **generate-chain-spec.sh**
   - Generates local testnet chain spec
   - Creates both JSON and raw formats
   - Output: chain-specs/local-testnet{,-raw}.json

2. **start-alice.sh**
   - Validator 1
   - Ports: 30333 (P2P), 9944 (RPC)
   - Node key: 0x01...01

3. **start-bob.sh**
   - Validator 2
   - Ports: 30334 (P2P), 9945 (RPC)
   - Node key: 0x02...02
   - Bootnode: Alice

4. **start-charlie.sh**
   - Validator 3
   - Ports: 30335 (P2P), 9946 (RPC)
   - Node key: 0x03...03
   - Bootnode: Alice

5. **start-testnet.sh**
   - Launches all 3 validators
   - Starts sequentially with 2s delay
   - Graceful shutdown on Ctrl+C

6. **cleanup.sh**
   - Removes all testnet data
   - Preserves chain specs

---

## Consensus Configuration

### Aura (Block Production)
- **Algorithm**: Authority Round (round-robin)
- **Slot Duration**: 3 seconds
- **Authorities**: 3 (Alice, Bob, Charlie)
- **Config**: `pallet_aura::Config`
  - `MaxAuthorities`: 32
  - `AllowMultipleBlocksPerSlot`: false
  - `SlotDuration`: MinimumPeriodTimesTwo (3000ms / 2 * 2 = 3000ms)

### GRANDPA (Finality)
- **Algorithm**: GHOST-based finality gadget
- **Target**: Finalize blocks within 6 seconds (2 blocks)
- **Config**: `pallet_grandpa::Config`
  - `MaxAuthorities`: 32
  - `MaxNominators`: 0 (PoA, no nominations)
  - `MaxSetIdSessionEntries`: 0

### Timestamp
- **Config**: `pallet_timestamp::Config`
  - `Moment`: u64 (milliseconds)
  - `OnTimestampSet`: Aura
  - `MinimumPeriod`: SLOT_DURATION / 2 = 1500ms

---

## Substrate Crates Used

### Node Layer
- `sc_service` - Node service management
- `sc_cli` - CLI framework
- `sc_network` - P2P networking (libp2p)
- `sc_consensus` - Consensus framework
- `sc_consensus_aura` - Aura implementation
- `sc_consensus_grandpa` - GRANDPA implementation
- `sc_transaction_pool` - Transaction pool
- `sc_executor` - WASM runtime executor
- `sc_telemetry` - Telemetry client

### Runtime Layer (Pallets)
- `frame_system` - Core system
- `frame_support` - Pallet framework
- `frame_executive` - Block execution
- `pallet_aura` - Aura consensus
- `pallet_grandpa` - GRANDPA finality
- `pallet_timestamp` - Timestamp
- `pallet_balances` - Balances
- `pallet_transaction_payment` - Fees
- `pallet_sudo` - Superuser (testnet)

### Primitives
- `sp_api` - Runtime API traits
- `sp_runtime` - Runtime primitives
- `sp_core` - Crypto primitives
- `sp_consensus_aura` - Aura types
- `sp_consensus_grandpa` - GRANDPA types
- `sp_block_builder` - Block building
- `sp_transaction_pool` - TX pool types

---

## Project Structure

```
packages/chain/node-core/
├── Cargo.toml              # Workspace manifest
├── Cargo.lock              # Dependency lock
├── README.md               # User documentation
├── CONFIGURATION.md        # This file
│
├── node/                   # Node implementation
│   ├── Cargo.toml
│   └── src/
│       ├── main.rs         # Entry point
│       ├── cli.rs          # CLI setup
│       ├── command.rs      # Command handling
│       ├── service.rs      # Node service
│       ├── chain_spec.rs   # Chain specs
│       └── rpc.rs          # RPC config
│
├── runtime/                # Blockchain runtime (WASM)
│   ├── Cargo.toml
│   ├── build.rs            # Build script
│   └── src/
│       ├── lib.rs          # Runtime composition (MODIFIED)
│       ├── apis.rs         # Runtime APIs
│       ├── genesis_config_presets.rs (MODIFIED)
│       └── configs/
│           └── mod.rs      # Pallet configs
│
├── pallets/                # Custom pallets (future)
│   └── template/           # Example pallet
│
├── scripts/                # Launch scripts (CREATED)
│   ├── generate-chain-spec.sh
│   ├── start-testnet.sh
│   ├── start-alice.sh
│   ├── start-bob.sh
│   ├── start-charlie.sh
│   └── cleanup.sh
│
└── chain-specs/            # Generated chain specs
    ├── local-testnet.json
    └── local-testnet-raw.json
```

---

## Success Criteria Verification

### Build
- [ ] ✅ Substrate node compiles successfully (`cargo build --release`)
  - **Status**: ⏳ In Progress (15-30 minutes)
  - **Binary**: `target/release/ghost-node`

### Chain Spec
- [x] ✅ Chain spec generation script created
  - **Script**: `scripts/generate-chain-spec.sh`
  - **Output**: 3 authorities (Alice, Bob, Charlie)

### Testnet Launch
- [x] ✅ Launch scripts created for 3-node testnet
  - **Script**: `scripts/start-testnet.sh`
  - **Validators**: Alice (9944), Bob (9945), Charlie (9946)

### Block Production
- [ ] ⏳ Blocks produced every 3 seconds (±100ms tolerance)
  - **Test**: Run testnet and monitor logs
  - **Expected**: "Imported #N" every ~3 seconds

### Finality
- [ ] ⏳ GRANDPA finalizes blocks within 6 seconds (2 blocks)
  - **Test**: Monitor "Finalized #N" in logs
  - **Expected**: Finality within 2 blocks

### Stability
- [ ] ⏳ No panics or critical errors in logs
  - **Test**: Run testnet for 5+ minutes
  - **Expected**: Clean logs, no crashes

---

## Next Steps

1. **Complete Build** (⏳ In Progress)
   - Wait for `cargo build --release` to finish
   - Verify binary at `target/release/ghost-node`

2. **Generate Chain Spec**
   ```bash
   ./scripts/generate-chain-spec.sh
   ```

3. **Launch Testnet**
   ```bash
   ./scripts/start-testnet.sh
   ```

4. **Verify Block Production**
   - Monitor logs for 3-second block times
   - Check all 3 validators are producing blocks

5. **Verify Finality**
   - Monitor GRANDPA finality messages
   - Confirm 6-second finality window

6. **Connect with Polkadot.js Apps**
   - Open https://polkadot.js.org/apps/
   - Connect to ws://127.0.0.1:9944
   - Verify chain state and blocks

---

## Testing Checklist

### Pre-Test
- [ ] Build completed successfully
- [ ] Binary exists at `target/release/ghost-node`
- [ ] Chain spec generated

### Test Execution
- [ ] Start all 3 validators
- [ ] Wait for network to initialize
- [ ] Observe block production (3s interval)
- [ ] Observe finality (6s window)
- [ ] Run for 5+ minutes
- [ ] Check for errors/panics

### Post-Test
- [ ] Document test results
- [ ] Capture sample logs
- [ ] Clean up test data
- [ ] Update README if needed

---

## Configuration Summary

| Parameter | Value | Location |
|-----------|-------|----------|
| Block Time | 3 seconds | `runtime/src/lib.rs:89` |
| Slot Duration | 3 seconds | `runtime/src/lib.rs:93` |
| Validators | 3 (Alice, Bob, Charlie) | `runtime/src/genesis_config_presets.rs:72-87` |
| Finality Window | ~6 seconds (2 blocks) | Automatic (GRANDPA) |
| RPC Ports | 9944, 9945, 9946 | `scripts/start-*.sh` |
| P2P Ports | 30333, 30334, 30335 | `scripts/start-*.sh` |
| Chain ID | `local_testnet` | `node/src/chain_spec.rs:25` |
| Runtime Name | `ghost-chain-runtime` | `runtime/src/lib.rs:67` |

---

## References

- [ADR-006: Chain Ghost Node Architecture](../../docs/adr/ADR-20251116-006-chain-ghost-node-architecture.md)
- [Substrate Documentation](https://docs.substrate.io/)
- [Polkadot SDK Docs](https://paritytech.github.io/polkadot-sdk/master/)

---

## Notes

- This is PHASE 1: baseline node with Aura/GRANDPA
- Custom pallets (ChainGhost, G3Mail, Ghonity) will be added in PHASE 4
- EVM compatibility (Frontier) will be added in a later phase
- Current setup is PoA (Proof of Authority) for testnet
- Future mainnet will use NPoS (Nominated Proof of Stake)
