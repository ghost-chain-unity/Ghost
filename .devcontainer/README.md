# Ghost Protocol - DevContainer Configurations

This directory contains VS Code DevContainer configurations for different development workflows in the Ghost Protocol mono-repo.

## Available DevContainers

### 1. **Root DevContainer** (`.devcontainer/devcontainer.json`)
**Use for:** Full-stack development (Frontend + Backend)

**Includes:**
- Node.js 20 LTS
- Rust toolchain
- Docker-in-Docker
- PostgreSQL, Redis, Elasticsearch (via docker-compose)

**Best for:**
- Working across multiple packages
- Full-stack features (frontend + backend + contracts)
- General development

**How to use:**
1. Open root folder in VS Code
2. Press `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
3. Wait for container setup (~5-10 minutes first time)

---

### 2. **Contracts DevContainer** (`.devcontainer/contracts/devcontainer.json`)
**Use for:** Smart contract development (Solidity)

**Includes:**
- Node.js 20 LTS
- Python 3.11 (for Slither)
- Hardhat
- Slither (static analyzer)
- solc-select (Solidity compiler manager)
- Foundry (optional)

**Best for:**
- Writing and testing smart contracts
- Running Hardhat tasks
- Security analysis with Slither
- Gas optimization

**How to use:**
1. Open `.devcontainer/contracts/devcontainer.json` in VS Code
2. Press `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
3. Navigate to `packages/contracts/chaing-token`
4. Run `pnpm install` and `pnpm hardhat compile`

**Ports exposed:**
- `8545` - Hardhat local node

---

### 3. **Chain DevContainer** (`.devcontainer/chain/devcontainer.json`)
**Use for:** Blockchain node development (Rust)

**Includes:**
- Rust stable toolchain
- wasm32-unknown-unknown target (for WASM smart contracts)
- protoc (Protocol Buffers compiler)
- cargo tools (watch, expand, edit)
- LLDB debugger
- subkey (Substrate key management)

**Best for:**
- Building the blockchain node
- Writing Rust pallets
- WASM smart contract development (ink!)
- Node testing and debugging

**How to use:**
1. Open `.devcontainer/chain/devcontainer.json` in VS Code
2. Press `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
3. Navigate to `packages/chain/node-core`
4. Run `cargo build --release`

**Ports exposed:**
- `9933` - HTTP RPC endpoint
- `9944` - WebSocket RPC endpoint
- `30333` - P2P networking

---

## Setup Instructions

### First-Time Setup

1. **Install Prerequisites:**
   - Docker Desktop (or Docker Engine + Docker Compose)
   - VS Code
   - VS Code extension: "Dev Containers" (ms-vscode-remote.remote-containers)

2. **Choose Your DevContainer:**
   - **Full-stack:** Use root `.devcontainer/devcontainer.json`
   - **Smart contracts only:** Use `.devcontainer/contracts/devcontainer.json`
   - **Blockchain node only:** Use `.devcontainer/chain/devcontainer.json`

3. **Open in Container:**
   ```
   VS Code → File → Open Folder → Select repository root
   VS Code → Command Palette (Ctrl+Shift+P) → "Dev Containers: Reopen in Container"
   ```

4. **Wait for Setup:**
   - First build takes 5-15 minutes (downloads images, installs tools)
   - Subsequent opens are instant (uses cached images)

### Switching Between DevContainers

If you need to switch between different DevContainer configs:

1. Close VS Code
2. Delete `.devcontainer/.devcontainer` folder (if exists)
3. Open the DevContainer config you want (e.g., `.devcontainer/contracts/devcontainer.json`)
4. Reopen in container

**OR** use multiple VS Code windows:
- Window 1: Root DevContainer (full-stack)
- Window 2: Contracts DevContainer (smart contracts)
- Window 3: Chain DevContainer (blockchain node)

---

## Troubleshooting

### Container Build Fails

**Problem:** Docker build fails during DevContainer setup

**Solutions:**
```bash
# 1. Clean Docker cache
docker system prune -a

# 2. Restart Docker Desktop

# 3. Increase Docker resources
# Docker Desktop → Settings → Resources
# - CPUs: 4+
# - Memory: 8GB+
# - Swap: 2GB+
```

### Ports Already in Use

**Problem:** "Port 5432 already in use"

**Solution:**
```bash
# Stop local PostgreSQL
brew services stop postgresql  # macOS
sudo systemctl stop postgresql # Linux

# Or change port in docker-compose.yml
```

### Setup Script Fails

**Problem:** `setup.sh` script fails during postCreateCommand

**Solution:**
```bash
# Manually run setup inside container
bash .devcontainer/contracts/setup.sh
```

### Rust Target Missing (Chain DevContainer)

**Problem:** `wasm32-unknown-unknown` target not installed

**Solution:**
```bash
rustup target add wasm32-unknown-unknown
```

---

## Performance Tips

1. **Use Volume Mounts for Dependencies:**
   - Node modules are stored in Docker volumes (faster)
   - Cargo cache is mounted from host (`~/.cargo`)

2. **Enable File Watching:**
   ```bash
   # Frontend hot reload
   cd packages/frontend/web && pnpm dev

   # Backend hot reload
   cd packages/backend/api-gateway && pnpm dev

   # Rust hot reload
   cd packages/chain/node-core && cargo watch -x build
   ```

3. **Use Docker BuildKit:**
   ```bash
   export DOCKER_BUILDKIT=1
   export COMPOSE_DOCKER_CLI_BUILD=1
   ```

---

## VS Code Extensions (Auto-Installed)

### Root DevContainer
- ESLint, Prettier
- Tailwind CSS IntelliSense
- Prisma
- Rust Analyzer
- Docker
- GitLens

### Contracts DevContainer
- Solidity (Juan Blanco)
- Hardhat Solidity (Nomic Foundation)
- Solidity Visual Auditor
- ESLint, Prettier

### Chain DevContainer
- Rust Analyzer
- LLDB Debugger
- Crates (crate management)
- Even Better TOML

---

## Common Workflows

### Full-Stack Development
```bash
# Use Root DevContainer
code . && reopen in container

# Terminal 1: Frontend
cd packages/frontend/web && pnpm dev

# Terminal 2: Backend
cd packages/backend/api-gateway && pnpm dev

# Terminal 3: Services
docker-compose up -d
```

### Smart Contract Development
```bash
# Use Contracts DevContainer
code .devcontainer/contracts/devcontainer.json && reopen in container

# Compile contracts
cd packages/contracts/chaing-token
pnpm hardhat compile

# Run tests
pnpm hardhat test

# Run security analysis
slither contracts/

# Deploy to local network
pnpm hardhat node  # Terminal 1
pnpm hardhat run scripts/deploy.ts --network localhost  # Terminal 2
```

### Blockchain Node Development
```bash
# Use Chain DevContainer
code .devcontainer/chain/devcontainer.json && reopen in container

# Build node
cd packages/chain/node-core
cargo build --release

# Run tests
cargo test

# Run node
./target/release/ghost-node --dev
```

---

## Security Notes

1. **SSH Keys:** Mounted read-only from host (`~/.ssh`)
2. **Secrets:** Never commit `.env` files - use `.env.example` as template
3. **Docker Socket:** Mounted for Docker-in-Docker (required for builds)
4. **Network:** Containers share network with host (required for service access)

---

## Support

For issues or questions:
1. Check this README
2. Review ADR-004 (Development Environment Setup)
3. Ask in team Slack channel
4. Open GitHub issue with `devcontainer` label

---

**Last Updated:** November 15, 2025  
**Maintained by:** Agent Backend
