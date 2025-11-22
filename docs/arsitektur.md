# Arsitektur — Ghost Protocol (Comprehensive)

## High-level domains
- Chain Layer (Rust)
  - Consensus (prototype): lightweight PoA or customized PoS for early testnet.
  - Storage: append-only block store, state DB (RocksDB).
  - RPC interface: JSON-RPC HTTP + WebSocket.
- Node Orchestration (NodeJS)
  - Node manager, telemetry, plugin loader for indexer hooks.
- Indexer Service (NodeJS / Rust)
  - Streams blocks, extracts events via WebSocket subscription.
  - Writes high-performance indexed events to DuckDB/LMDB.
  - Writes block/transaction metadata to Postgres (for aggregations).
  - Exposes GraphQL and REST APIs for frontend.
- API Gateway (NodeJS)
  - Auth (JWT + request signing), rate-limiting, request aggregation.
  - RPC response caching via Dragonfly (distributed cache).
  - PostgreSQL-based rate limiting via Guards/Middleware.
- Hybrid Caching Strategy:
  - **RPC Cache:** Dragonfly (Redis-compatible, opensource) for distributed RPC response caching
  - **Event Storage:** DuckDB or LMDB for high-performance event indexing and analytics
  - **Rate Limiting:** PostgreSQL-based storage for rate limit state (per-IP, per-token tracking)
  - **Session State:** PostgreSQL (primary), Dragonfly (cache layer)
- ChainGhost (Unified Execution + Journey)
  - Wallet operations + auto-generated narrative visualization
  - Intent-based architecture for cross-chain transactions
  - Story generation integrated into transaction flow
- G3Mail (Ghost Web3 Mail Product)
  - Encrypted off-chain storage via IPFS (decentralized, censorship-resistant).
  - Alternative: S3 with client-side encryption as fallback.
  - On-chain pointers to message roots, client-side decryption.
- AI Engine (Python/NodeJS)
  - LLM orchestration with Hugging Face endpoints; request queuing and caching.
  - Story generation for ChainGhost narrative layer
  - Content safety filter and traceability (store seeds & prompts on append-only logs).
- Ghonity (Community Ecosystem)
  - Social Graph (Postgres + edges): relationship modeling, follow/unfollow, reputation, bans.
  - Community feed, wallet discovery, alpha discovery
  - Copy-trade strategies and social interactions
- Marketplace Service
  - Orders, listings, payment settlement, escrowed transfers.

## Blockchain Layer
- Substrate-based WASM chain
- Testnet: Aura/GRANDPA
- Mainnet: NPoS
- Smart Contracts: ink! + optional EVM pallet

## Services
- RPC custom
- AI Engine
- Social Graph
- Web3 Mail

# Smart Contracts — Final Set

- ChainG Token (ink!)
- GhostBit Mining Token
- Staking Module (runtime)
- Governance Voting Contract
- NFT Hologram Contract
- Marketplace Contract
- G3Mail Pointer Contract

## Data flow (simplified)
1. User action (mint/list) → Frontend submits signed tx via ChainG RPC.
2. Node processes tx → block produced.
3. Indexer consumes block → extracts events → updates marketplace DB + search index (Elastic/Meilisearch).
4. Notification service pushes to user via websocket/push and Telegram bot if linked.

## Deployment topology
- Kubernetes clusters (staging, production) using Helm charts.
- Separated namespaces for infra: infra, backend, services, frontend.
- Observability: Prometheus, Grafana, Loki, Jaeger.
- CDN + edge caching: Vercel/Netlify for frontend static pages; image CDN for assets.

## Security
- Secrets via HashiCorp Vault / Kubernetes secrets with KMS.
- Immutable images, reproducible builds, SBOMs for containers.
- Runtime policies: OPA/Gatekeeper, network policies to limit service-to-service access.

## CI/CD
- Monorepo pipelines (GitHub Actions / GitLab CI / Buildkite)
  - Per-package builds using workspace detection.
  - Dependabot + automated dependency audits.
  - Avoid `npm install` in repo-root: install per-package inside packages/* with clean lockfiles.
  - Example job: `ci/install-and-test` that locates changed packages and runs install/test in their directories.

## Observability & Alerts
- SLOs for RPC/Indexer/API.
- Alerting rules for high error-rate, increased gas/use, node lag.
- Replayable logs for incident analysis.

## Testing strategy
- Local end-to-end using ephemeral docker-compose testnet.
- Unit tests for contracts (forge/hardhat), property tests for critical invariants.
- Chaos testing for node resilience.

## Scalability notes
- Indexer horizontally scalable via partitioning block ranges.
- API Gateway stateless; use Dragonfly for transient cache (RPC responses) but not as single source for persistence.
- Event storage in DuckDB/LMDB enables fast analytics queries without overloading Postgres.
- Rate limiting state in PostgreSQL ensures consistency across multiple Gateway instances.
- Use database read replicas for heavy read queries (marketplace search).