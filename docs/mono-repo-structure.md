# Mono Repo Structure (Suggested)

Root constraints:
- NEVER INSTALL DEPENDENCIES IN ROOT
- Each package has its own package manager files and install scripts
- Use pnpm/workspaces or turborepo; installs executed per-package

Repository layout:

/ (repo root)
├─ agent-rules.md
├─ README.md
├─ .github/
│  └─ workflows/
├─ infra/
│  ├─ terraform/
│  └─ k8s/
├─ packages/
│  ├─ backend/
│  │  ├─ api-gateway/        # NodeJS (Express/Nest)
│  │  ├─ indexer/            # NodeJS or Rust
│  │  ├─ rpc-orchestrator/   # NodeJS tooling to manage Chain nodes
│  │  └─ ai-engine/          # Python/Node service for LLM orchestration
│  ├─ chain/
│  │  ├─ node-core/          # Rust (consensus, storage)
│  │  └─ chain-cli/          # Rust/Node CLI tools
│  ├─ contracts/
│  │  ├─ chaing-token/       # solidity/ink/wasm depending on chain VM
│  │  └─ marketplace/
│  ├─ frontend/
│  │  ├─ web/                # Next.js app
│  │  ├─ admin/              # Admin, SuperAccount features (3D NFT generator)
│  │  └─ components/         # Design system, HeroUI wrappers
│  └─ tooling/
│     ├─ scripts/
│     └─ devcontainers/
└─ docs/
   ├─ roadmap.md
   ├─ design-guide.md
   └─ arsitektur.md

Notes:
- Each subfolder under packages/* is an isolated package. Runs `npm ci` or `cargo build` inside package folder.
- Use Docker images for consistent runtime. Lock files should live inside each package.