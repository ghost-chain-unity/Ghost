# Ghost Protocol — Mono Repo

**Web3 Super-App: Execution, Identity & Community in One Ecosystem**

> **CRITICAL RULE:** NEVER INSTALL DEPENDENCIES IN ROOT  
> All dependencies must be installed in their respective `packages/*` directories.

---

## 🌟 Overview

Ghost Protocol is a revolutionary Web3 super-app ecosystem with integrated products:

```
┌─────────────────────────────────────────────┐
│          GHOST PROTOCOL ECOSYSTEM           │
├─────────────────────────────────────────────┤
│                                             │
│  1. ChainGhost                              │
│     → Unified Execution + Journey Layer     │
│     → One-click cross-chain transactions    │
│     → Auto-generated narrative visualization│
│     → Intent-based architecture             │
│     (Wallet operations + Story in ONE exp)  │
│                                             │
│  2. G3Mail (Ghost Web3 Mail)                │
│     → Decentralized Communication Product   │
│     → Encrypted messaging                   │
│     → On-chain message pointers             │
│     → Client-side decryption                │
│                                             │
│  3. Ghonity                                 │
│     → Community Ecosystem                   │
│     → Follow wallets, discover alpha        │
│     → Social graph & reputation             │
│     → Copy-trade strategies                 │
│                                             │
└─────────────────────────────────────────────┘
```

### Core Philosophy (Flywheel Effect)
```
ACTION (ChainGhost) → NARRATIVE (ChainGhost Story) → COMMUNITY (Ghonity)
        ↓                      ↓                            ↓
     "I DO"              "I BECOME"                     "WE ARE"
     
     More Action ← Community Discovery ← Shared Narratives
```

---

## 📁 Repository Structure

```
ghost-protocol/
├── packages/              # All application packages (mono-repo)
│   ├── backend/          # Backend services (NestJS, Node.js)
│   │   ├── api-gateway/
│   │   ├── indexer/
│   │   ├── rpc-orchestrator/
│   │   └── ai-engine/
│   ├── chain/            # Blockchain layer (Rust)
│   │   ├── node-core/
│   │   └── chain-cli/
│   ├── contracts/        # Smart contracts (Solidity/ink!)
│   │   ├── chaing-token/
│   │   └── marketplace/
│   ├── frontend/         # Frontend applications (Next.js, React)
│   │   ├── web/          # Main web app (ChainGhost + Ghonity)
│   │   ├── admin/        # Admin dashboard
│   │   └── components/   # Shared component library
│   └── tooling/          # Development tools
│       ├── scripts/
│       └── devcontainers/
│
├── infra/                # Infrastructure as Code
│   ├── terraform/        # Cloud infrastructure
│   ├── k8s/              # Kubernetes manifests
│   └── runbooks/         # Operational procedures
│
├── docs/                 # Documentation
│   ├── adr/              # Architecture Decision Records
│   ├── roadmap.md        # Development roadmap
│   ├── arsitektur.md     # System architecture
│   └── design-guide.md   # UI/UX design guide
│
├── .github/              # GitHub configuration
│   └── workflows/        # CI/CD pipelines
│
├── agent-rules.md        # Development guidelines (READ FIRST)
├── reference-file.md     # File structure reference
├── roadmap-tasks.md      # Comprehensive task breakdown
└── README.md             # This file
```

---

## 🚀 Quick Start

### Prerequisites
- Node.js 20 LTS
- **pnpm 8.15+** (REQUIRED - not npm)
- Rust (for blockchain layer)
- Docker Desktop (for local development)

### Local Development Setup (Docker Compose)

**Step 1: Start Docker Services**

```bash
# Start all development services (PostgreSQL, Dragonfly, Elasticsearch, pgAdmin)
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Reset all data (delete volumes)
docker-compose down -v
```

> **Note:** Docker Compose includes Dragonfly (Redis-compatible cache layer) instead of Redis for hybrid caching strategy. See [CACHING_STORAGE_STRATEGY.md](./CACHING_STORAGE_STRATEGY.md) for details.

**Services Running:**
- PostgreSQL: `localhost:5432` (dev) / `localhost:5433` (test)
- Dragonfly (RPC Cache): `localhost:6379` (Redis-compatible)
- Elasticsearch: `localhost:9200` (optional)
- pgAdmin: `localhost:5050` (admin@ghostprotocol.io / development)

### Installation

**⚠️ CRITICAL: Install dependencies ONLY in package directories, NEVER in root!**

```bash
# CRITICAL: Use pnpm, NOT npm!

# Step 2: Install Frontend Dependencies
cd packages/frontend/web
pnpm install

# Copy environment variables
cp .env.example .env
# Edit .env with your configuration

# Start frontend dev server
pnpm run dev             # http://0.0.0.0:5000

# Step 3: Install Backend Dependencies (when needed)
cd packages/backend/api-gateway
pnpm install

# Copy environment variables
cp .env.example .env
# Edit .env with your configuration

# Run database migrations
pnpx prisma migrate dev

# Start backend dev server
pnpm run dev             # http://localhost:4000
```

### Development

```bash
# Run specific package (use pnpm filter from root)
pnpm --filter [package-name] dev

# Or cd into package
cd packages/[package-name]
pnpm run dev

# Run tests
pnpm test

# Build for production
pnpm run build
```

---

## 📚 Documentation

### Essential Reading (in order)
1. **[agent-rules.md](./agent-rules.md)** - Development guidelines and CoT framework (READ FIRST)
2. **[reference-file.md](./reference-file.md)** - File structure and dependencies
3. **[roadmap-tasks.md](./roadmap-tasks.md)** - Complete task breakdown
4. **[docs/roadmap.md](./docs/roadmap.md)** - Development roadmap (Phases 0-5)
5. **[docs/arsitektur.md](./docs/arsitektur.md)** - System architecture
6. **[docs/design-guide.md](./docs/design-guide.md)** - UI/UX guidelines

### Architecture Decision Records (ADRs)
All major architectural decisions are documented in `docs/adr/`. See [ADR README](./docs/adr/README.md) for guidelines.

---

## 🛠️ Tech Stack

### Frontend
- **Framework:** Next.js 14, React 18
- **UI Library:** Hero UI, Tailwind CSS
- **3D Graphics:** Three.js, @react-three/fiber, Spline
- **Animation:** GSAP, Framer Motion
- **State Management:** Zustand, React Context

### Backend
- **Framework:** NestJS 10
- **Runtime:** Node.js 20
- **Database:** PostgreSQL 15 + TimescaleDB (time-series)
- **ORM:** Prisma
- **Caching Strategy (Hybrid):**
  - **RPC Calls:** Dragonfly (Redis-compatible, opensource alternative)
  - **Event Indexing:** DuckDB / LMDB (high-performance analytics)
  - **Decentralized Storage:** IPFS (messages, metadata)
  - **Rate Limiting:** PostgreSQL (Guards & Middleware)
- **Search:** Elasticsearch (optional)
- **Message Queue:** Bull (PostgreSQL-based alternative to Redis)
- **API:** RESTful + GraphQL
- **AI/ML:** Hugging Face Inference API, LLM orchestration

### Blockchain
- **Layer:** Custom Substrate-based chain (Rust)
- **Smart Contracts:** Solidity, ink! (WASM)
- **Account Abstraction:** ERC-4337
- **Multi-chain:** Ethereum, BSC, Polygon, Arbitrum, Base

### Infrastructure
- **Containerization:** Docker, Kubernetes
- **IaC:** Terraform
- **CI/CD:** GitHub Actions
- **Monitoring:** Prometheus, Grafana, Loki
- **Secrets:** Vault, KMS

---

## 🔒 Critical Rules

### 1. NEVER INSTALL DEPENDENCIES IN ROOT
```bash
❌ WRONG: pnpm install <package>  # at root without -w flag
❌ WRONG: npm install <package>   # NEVER use npm, use pnpm!
✅ RIGHT: cd packages/frontend/web && pnpm install <package>
✅ RIGHT: pnpm --filter frontend-web add <package>
```

### 2. NO EMOJI IN CODE
```javascript
❌ WRONG: const status = "✅ Success"
✅ RIGHT: import { CheckIcon } from '@heroicons/react'
```

### 3. Architecture Decision Records (ADRs)
All architectural decisions MUST be documented in `docs/adr/` before implementation.

### 4. Security First
- Secrets in Vault/KMS (never in code)
- All PRs require security review
- Third-party audit for smart contracts

### 5. Testing Standards
- Backend: >80% coverage
- Frontend: >70% coverage
- Smart Contracts: >95% coverage

---

## 🗺️ Roadmap

### Phase 0 — Foundations (Current)
- ✅ Phase 0.1: Documentation setup (Completed Nov 15, 2025)
  - ✅ All 4 ADRs created and accepted
  - ✅ Mono-repo structure with pnpm workspace
  - ✅ Complete documentation framework
- ✅ Phase 0.2: Development Environment (Completed)
  - ✅ Docker Compose configuration (PostgreSQL, Dragonfly, Elasticsearch, pgAdmin)
  - ✅ Hybrid caching strategy (Dragonfly RPC, DuckDB/LMDB indexing, IPFS storage)
  - ✅ DevContainers for VS Code
  - ✅ ESLint & Prettier for Frontend (with emoji detection)
  - ✅ ESLint & Prettier for Backend (NestJS)
  - ✅ Husky pre-commit hooks
- 📋 Phase 0.3: CI/CD pipelines
- 📋 Phase 0.4: Infrastructure setup

### Phase 1 — Core Backend & ChainG Testnet
- Backend services (API Gateway, Indexer)
- Blockchain node prototype
- Testnet deployment

### Phase 2 — Tokens & Smart Contracts
- ChainG token
- Staking & governance
- NFT primitives

### Phase 3 — G3Mail & AI Engine
- G3Mail (Ghost Web3 Mail product)
- AI story generation for ChainGhost
- Ghonity social graph backend

### Phase 4 — Frontend Core
- ChainGhost (Unified wallet + journey visualization)
- Ghonity (Community feed & social interactions)
- Marketplace MVP

### Phase 5 — Community & Launch
- Ghost Hunter game
- Telegram integration
- Mainnet launch

See [docs/roadmap.md](./docs/roadmap.md) for detailed breakdown.

---

## 🤝 Contributing

1. Read [agent-rules.md](./agent-rules.md) thoroughly
2. Create ADR for architectural changes
3. Follow mono-repo structure (no root dependencies!)
4. Write tests (follow coverage requirements)
5. Submit PR with proper commit format (Conventional Commits)
6. Await code review + security review (if applicable)

### Commit Format
```
feat: Add ChainGhost narrative generation API
fix: Resolve wallet balance calculation bug
docs: Update architecture documentation
test: Add integration tests for indexer
```

---

## 📊 Project Status

### ✅ Implemented
- Frontend basic structure (Next.js on port 5000)
- Documentation framework
- Mono-repo skeleton

### 📋 Planned
- Backend services
- Blockchain layer
- Smart contracts
- Infrastructure automation

---

## 📧 Contact & Support

- **Documentation:** See `docs/` directory
- **Issues:** GitHub Issues
- **Discussions:** GitHub Discussions
- **Security:** See SECURITY.md (coming soon)

---

## 📄 License

[To be determined]

---

**Last Updated:** November 23, 2025  
**Maintained by:** Ghost Protocol Development Team

---

## 📖 Additional Resources

- **[CACHING_STORAGE_STRATEGY.md](./CACHING_STORAGE_STRATEGY.md)** - Hybrid caching & storage architecture (Dragonfly, DuckDB, LMDB, IPFS)
- **[roadmap-tasks.md](./roadmap-tasks.md)** - Detailed task breakdown with deferred items tracking
- **[docs/adr/](./docs/adr/)** - Architecture Decision Records (all major decisions)
