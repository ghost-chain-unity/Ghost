# ADR-004: Development Environment Setup

**Date:** 2025-11-15  
**Status:** Accepted  
**Accepted Date:** 2025-11-15  
**Deciders:** Agent Frontend, Agent Backend, Agent Blockchain  
**Technical Story:** Phase 0.2 - Local Development Experience  
**Relates to:** ADR-001 (Tech Stack), ADR-002 (Mono-Repo)

---

## Context and Problem Statement

Developers need a consistent, reproducible development environment that:
- Works across different operating systems (macOS, Linux, Windows)
- Includes all required services (PostgreSQL, Dragonfly, DuckDB/LMDB, Elasticsearch, IPFS)
- Supports hot reloading and fast iteration
- Minimizes setup time (<30 minutes from clone to running)
- Matches production environment closely

**Question:** What development environment setup should we use? Docker Compose? DevContainers? Local installation?

## Decision Drivers

- **Consistency:** Same environment across all developers
- **Setup Speed:** <30 minutes from git clone to running app
- **Iteration Speed:** <3 seconds for hot reload
- **OS Support:** Works on macOS, Linux, Windows
- **Production Parity:** Environment matches staging/production
- **Resource Usage:** Reasonable CPU/memory for development machines
- **Debugging:** Easy to attach debuggers, inspect databases

## Considered Options

1. **Docker Compose + Local Development**
2. **DevContainers (VS Code Remote Containers)**
3. **Local Installation (PostgreSQL, Redis, etc.)**
4. **Vagrant**
5. **Nix/NixOS**

## Decision Outcome

**Chosen option:** "Docker Compose for services + Local Development for code", because:
- Services in Docker (PostgreSQL, Redis) ensure consistency
- Code runs locally (faster hot reload, easier debugging)
- Works across all OS (Docker Desktop available everywhere)
- Easy to add/remove services (edit docker-compose.yml)
- Production parity (same Docker images used in Kubernetes)

**Optional:** DevContainers for contributors who prefer fully containerized development.

### Docker Compose Setup

**File:** `docker-compose.yml` (root)

```yaml
version: '3.9'

services:
  postgres:
    image: postgres:15-alpine
    container_name: ghost-postgres
    environment:
      POSTGRES_USER: ghost
      POSTGRES_PASSWORD: development
      POSTGRES_DB: ghost_dev
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ghost"]
      interval: 10s
      timeout: 5s
      retries: 5
  
  postgres-test:
    image: postgres:15-alpine
    container_name: ghost-postgres-test
    environment:
      POSTGRES_USER: ghost
      POSTGRES_PASSWORD: test
      POSTGRES_DB: ghost_test
    ports:
      - "5433:5432"
    tmpfs:
      - /var/lib/postgresql/data
  
  dragonfly:
    image: docker.io/easystack/dragonfly:latest
    container_name: ghost-dragonfly
    ports:
      - "6379:6379"
    volumes:
      - dragonfly-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    # Dragonfly is a Redis-compatible, opensource alternative
    # Used for RPC response caching and distributed cache layer
  
  ipfs:
    image: ipfs/kubo:latest
    container_name: ghost-ipfs
    ports:
      - "5001:5001"  # API port
      - "8080:8080"  # Gateway port
    volumes:
      - ipfs-data:/data/ipfs
    environment:
      - IPFS_PATH=/data/ipfs
    # IPFS for decentralized content storage (messages, data)
  
  elasticsearch:
    image: elasticsearch:8.11.0
    container_name: ghost-elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9200/_cluster/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
  
  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: ghost-pgadmin
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@ghostprotocol.io
      PGADMIN_DEFAULT_PASSWORD: development
    ports:
      - "5050:80"
    volumes:
      - pgadmin-data:/var/lib/pgadmin
    depends_on:
      postgres:
        condition: service_healthy

volumes:
  postgres-data:
  dragonfly-data:
  elasticsearch-data:
  pgadmin-data:
  ipfs-data:
```

**Usage:**
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f postgres

# Stop all services
docker-compose down

# Reset data (delete volumes)
docker-compose down -v
```

### Local Development Setup

**Prerequisites:**
- Node.js 20 LTS
- pnpm 8.15+
- Rust (for blockchain components)
- Docker Desktop
- VS Code (recommended)

**Setup Steps:**

```bash
# 1. Clone repository
git clone https://github.com/ghostprotocol/ghost-protocol.git
cd ghost-protocol

# 2. Start services
docker-compose up -d

# 3. Install frontend dependencies
cd packages/frontend/web
pnpm install

# 4. Run database migrations
pnpx prisma migrate dev

# 5. Start frontend dev server
pnpm run dev
# → http://localhost:5000

# 6. In new terminal: Start backend
cd packages/backend/api-gateway
pnpm install
pnpm run dev
# → http://localhost:4000
```

**Total Time:** ~15-20 minutes (depending on pnpm install speed)

### DevContainer Setup (Optional)

**File:** `.devcontainer/devcontainer.json`

```json
{
  "name": "Ghost Protocol",
  "dockerComposeFile": "../docker-compose.yml",
  "service": "devcontainer",
  "workspaceFolder": "/workspace",
  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "version": "20"
    },
    "ghcr.io/devcontainers/features/rust:1": {
      "version": "latest"
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode",
        "bradlc.vscode-tailwindcss",
        "prisma.prisma",
        "rust-lang.rust-analyzer"
      ]
    }
  },
  "postCreateCommand": "pnpm install",
  "remoteUser": "node"
}
```

**Benefits:**
- Fully reproducible environment
- All dependencies pre-installed
- VS Code extensions auto-installed
- No local setup required (beyond Docker + VS Code)

### Environment Variables

**File:** `packages/backend/api-gateway/.env.example`

```env
# Database
DATABASE_URL=postgresql://ghost:development@localhost:5432/ghost_dev
DATABASE_URL_TEST=postgresql://ghost:test@localhost:5433/ghost_test

# Dragonfly (Redis-compatible cache)
DRAGONFLY_URL=redis://localhost:6379
# Or for direct usage
REDIS_URL=redis://localhost:6379  # Dragonfly is Redis-compatible

# IPFS for decentralized storage
IPFS_API_URL=http://localhost:5001
IPFS_GATEWAY_URL=http://localhost:8080

# Elasticsearch (optional)
ELASTICSEARCH_URL=http://localhost:9200

# JWT
JWT_SECRET=your-secret-key-here
JWT_EXPIRES_IN=7d

# Server
PORT=4000
NODE_ENV=development

# External APIs
HUGGINGFACE_API_KEY=your-key-here
```

**Setup:**
```bash
# Copy example to .env
cp .env.example .env

# Edit .env with your values
```

### Positive Consequences

- **Fast Setup:** Docker Compose starts all services in 30 seconds
- **Consistency:** Same PostgreSQL, Dragonfly, IPFS versions across all developers
- **Production Parity:** Docker images match production
- **Easy Reset:** `docker-compose down -v` resets all data
- **Database GUI:** pgAdmin included for database inspection
- **Hot Reload:** Code runs locally (fast iteration)
- **Easy Debugging:** Attach Node.js debugger, inspect databases
- **Cross-Platform:** Works on macOS, Linux, Windows

### Negative Consequences

- **Docker Dependency:** Requires Docker Desktop (paid for large teams)
  - **Mitigation:** Can use Podman or local PostgreSQL/Redis
- **Resource Usage:** Docker services use ~2GB RAM
  - **Mitigation:** Lightweight Alpine images, can stop when not needed
- **Windows Limitations:** File watching slower on Windows + Docker
  - **Mitigation:** Use DevContainers or WSL2
- **Initial Download:** Docker images ~1GB first time
  - **Mitigation:** One-time cost, cached afterward

## Pros and Cons of the Options

### Docker Compose + Local Development

**Pros:**
- Best of both worlds (services containerized, code local)
- Fast hot reload (code runs on host)
- Easy debugging (Node.js inspector, browser DevTools)
- Production parity (same Docker images)
- Easy to add services (edit YAML)

**Cons:**
- Requires Docker Desktop
- Services in containers, code on host (slight complexity)
- Need to manage .env files

**Why chosen:** Best balance of speed, consistency, and debugging.

---

### DevContainers (Full Container)

**Pros:**
- Fully reproducible (everything in container)
- No local setup (beyond Docker + VS Code)
- Extensions auto-installed
- Consistent across all developers

**Cons:**
- Slower file watching (container <-> host sync)
- Higher resource usage (full dev environment in container)
- Requires VS Code (editor lock-in)
- Debugging slightly more complex

**Decision:** Provide as option, not default.

---

### Local Installation

**Pros:**
- No Docker dependency
- Fastest possible iteration
- Simplest debugging

**Cons:**
- Inconsistent across developers (different PostgreSQL versions)
- Hard to reset (manual database drops)
- OS-specific setup (brew vs apt vs choco)
- No production parity

**Why not:** Inconsistency outweighs speed benefits.

---

### Vagrant

**Pros:**
- Full VM (complete isolation)
- Reproducible

**Cons:**
- Very slow (VM overhead)
- Large resource usage (4-8GB RAM)
- Slower than containers
- Outdated approach (containers replaced VMs)

**Why not:** Containers are faster and more modern.

---

### Nix/NixOS

**Pros:**
- Declarative, reproducible
- No Docker needed
- Fast

**Cons:**
- Steep learning curve
- Small ecosystem (vs Docker)
- Harder to debug
- Not widely adopted

**Why not:** Team familiarity with Docker > Nix benefits.

---

## Links

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [DevContainers Specification](https://containers.dev/)
- [PostgreSQL Docker Image](https://hub.docker.com/_/postgres)
- [pgAdmin Documentation](https://www.pgadmin.org/docs/)

## Notes

### Troubleshooting

**Problem:** Port 5432 already in use
```bash
# Solution 1: Stop local PostgreSQL
brew services stop postgresql

# Solution 2: Change port in docker-compose.yml
ports:
  - "5433:5432"
```

**Problem:** Hot reload not working
```bash
# Solution: Restart dev server
# Next.js/NestJS usually auto-reloads
```

**Problem:** Database migrations fail
```bash
# Solution: Reset database
docker-compose down -v
docker-compose up -d
cd packages/backend/api-gateway
pnpx prisma migrate dev
```

### VS Code Extensions (Recommended)

```json
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "bradlc.vscode-tailwindcss",
    "prisma.prisma",
    "rust-lang.rust-analyzer",
    "ms-azuretools.vscode-docker",
    "github.copilot",
    "eamodio.gitlens"
  ]
}
```

### Performance Tuning

**macOS:**
- Increase Docker Desktop resources (Settings → Resources)
  - CPUs: 4
  - Memory: 8GB
  - Swap: 2GB

**Windows:**
- Use WSL2 backend (faster file watching)
- Enable WSL2 integration (Settings → Resources → WSL Integration)

**Linux:**
- Native Docker (best performance)
- No special configuration needed

### Database Migrations Workflow

```bash
# Create migration
cd packages/backend/api-gateway
pnpx prisma migrate dev --name add_user_table

# Apply migrations
pnpx prisma migrate deploy

# Reset database (development only)
pnpx prisma migrate reset
```

### Testing Environment

**Test Database:** Separate PostgreSQL container (port 5433)
```bash
# Tests automatically use TEST_DATABASE_URL
pnpm test
```

**Why separate:** Avoid polluting dev database with test data.

---

**Review Date:** 2025-12-15  
**Next Review:** After feedback from 3+ developers or if setup issues arise
