# Tooling

Development tools and utilities for Ghost Protocol.

## Tools

### scripts
Automation scripts for development, deployment, and maintenance.
- **Deployment scripts** - Deploy to staging/production
- **Migration scripts** - Database migrations
- **Utility scripts** - Code generation, cleanup
- **Status:** 📋 Planned (not implemented)

### devcontainers
Development container configurations for consistent environments.
- **Docker configs** - Containerized development
- **VS Code configs** - Remote container development
- **Status:** 📋 Planned (not implemented)

## Scripts Usage

```bash
# Run deployment script
./scripts/deploy.sh staging

# Run database migration
./scripts/migrate.sh up

# Generate code
./scripts/generate-types.sh
```

## Development Containers

```bash
# Open in VS Code devcontainer
code .
# Then: Reopen in Container

# Build container manually
cd devcontainers
docker build -t ghost-dev .
docker run -it ghost-dev
```

## Directory Structure

```
tooling/
├── scripts/
│   ├── deploy/
│   ├── migrate/
│   └── utils/
└── devcontainers/
    ├── backend/
    ├── frontend/
    └── contracts/
```

---

**Last Updated:** November 15, 2025
