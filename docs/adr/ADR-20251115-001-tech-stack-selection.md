# ADR-001: Tech Stack Selection

**Date:** 2025-11-15  
**Status:** Accepted  
**Accepted Date:** 2025-11-15  
**Deciders:** Agent Frontend, Agent Backend, Agent Blockchain  
**Technical Story:** Phase 0.1 - Foundational Architecture

---

## Context and Problem Statement

Ghost Protocol is a Web3 super-app with an integrated ecosystem consisting of:
- **ChainGhost**: Unified execution + journey visualization layer (wallet operations + story narrative in one experience)
- **G3Mail (Ghost Web3 Mail)**: Decentralized communication product
- **Ghonity**: Community ecosystem for social interaction and discovery

We need to select a technology stack that supports:
- High-performance blockchain operations
- Real-time data streaming and updates
- AI/ML story generation
- 3D visualization (holograms)
- Multi-chain compatibility
- Scalable architecture

**Question:** What technology stack should we use for frontend, backend, blockchain, and infrastructure?

## Decision Drivers

- **Performance:** Sub-200ms API response times, smooth 3D rendering (60fps)
- **Developer Experience:** Fast iteration, good tooling, active community
- **Scalability:** Handle 100K+ users, 1M+ transactions/day
- **Security:** Battle-tested frameworks, regular security updates
- **Ecosystem:** Rich library ecosystem, blockchain integrations
- **Cost:** Development velocity vs infrastructure costs
- **Maintainability:** Long-term support, easy onboarding

## Considered Options

### Frontend Options

1. **Next.js 14 + React 18 + TypeScript**
2. Remix + React + TypeScript
3. SvelteKit + Svelte + TypeScript

### Backend Options

1. **NestJS 10 + Node.js 20 + TypeScript**
2. Express.js + Node.js + TypeScript
3. Go + Gin framework
4. Python + FastAPI

### Blockchain Options

1. **Substrate (Rust) + ink! smart contracts**
2. Ethereum fork + Solidity
3. Cosmos SDK + Go

### Database Options

1. **PostgreSQL + Prisma ORM**
2. MongoDB + Mongoose
3. PostgreSQL + TypeORM

### Infrastructure Options

1. **Kubernetes + Terraform + Docker**
2. AWS ECS + CloudFormation
3. Railway / Vercel (managed platforms)

## Decision Outcome

**Chosen stack:**

### Frontend
- **Framework:** Next.js 14 (App Router)
- **UI Library:** React 18 (functional components, hooks)
- **Language:** TypeScript
- **UI Components:** Hero UI + Tailwind CSS
- **3D Graphics:** Three.js + @react-three/fiber + Spline
- **Animation:** GSAP + Framer Motion
- **State Management:** Zustand + React Query
- **Wallet Integration:** wagmi + viem

**Justification:**
- Next.js provides excellent SEO, SSR, and performance optimizations
- React ecosystem is mature with extensive 3D/blockchain libraries
- TypeScript ensures type safety for complex Web3 interactions
- Hero UI + Tailwind enable rapid, accessible UI development
- Three.js is industry standard for WebGL/3D

### Backend
- **Framework:** NestJS 10
- **Runtime:** Node.js 20 LTS
- **Language:** TypeScript
- **Database:** PostgreSQL 15 + TimescaleDB (time-series)
- **ORM:** Prisma
- **Caching Strategy (Hybrid):**
  - **RPC Call Cache:** Dragonfly (Redis-compatible, opensource alternative) for distributed caching
  - **Event Indexing:** DuckDB or LMDB for high-performance event storage and analytics
  - **Rate Limiting:** PostgreSQL-based (via API Gateway Guards/Middleware)
  - **Session State:** PostgreSQL (primary), Dragonfly (cache layer)
- **Node Storage:** IPFS for decentralized content storage
- **Search:** Elasticsearch (optional)
- **Message Queue:** Bull or AMQP-based (with Dragonfly for pub/sub)
- **AI/ML:** Hugging Face Inference API + Python microservice

**Justification:**
- NestJS provides enterprise-grade architecture (modules, DI, guards)
- TypeScript enables code sharing with frontend (types, interfaces)
- PostgreSQL is ACID-compliant, supports JSON, and has excellent tooling
- Prisma offers type-safe database access and migrations
- Node.js enables JavaScript/TypeScript monorepo
- Dragonfly (opensource Redis-compatible) eliminates vendor lock-in
- DuckDB/LMDB provide high-performance event indexing for analytics
- IPFS enables decentralized, censorship-resistant content storage

### Blockchain
- **Node:** Custom Substrate-based chain (Rust)
- **Consensus:** Aura/GRANDPA (testnet), NPoS (mainnet)
- **Smart Contracts:** ink! (WASM) + Solidity (EVM pallet)
- **RPC:** Custom JSON-RPC (eth_* compatible)
- **Multi-chain:** EVM-compatible chains (Ethereum, BSC, Polygon, Arbitrum, Base)

**Justification:**
- Substrate provides customizable blockchain framework
- ink! enables efficient WASM smart contracts
- EVM pallet allows Solidity contracts (wider ecosystem)
- Multi-chain support via standardized RPC

### Infrastructure
- **Orchestration:** Kubernetes
- **IaC:** Terraform
- **Containers:** Docker
- **CI/CD:** GitHub Actions
- **Monitoring:** Prometheus + Grafana + Loki
- **Secrets:** HashiCorp Vault
- **CDN:** Cloudflare

**Justification:**
- Kubernetes enables declarative, scalable deployments
- Terraform ensures reproducible infrastructure
- GitHub Actions integrates with repository
- Prometheus/Grafana are industry standards

### Positive Consequences

- **Unified Language:** TypeScript across frontend/backend enables code sharing
- **Type Safety:** Reduces runtime errors, improves developer experience
- **Rich Ecosystem:** Extensive libraries for Web3, 3D, AI
- **Performance:** Next.js + NestJS both optimized for speed
- **Scalability:** Kubernetes + microservices enable horizontal scaling
- **Security:** All frameworks have active security teams
- **Developer Experience:** Excellent tooling (VS Code, Prisma Studio, Grafana)

### Negative Consequences

- **Learning Curve:** Substrate/Rust requires blockchain expertise
- **Complexity:** Multiple technologies (TypeScript, Rust, Python) increase cognitive load
- **Infrastructure Costs:** Kubernetes requires DevOps expertise
- **3D Performance:** Three.js can be heavy on low-end devices (needs optimization)
- **AI Costs:** LLM API calls can be expensive (need caching/batching)

## Pros and Cons of the Options

### Frontend: Next.js vs Remix vs SvelteKit

#### Next.js 14
**Pros:**
- Mature ecosystem, battle-tested
- Excellent performance optimizations (ISR, SSR, SSG)
- Great TypeScript support
- Large community, extensive tutorials
- Vercel deployment (optional)

**Cons:**
- App Router is relatively new (learning curve)
- Can be complex for simple use cases
- Vercel lock-in concerns (mitigated by self-hosting)

#### Remix
**Pros:**
- Progressive enhancement focus
- Excellent form handling
- Simpler mental model (no SSR/SSG confusion)

**Cons:**
- Smaller ecosystem
- Less mature than Next.js
- Fewer 3D/blockchain examples

#### SvelteKit
**Pros:**
- Best performance (compiled framework)
- Smallest bundle sizes
- Great developer experience

**Cons:**
- Smaller ecosystem (fewer Web3 libraries)
- Less TypeScript maturity
- Fewer blockchain integration examples

**Why Next.js:** Proven for Web3 apps, rich ecosystem, excellent TypeScript support.

---

### Backend: NestJS vs Express vs Go vs Python

#### NestJS
**Pros:**
- Enterprise architecture (modules, DI, guards)
- Excellent TypeScript support
- Built-in validation, pipes, interceptors
- OpenAPI/Swagger integration
- Microservices support

**Cons:**
- More opinionated than Express
- Steeper learning curve
- Slightly more boilerplate

#### Express.js
**Pros:**
- Minimal, flexible
- Huge ecosystem
- Fast to prototype

**Cons:**
- No built-in structure (need to design architecture)
- Manual TypeScript configuration
- Less enterprise-ready out of box

#### Go (Gin)
**Pros:**
- Best raw performance
- Compiled, type-safe
- Great concurrency

**Cons:**
- Cannot share types with TypeScript frontend
- Smaller Web3 ecosystem
- Team needs to learn Go

#### Python (FastAPI)
**Pros:**
- Best for AI/ML (native libraries)
- Fast to prototype
- Great async support

**Cons:**
- Dynamic typing (vs TypeScript)
- Slower than Node.js/Go
- Cannot share types with frontend

**Why NestJS:** Best balance of structure, TypeScript, and ecosystem for Web3.

---

### Blockchain: Substrate vs Ethereum Fork vs Cosmos

#### Substrate (Rust)
**Pros:**
- Highly customizable
- Excellent performance
- WASM smart contracts (efficient)
- Built-in upgradability
- Polkadot ecosystem

**Cons:**
- Steeper learning curve (Rust)
- Smaller community vs Ethereum
- Fewer tools and examples

#### Ethereum Fork
**Pros:**
- Largest ecosystem
- Solidity developers abundant
- Extensive tooling (Hardhat, Foundry)

**Cons:**
- Less customizable (EVM constraints)
- Gas costs can be high
- Harder to optimize

#### Cosmos SDK (Go)
**Pros:**
- IBC (cross-chain communication)
- Tendermint consensus (fast)
- Growing ecosystem

**Cons:**
- Smaller ecosystem than Ethereum
- Fewer Web3 integrations
- Team needs to learn Go

**Why Substrate:** Customizability + efficiency + WASM + EVM compatibility via pallet.

---

### Database: PostgreSQL vs MongoDB

#### PostgreSQL + Prisma
**Pros:**
- ACID compliance (critical for financial data)
- Excellent query performance
- JSON support (flexible schema)
- Rich extensions (PostGIS, TimescaleDB)
- Prisma provides type-safe ORM

**Cons:**
- Schema migrations required
- Horizontal scaling more complex

#### MongoDB + Mongoose
**Pros:**
- Flexible schema
- Horizontal scaling (sharding)
- Fast for unstructured data

**Cons:**
- No ACID by default (eventual consistency)
- Less efficient for relational data
- Weaker type safety vs Prisma

**Why PostgreSQL:** ACID compliance is critical for blockchain/financial data.

---

## Links

- [Next.js Documentation](https://nextjs.org/docs)
- [NestJS Documentation](https://docs.nestjs.com/)
- [Substrate Documentation](https://docs.substrate.io/)
- [Prisma Documentation](https://www.prisma.io/docs)
- [Three.js Documentation](https://threejs.org/docs/)

## Notes

### Future Considerations

- **AI Microservice:** May extract Python FastAPI service for LLM orchestration (better ML library support)
- **Database Scaling:** Consider read replicas + TimescaleDB for time-series analytics
- **Frontend Performance:** Monitor bundle size, implement code splitting aggressively
- **Multi-chain:** Start with EVM chains, evaluate Cosmos/Polkadot later

### Implementation Details

- **Frontend:** Bind to 0.0.0.0:5000 (Replit requirement)
- **Backend:** Run on localhost:4000 (internal)
- **Database:** PostgreSQL 15 with UTF-8 encoding
- **Redis:** For caching + job queues
- **Monitoring:** Export metrics in Prometheus format

### Cost Estimates (Monthly)

- **Infrastructure:** ~$500-1000 (Kubernetes cluster, databases)
- **AI/ML APIs:** ~$200-500 (LLM calls, caching reduces cost)
- **CDN:** ~$50-100 (Cloudflare)
- **Monitoring:** ~$50 (Grafana Cloud optional)
- **Total:** ~$800-1650/month for production

### Performance Targets

- **Frontend:** Lighthouse >90 (desktop), >80 (mobile)
- **Backend:** API p95 <200ms
- **Database:** Query p95 <50ms
- **Blockchain:** 10-100 TPS (testnet), 1000+ TPS (mainnet goal)

---

**Review Date:** 2025-12-15  
**Next Review:** After Phase 1 completion or if major issues arise
