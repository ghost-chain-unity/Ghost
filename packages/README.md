# Ghost Protocol — Packages

This directory contains all the packages for the Ghost Protocol mono-repo.

## Structure

```
packages/
├── backend/           # Backend services (NestJS, Node.js)
├── chain/             # Blockchain layer (Rust)
├── contracts/         # Smart contracts (Solidity/ink!)
├── frontend/          # Frontend applications (Next.js, React)
└── tooling/           # Development tools and scripts
```

## Package Management

**CRITICAL RULE: NEVER INSTALL DEPENDENCIES IN ROOT**

Each package is self-contained with its own:
- `package.json` / `Cargo.toml` (dependency manifest)
- `package-lock.json` / `Cargo.lock` (lockfile)
- `node_modules/` / `target/` (dependencies)
- `README.md` (package documentation)

## Installation

```bash
# Backend packages
cd packages/backend/api-gateway && npm install
cd packages/backend/indexer && npm install

# Frontend packages
cd packages/frontend/web && npm install
cd packages/frontend/admin && npm install

# Contracts
cd packages/contracts/chaing-token && npm install
cd packages/contracts/marketplace && npm install

# Chain (Rust)
cd packages/chain/node-core && cargo build
```

## Development

Each package has its own development workflow. Refer to individual package READMEs for specific instructions.

## Testing

```bash
# Run tests for all packages
npm run test:all         # (from root)

# Run tests for specific package
cd packages/backend/api-gateway && npm test
```

## Contributing

1. Make changes within the appropriate package directory
2. Follow the package-specific guidelines in its README
3. Ensure all tests pass before submitting PR
4. Update package documentation if needed

---

**Last Updated:** November 15, 2025
