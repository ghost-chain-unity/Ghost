# Ghost Protocol - Web3 Super-App Ecosystem

## Overview

Ghost Protocol is a Web3 super-app ecosystem aiming to create a "flywheel effect" through the integration of three core products: **ChainGhost** (unified execution, journey visualization, and narrative storytelling), **G3Mail** (decentralized, encrypted messaging), and **Ghonity** (a community ecosystem for wallet discovery, social interaction, and copy-trading). The project's vision is to establish a self-reinforcing loop of **ACTION (ChainGhost) → NARRATIVE (Story) → COMMUNITY (Ghonity)**, fostering engagement and growth within its decentralized ecosystem. It seeks to offer a comprehensive and intuitive Web3 experience.

## User Preferences

Preferred communication style: Simple, everyday language.

## System Architecture

### Repository Structure

The project uses a mono-repo architecture with pnpm workspaces for dependency isolation and management.

### Technology Stack

**Frontend:** Next.js 14, React 18, TypeScript, Hero UI, Tailwind CSS, Three.js (@react-three/fiber), Spline, GSAP, Framer Motion, with a mobile-first, glass/neon aesthetic.

**Backend:** NestJS 10, Node.js 20, TypeScript for API Gateway and microservices.

**Blockchain:** Rust-based chain node (Substrate-inspired), RocksDB for storage, JSON-RPC (HTTP + WebSocket) interface. Smart contracts are developed using ink! and/or Solidity. Consensus mechanisms include PoA (testnet) and NPoS (mainnet plan). Custom pallets include `pallet-chainghost` (intent execution), `pallet-g3mail` (decentralized messaging), and `pallet-ghonity` (social graph, reputation).

**AI/ML:** Python/Node.js AI Engine leveraging Hugging Face LLM endpoints for story generation, with multi-LLM fallback and content safety filtering.

**Caching & Storage Strategy (Hybrid):** Dragonfly (RPC Call Cache), DuckDB or LMDB (Event Indexing), IPFS (decentralized content storage), PostgreSQL (Rate Limiting, Session State), Dragonfly (Session State Cache).

**Infrastructure:** Docker Compose (local), Kubernetes (production), GitHub Actions (CI/CD).

### Core Services Architecture

- **Frontend:** Main App and Admin Dashboard.
- **Backend:** API Gateway (Auth, rate limiting, routing), Indexer (Blockchain event processing), RPC Orchestrator (Node management), AI Engine (LLM orchestration).
- **Blockchain:** Core blockchain node.
- **Smart Contracts:** Native token and NFT marketplace.

### Data Flow Architecture

- **Transaction Execution (ChainGhost):** User intents via API Gateway → Blockchain → Indexed → AI Engine for narrative.
- **Communication (G3Mail):** Client-side encrypted messages stored off-chain (IPFS/S3) with on-chain pointers.
- **Social Graph (Ghonity):** Manages wallet relationships and reputation in PostgreSQL, feeding community activity.

### Security Architecture

Includes JWT authentication, request signing, client-side encryption for G3Mail, API Gateway rate limiting, AI Engine content safety filtering, and comprehensive audit logging with append-only logs for AI prompts.

## Recent Changes (2025-11-24)

- **Runtime Structure Fix:** Reorganized runtime/src/lib.rs - moved `mod runtime` block earlier to enable proper type sequencing, removed unavailable features (RuntimeViewFunction, WeightReclaim)
- **Type Export Fixes:** Added root-level re-exports for RuntimeGenesisConfig, BalancesConfig, SudoConfig to genesis_config_presets.rs
- **Dependency Version Alignment:** Updated all polkadot-sdk and Frontier dependencies from stable2409 to stable2412 for consistency
- **Import Path Fixes:** Cleaned up apis_impls.rs and genesis_config_presets.rs imports to use correct type paths

## External Dependencies

### Third-Party Services

- **Blockchain & Web3:** Substrate framework (stable2412), RocksDB, Frontier/Moonbeam (stable2412 fork).
- **AI/ML:** Hugging Face API.
- **Caching & Storage:** Dragonfly, DuckDB, LMDB, IPFS, Amazon S3.
- **Databases:** PostgreSQL 15+, TimescaleDB.
- **Infrastructure & DevOps:** Docker, Docker Compose, Kubernetes, GitHub Actions.
- **Frontend Libraries:** Three.js, Spline, GSAP, Framer Motion, Hero UI, Tailwind CSS.
- **Backend Libraries:** NestJS, Prisma ORM.

### API Integrations

- JSON-RPC endpoints.
- GraphQL APIs.
- REST APIs.
- WebSocket connections.

### External Blockchain Networks

- Multi-chain support, chain-specific RPC endpoints, bridge protocols.