# Ghost Protocol — Complete Roadmap

> Scope: backend → smartcontract → frontend. Phased roadmap with deliverables, milestones, and acceptance criteria.
> Guiding principles: security-first, modular mono-repo, CI/CD, reproducible builds, "NEVER INSTALL DEPENDENCIES IN ROOT" rule enforced.

## Phases overview
- Phase 0 — Foundations (0–6 weeks)
  - All ADR Created (blocked all tasks)
  - Establish mono-repo layout, CI/CD templates, security rules (agent-rules.md).
  - Dev environment: local docker-compose for services; devcontainers for contributors.
  - Deliverables: mono-repo scaffold, README, agent-rules.md, initial infra terraform modules (stubs).

- Phase 1 — Core Backend & ChainG Testnet (6–16 weeks)
  - Design and implement Chain Ghost (node) prototype (Rust core + NodeJS orchestration).
  - Build ChainG RPC (read-only + write through validators).
  - Indexer service: stream node blocks to DB (postgres + timescaledb if needed).
  - Testnet orchestration: Docker Compose + Kubernetes manifests for testnet nodes.
  - Faucet: daily claim logic and anti-abuse rules.
  - Acceptance: private testnet running with automated block generation and working faucet.

- Phase 2 — Token, Smart Contracts & NFT primitives (10–20 weeks, overlapped)
  - Smart contract design: token (ChainG), staking, governance voting, NFT standard.
  - Audit-ready patterns: upgradeability considerations, upgradable proxies if necessary.
  - Unit + property tests for contracts, CI that runs tests + static analyzers.
  - Deploy to testnet; integrate with indexer & RPC.
  - Acceptance: token mint/burn, stake/unstake flows, NFT minting on testnet.

- Phase 3 — G3Mail, AI Engine & Social Graph (12–24 weeks)
  - G3Mail (Ghost Web3 Mail): decentralized communication product with on-chain pointers and encrypted off-chain storage.
  - AI Engine: LLM orchestration (Hugging Face + multi-LLM fallbacks), story generation for ChainGhost narrative layer.
  - Social Graph service (Ghonity backend): relationships, follows, reputation system.
  - Acceptance: send/receive G3Mail on testnet, LLM-generated story output integrated in ChainGhost.

- Phase 4 — Frontend Core (ChainGhost + Ghonity) (8–16 weeks)
  - Next.js app (monorepo workspace), Spline scenes for 3D holograms, HeroUI components and design system.
  - ChainGhost: Unified wallet + journey visualization, transaction signing, story narrative display.
  - Ghonity: Community feed, follow wallets, discover alpha, social interactions.
  - Marketplace MVP: browse, mint, list, buy.
  - Acceptance: end-to-end transaction + story flow on testnet, responsive UI, accessibility.

- Phase 5 — Community, Gamified Mining & Launch (12–20 weeks)
  - Ghost Hunter missions (telegram-based game): mining mechanics, claims, token conversion.
  - Telegram integration: bot, OTP, wallet linking, game logic.
  - Go-to-market: community on Telegram, incentives, ambassador program.
  - Mainnet readiness checklist, audits, validators onboarding.
  - Acceptance: secure mainnet launch with staking enabled; marketplace operational.

## Milestones and checkpoints
- Weekly: sprint demo, security sprint review
- Monthly: integration QA on testnet, audit readiness
- Pre-mainnet: third-party security audit, bug bounty launch, stress testing & performance benchmarks

## Risk matrix & mitigation
- Smart contract bugs → rigorous audits + formal verification + staged deployment
- RPC / node sync issues → monitoring, fallback providers, multi-region nodes
- Abuse of faucet/mining → rate-limiting, identity checks, economic friction
- LLM hallucination risk → chain-of-truth anchoring, human-in-the-loop moderation

## Acceptance criteria (sample)
- Node: 7-day uptime >= 99% in staging
- RPC: p95 latency < 300ms for primary calls
- Smart contracts: 0 critical or high audit findings
- Frontend: a11y score >= AA, Lighthouse > 90 on core pages