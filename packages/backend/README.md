# Backend Services

This directory contains all backend services for Ghost Protocol.

## Services

### api-gateway
API Gateway service - handles authentication, rate limiting, and request routing.
- **Tech Stack:** NestJS, Express
- **Port:** 4000 (development)
- **Status:** 📋 Planned (not implemented)

### indexer
Blockchain indexer service - streams blocks, extracts events, writes to database.
- **Tech Stack:** Node.js/Rust
- **Database:** PostgreSQL + TimescaleDB
- **Status:** 📋 Planned (not implemented)

### rpc-orchestrator
Node orchestration service - manages Chain Ghost nodes, telemetry, plugin loading.
- **Tech Stack:** Node.js
- **Status:** 📋 Planned (not implemented)

### ai-engine
AI/ML service - LLM orchestration, story generation, persona management.
- **Tech Stack:** Python/Node.js
- **LLM:** Hugging Face endpoints
- **Status:** 📋 Planned (not implemented)

## Installation

Each service has its own `package.json`. Install dependencies per-service:

```bash
cd api-gateway && npm install
cd indexer && npm install
cd rpc-orchestrator && npm install
cd ai-engine && npm install
```

## Development

```bash
# Start all services (when implemented)
npm run dev:all

# Start specific service
cd api-gateway && npm run dev
```

## Environment Variables

Each service requires its own `.env` file. See individual service READMEs for required variables.

## Testing

```bash
# Run tests for all services
npm test

# Run tests for specific service
cd api-gateway && npm test
```

## Architecture

All services follow NestJS modular architecture:
```
service/
├── src/
│   ├── modules/       # Feature modules
│   ├── controllers/   # HTTP handlers
│   ├── services/      # Business logic
│   ├── models/        # Data models
│   └── utils/         # Helper functions
├── test/              # Tests
├── package.json
└── README.md
```

---

**Last Updated:** November 15, 2025
