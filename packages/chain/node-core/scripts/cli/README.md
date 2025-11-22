# ChainGhost CLI Helper Scripts

This directory contains helper scripts to simplify common ChainGhost node operations.

## Available Scripts

### Node Management

#### `node-start.sh`
Start a ChainGhost node with configurable options.

```bash
# Start development node
./node-start.sh --mode dev

# Start validator node
./node-start.sh --mode validator --name MyValidator --base-path /var/lib/ghost-validator

# Start full node
./node-start.sh --mode full --base-path /var/lib/ghost-node

# Start archive node
./node-start.sh --mode archive --pruning archive
```

**Options:**
- `-c, --config FILE` - Configuration file
- `-m, --mode MODE` - Node mode (dev, validator, full, archive)
- `-n, --name NAME` - Node name
- `-p, --base-path PATH` - Base path for data
- `-s, --chain SPEC` - Chain specification
- `--rpc-port PORT` - RPC port (default: 9944)
- `--p2p-port PORT` - P2P port (default: 30333)
- `--validator` - Enable validator mode
- `-h, --help` - Show help

#### `node-stop.sh`
Gracefully stop a running node.

```bash
# Stop node by name
./node-stop.sh --name MyValidator

# Stop node by PID
./node-stop.sh --pid 12345

# Force stop with timeout
./node-stop.sh --name MyValidator --force --timeout 60
```

**Options:**
- `-n, --name NAME` - Node name to stop
- `-p, --pid PID` - Process ID to stop
- `-f, --force` - Force kill if graceful shutdown fails
- `-t, --timeout SECONDS` - Timeout for graceful shutdown (default: 30)
- `-h, --help` - Show help

#### `node-status.sh`
Check the status of a running node.

```bash
# Check local node status
./node-status.sh

# Check specific node
./node-status.sh --name MyValidator

# Verbose output
./node-status.sh --verbose

# JSON output
./node-status.sh --json
```

**Options:**
- `-r, --rpc-url URL` - RPC endpoint (default: http://localhost:9944)
- `-n, --name NAME` - Node name to check
- `-v, --verbose` - Show detailed information
- `-j, --json` - Output in JSON format
- `-h, --help` - Show help

### Validator Management

#### `create-validator.sh`
Generate and setup validator keys.

```bash
# Generate validator keys
./create-validator.sh --name MyValidator

# Custom base path
./create-validator.sh --name MyValidator --base-path /var/lib/ghost-validator

# Ed25519 keys
./create-validator.sh --scheme Ed25519
```

**Options:**
- `-n, --name NAME` - Validator name
- `-p, --base-path PATH` - Base path for data
- `-s, --chain SPEC` - Chain specification
- `--output FILE` - Output file for keys
- `--scheme SCHEME` - Key scheme (Sr25519, Ed25519, Ecdsa)
- `-h, --help` - Show help

**Important:** This script generates and saves sensitive keys. Backup the output file securely!

#### `rotate-session-keys.sh`
Rotate validator session keys.

```bash
# Rotate keys on local node
./rotate-session-keys.sh

# Rotate keys on remote node
./rotate-session-keys.sh --rpc-url http://validator.example.com:9944

# Save to custom file
./rotate-session-keys.sh --output my-session-keys.txt
```

**Options:**
- `-r, --rpc-url URL` - RPC endpoint (default: http://localhost:9944)
- `-o, --output FILE` - Output file for keys
- `-v, --verbose` - Show detailed information
- `-h, --help` - Show help

### Chain Inspection

#### `inspect-chain.sh`
Quick inspection of blockchain status.

```bash
# Inspect local chain
./inspect-chain.sh

# Inspect remote chain
./inspect-chain.sh --rpc-url http://node.example.com:9944

# Show last 10 blocks
./inspect-chain.sh --blocks 10 --verbose

# JSON output
./inspect-chain.sh --json
```

**Options:**
- `-r, --rpc-url URL` - RPC endpoint (default: http://localhost:9944)
- `-b, --blocks NUM` - Number of recent blocks to show (default: 5)
- `-v, --verbose` - Show detailed information
- `-j, --json` - Output in JSON format
- `-h, --help` - Show help

## Common Workflows

### Workflow 1: Setting Up a Validator

```bash
# 1. Build the node
cd packages/chain/node-core
cargo build --release

# 2. Generate validator keys
./scripts/cli/create-validator.sh --name MyValidator --base-path /var/lib/ghost-validator

# 3. Start validator node
./scripts/cli/node-start.sh --mode validator --name MyValidator --base-path /var/lib/ghost-validator

# 4. Rotate session keys (in another terminal)
./scripts/cli/rotate-session-keys.sh

# 5. Set session keys on-chain via Polkadot.js UI

# 6. Monitor validator status
./scripts/cli/node-status.sh --verbose
```

### Workflow 2: Running a Full Node

```bash
# 1. Start full node
./scripts/cli/node-start.sh --mode full --name MyFullNode --base-path /var/lib/ghost-node

# 2. Check sync status
./scripts/cli/node-status.sh --verbose

# 3. Inspect chain
./scripts/cli/inspect-chain.sh --blocks 10 --verbose

# 4. Stop node when needed
./scripts/cli/node-stop.sh --name MyFullNode
```

### Workflow 3: Development Testing

```bash
# 1. Start dev node
./scripts/cli/node-start.sh --mode dev

# 2. In another terminal, check status
./scripts/cli/node-status.sh

# 3. Inspect chain
./scripts/cli/inspect-chain.sh --verbose

# 4. Stop when done
./scripts/cli/node-stop.sh
```

### Workflow 4: Archive Node Setup

```bash
# 1. Start archive node
./scripts/cli/node-start.sh \
  --mode archive \
  --name MyArchiveNode \
  --base-path /var/lib/ghost-archive \
  --pruning archive \
  --rpc-external

# 2. Monitor sync progress
watch -n 5 './scripts/cli/node-status.sh --verbose'

# 3. Inspect historical blocks
./scripts/cli/inspect-chain.sh --blocks 20 --verbose
```

## Requirements

### System Requirements

All scripts require:
- `bash` (4.0+)
- `curl` (for RPC calls)
- `jq` (for JSON processing)

Install on Ubuntu/Debian:
```bash
sudo apt update
sudo apt install curl jq
```

Install on macOS:
```bash
brew install curl jq
```

### Node Binary

Scripts expect the `ghost-node` binary at:
```
packages/chain/node-core/target/release/ghost-node
```

Build it with:
```bash
cd packages/chain/node-core
cargo build --release
```

## Configuration

### Environment Variables

Scripts respect these environment variables:
- `GHOST_NODE_BINARY` - Path to ghost-node binary
- `GHOST_BASE_PATH` - Default base path for data
- `GHOST_CHAIN_SPEC` - Default chain specification
- `RUST_LOG` - Rust logging configuration

Example:
```bash
export GHOST_NODE_BINARY=/usr/local/bin/ghost-node
export GHOST_BASE_PATH=/var/lib/ghost-node
export RUST_LOG=info
```

### Configuration Templates

Use configuration templates in `../../config/`:
- `validator.toml` - Validator node configuration
- `full-node.toml` - Full node configuration
- `archive-node.toml` - Archive node configuration

## Security Considerations

### Key Management

1. **NEVER commit keys to version control**
2. **Backup keys securely** - Store in multiple secure locations
3. **Protect output files** - Contains sensitive key material
4. **Use hardware wallets** - For production validators
5. **Rotate keys regularly** - For security best practices

### RPC Security

1. **Never expose RPC unsafely** - Use firewall rules
2. **Use Safe RPC methods** - In production environments
3. **Implement rate limiting** - Prevent abuse
4. **Use HTTPS** - For external RPC access
5. **Authentication** - For sensitive endpoints

### Process Security

1. **Run as dedicated user** - Not root
2. **Limit file permissions** - chmod 600 for key files
3. **Monitor processes** - Watch for anomalies
4. **Regular updates** - Keep software current
5. **Audit logs** - Review regularly

## Troubleshooting

### Script Issues

**Script not executable:**
```bash
chmod +x scripts/cli/*.sh
```

**Binary not found:**
```bash
# Build the binary
cargo build --release

# Or specify path
./node-start.sh --binary /path/to/ghost-node
```

**Permission denied:**
```bash
# Create directories with proper permissions
mkdir -p /var/lib/ghost-node
sudo chown $USER:$USER /var/lib/ghost-node
```

### RPC Connection Issues

**Connection refused:**
```bash
# Check if node is running
./node-status.sh

# Check RPC port
netstat -tlnp | grep 9944

# Verify firewall
sudo ufw status
```

**Timeout:**
```bash
# Check node health
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_health"}' \
  http://localhost:9944
```

### Process Management

**Node won't stop:**
```bash
# Use force flag
./node-stop.sh --name MyNode --force

# Or kill directly
pkill -9 ghost-node
```

**Multiple instances:**
```bash
# List all instances
pgrep -a ghost-node

# Stop specific PID
./node-stop.sh --pid 12345
```

## Systemd Integration

For production deployments, use systemd service:

```bash
# Copy service file
sudo cp ../../config/systemd/chainghost-node.service /etc/systemd/system/

# Enable and start
sudo systemctl enable chainghost-node
sudo systemctl start chainghost-node

# Check status
sudo systemctl status chainghost-node

# View logs
sudo journalctl -u chainghost-node -f
```

## Additional Resources

- [CLI Guide](../../docs/CLI_GUIDE.md) - Complete CLI documentation
- [Configuration Guide](../../CONFIGURATION.md) - Node configuration
- [Substrate Documentation](https://docs.substrate.io/) - Official docs
- [Polkadot Wiki](https://wiki.polkadot.network/) - Network information

## Contributing

To add new helper scripts:

1. Follow existing script structure
2. Add error handling
3. Include usage documentation
4. Add to this README
5. Make executable: `chmod +x script.sh`
6. Test thoroughly

## License

Same as ChainGhost node - see LICENSE file in repository root.
