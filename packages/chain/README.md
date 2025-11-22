# Chain Layer (Ghost Chain)

Blockchain infrastructure for Ghost Protocol.

## Components

### node-core
Core blockchain node implementation.
- **Tech Stack:** Rust
- **Consensus:** Lightweight PoA (testnet), NPoS (mainnet planned)
- **Storage:** RocksDB
- **RPC:** JSON-RPC HTTP + WebSocket
- **Status:** 📋 Planned (not implemented)

### chain-cli
Command-line tools for chain management.
- **Tech Stack:** Rust/Node.js
- **Features:** Node management, wallet utilities, deployment tools
- **Status:** 📋 Planned (not implemented)

## Build

```bash
# Build node-core
cd node-core
cargo build --release

# Build chain-cli
cd chain-cli
cargo build --release
```

## Run

```bash
# Start local node
./target/release/ghost-node --dev

# Run CLI command
./target/release/ghost-cli --help
```

## Architecture

```
Chain Layer
├── Consensus (PoA/NPoS)
├── Storage (RocksDB)
├── RPC Interface (JSON-RPC)
└── P2P Network
```

## Testing

```bash
# Run all tests
cargo test

# Run specific tests
cargo test --package node-core
```

## Development

Follow Substrate/Rust best practices:
- Use Clippy for linting
- Format code with rustfmt
- Write comprehensive tests
- Document public APIs

---

**Last Updated:** November 15, 2025
