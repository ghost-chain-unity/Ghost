# Ghost Protocol — File Structure Reference

**Last Updated:** November 16, 2025  
**Purpose:** Comprehensive file structure documentation, relationships, and dependency mapping  
**Status:** Living document (updated as project evolves)

**Recent Updates (Nov 16, 2025):**

**Phase 0.4: Infrastructure Setup - COMPLETED**

- ✅ **Phase 0.4.1: Terraform Modules (PRODUCTION-READY)**
  - All 5 Terraform modules completed: networking, compute, database, storage, observability
  - Comprehensive module documentation (5 modules with 300+ line READMEs each)
  - Two-stage deployment strategy documented (resolves OIDC/IRSA circular dependency)
  - Environment configurations complete (dev, staging, prod)
  - Secret management best practices documented

- ✅ **Phase 0.4.2: Kubernetes Base Manifests (48 YAML files total)**
  - Backend services: 31 YAML files (api-gateway, indexer, rpc-orchestrator, ai-engine)
  - Monitoring/Observability: 17 YAML files (Prometheus, Grafana, Loki, Jaeger, AlertManager)
  - Service configurations, ConfigMaps, ServiceAccounts with IRSA annotations
  - Resource limits, health checks, HorizontalPodAutoscaler for all services
  - Kustomize base + overlays (dev, staging, production)

- ✅ **Phase 0.4.3: Monitoring Infrastructure**
  - Prometheus deployed (v2.48.0 with 15-day retention, 50Gi storage)
  - Grafana deployed (v10.2.2 with pre-configured datasource)
  - Complete scrape configs for all backend services
  - RBAC configured (ServiceAccount, ClusterRole, ClusterRoleBinding)

- ✅ **Phase 0.4.4: Operational Runbooks (3,948 lines)**
  - Node recovery procedures (596 lines)
  - Database restore procedures (812 lines)
  - Incident response workflows (814 lines)
  - Rollback procedures (885 lines)
  - Disaster recovery procedures (841 lines)

- ✅ **Phase 0.4.5: Loki Log Aggregation (7 K8s manifests)**
  - Loki StatefulSet (grafana/loki:2.9.0, 10Gi storage, 30-day retention)
  - Promtail DaemonSet (runs on all nodes, scrapes pod logs)
  - PII masking configured (email, IP, wallet addresses, API keys, SSN, credit cards)
  - RBAC setup (ServiceAccounts, ClusterRole, ClusterRoleBinding)
  - Grafana datasource configured for Loki

- ✅ **Phase 0.4.6: OpenTelemetry Distributed Tracing (5 K8s manifests)**
  - OpenTelemetry Collector (2 replicas HA, OTLP gRPC/HTTP receivers)
  - W3C Trace Context propagation configured
  - Sampling strategy: 100% dev, 10% production (configurable)
  - Jaeger all-in-one (jaegertracing/all-in-one:1.51, in-memory storage)
  - Grafana datasources (Jaeger + Loki correlation, service graph)

- ✅ **Phase 0.4.7: AlertManager + PagerDuty Integration (5 K8s manifests)**
  - AlertManager StatefulSet (prom/alertmanager:v0.26.0, 5Gi storage)
  - 20 alert rules across 4 severity levels (P0 Critical, P1 High, P2 Medium, P3 Low)
  - Notification routing: P0/P1→PagerDuty+Slack, P2→Email+Slack, P3→Slack
  - Inhibition rules configured (prevent alert storms)
  - Escalation policies documented

**Phase 0.3: CI/CD Pipeline - COMPLETED**
- ✅ GitHub Actions workflows for Frontend, Backend, Smart Contracts
- ✅ Security scanning (Snyk, CodeQL, Dependabot)
- ✅ Automated testing and deployment pipelines

**Phase 0.2: Development Environment - COMPLETED**
- ✅ Docker Compose for local services
- ✅ DevContainer configurations with security validation (VALIDATION.md)
- ✅ Code quality tools configured (ESLint, Prettier, TypeScript)

**Phase 0.1: Documentation & Planning - COMPLETED**
- ✅ Product concept documentation (ChainGhost.md, G3Mail.md, Ghonity.md)
- ✅ Architecture Decision Records (ADRs)
- ✅ Mono-repo structure established
- ✅ Comprehensive task breakdown (roadmap-tasks.md)

**🎉 Phase 0 (Foundations) - FULLY COMPLETED**

---

## 📋 Table of Contents

1. [Complete File Tree](#complete-file-tree)
2. [File Relationships](#file-relationships)
3. [Dependency Graph](#dependency-graph)
4. [Configuration Files](#configuration-files)
5. [Documentation Map](#documentation-map)
6. [Cross-Package Dependencies](#cross-package-dependencies)
7. [File Naming Conventions](#file-naming-conventions)
8. [Synchronization Rules](#synchronization-rules)

---

## 🌳 Complete File Tree

```
ghost-protocol/
│
├── 📄 Root Configuration & Documentation
│   ├── README.md                      # Project overview and quick start
│   ├── agent-rules.md                 # Development guidelines (MUST READ)
│   ├── reference-file.md              # This file (structure reference)
│   ├── roadmap-tasks.md               # Comprehensive task breakdown
│   ├── .gitignore                     # Git ignore rules
│   ├── .replit                        # Replit configuration
│   ├── replit.md                      # Replit project state
│   ├── package.json                   # Workspace definition ONLY (no deps!)
│   └── [Product Concept Docs] ✅ COMPLETED
│       ├── ChainGhost.md              # ChainGhost (unified execution + journey visualization)
│       ├── G3Mail.md                  # Ghost Web3 Mail (decentralized communication)
│       └── Ghonity.md                 # Ghonity (community ecosystem & social graph)
│
├── 📦 packages/                       # All application code (mono-repo)
│   │
│   ├── 🔙 backend/                    # Backend services
│   │   ├── README.md
│   │   ├── api-gateway/               # API Gateway (NestJS)
│   │   │   ├── src/
│   │   │   ├── test/
│   │   │   ├── package.json           # ✅ Dependencies HERE
│   │   │   ├── package-lock.json
│   │   │   ├── tsconfig.json
│   │   │   └── README.md
│   │   ├── indexer/                   # Blockchain indexer
│   │   │   ├── src/
│   │   │   ├── test/
│   │   │   ├── package.json           # ✅ Dependencies HERE
│   │   │   ├── package-lock.json
│   │   │   └── README.md
│   │   ├── rpc-orchestrator/          # Node orchestration
│   │   │   ├── src/
│   │   │   ├── package.json           # ✅ Dependencies HERE
│   │   │   └── README.md
│   │   └── ai-engine/                 # AI/ML service
│   │       ├── src/
│   │       ├── package.json           # ✅ Dependencies HERE
│   │       └── README.md
│   │
│   ├── ⛓️ chain/                      # Blockchain layer (Rust)
│   │   ├── README.md
│   │   ├── node-core/                 # Core blockchain node
│   │   │   ├── src/
│   │   │   ├── Cargo.toml             # ✅ Dependencies HERE
│   │   │   ├── Cargo.lock
│   │   │   └── README.md
│   │   └── chain-cli/                 # CLI tools
│   │       ├── src/
│   │       ├── Cargo.toml             # ✅ Dependencies HERE
│   │       └── README.md
│   │
│   ├── 📜 contracts/                  # Smart contracts
│   │   ├── README.md
│   │   ├── chaing-token/              # ChainG token
│   │   │   ├── contracts/
│   │   │   ├── test/
│   │   │   ├── scripts/
│   │   │   ├── package.json           # ✅ Dependencies HERE
│   │   │   ├── hardhat.config.js
│   │   │   └── README.md
│   │   └── marketplace/               # NFT marketplace
│   │       ├── contracts/
│   │       ├── test/
│   │       ├── package.json           # ✅ Dependencies HERE
│   │       └── README.md
│   │
│   ├── 🎨 frontend/                   # Frontend applications
│   │   ├── README.md
│   │   ├── web/                       # Main web app (ChainGhost + Ghonity)
│   │   │   ├── pages/
│   │   │   ├── src/
│   │   │   │   └── components/
│   │   │   ├── styles/
│   │   │   ├── public/
│   │   │   ├── package.json           # ✅ Dependencies HERE
│   │   │   ├── package-lock.json
│   │   │   ├── next.config.js
│   │   │   ├── tailwind.config.js
│   │   │   ├── .eslintrc.json
│   │   │   └── README.md
│   │   ├── admin/                     # Admin dashboard
│   │   │   ├── pages/
│   │   │   ├── src/
│   │   │   ├── package.json           # ✅ Dependencies HERE
│   │   │   └── README.md
│   │   └── components/                # Shared component library
│   │       ├── src/
│   │       ├── .storybook/
│   │       ├── package.json           # ✅ Dependencies HERE
│   │       └── README.md
│   │
│   └── 🛠️ tooling/                    # Development tools
│       ├── README.md
│       ├── scripts/                   # Automation scripts
│       │   ├── deploy/
│       │   ├── migrate/
│       │   └── utils/
│       └── devcontainers/             # Dev container configs (not used, see .devcontainer/)
│           ├── backend/
│           ├── frontend/
│           └── contracts/
│
├── 🏗️ infra/                          # Infrastructure as Code ✅ PHASE 0.4 COMPLETED
│   ├── README.md
│   ├── terraform/                     # Infrastructure provisioning ✅ PRODUCTION-READY
│   │   ├── README.md                  # ✅ Bootstrap guide (first-time setup)
│   │   ├── DEPLOYMENT_GUIDE.md        # ✅ Two-stage deployment guide + secret management
│   │   ├── main.tf                    # Root module (orchestrates all modules)
│   │   ├── outputs.tf                 # Root outputs (OIDC, VPC, EKS, RDS, S3)
│   │   ├── backend.tf                 # S3 remote state config
│   │   ├── backend-bootstrap.tf       # Bootstrap resources (S3 + DynamoDB)
│   │   ├── provider.tf                # AWS provider config
│   │   ├── versions.tf                # Terraform >= 1.6.0, AWS ~> 5.0
│   │   ├── variables.tf               # Root module variables (all environments)
│   │   ├── locals.tf                  # Local values (resource naming)
│   │   │
│   │   ├── modules/                   # ✅ 5 Production-Ready Terraform Modules
│   │   │   │
│   │   │   ├── networking/aws/        # ✅ Multi-Tier VPC (Public/Private-App/Private-Data)
│   │   │   │   ├── main.tf            # VPC, subnets, route tables, IGW, NAT
│   │   │   │   ├── security_groups.tf # ALB, EKS cluster, EKS nodes, RDS, Redis, VPC endpoints
│   │   │   │   ├── vpc_endpoints.tf   # S3 (gateway), ECR/EKS/EC2/STS (interface)
│   │   │   │   ├── outputs.tf         # VPC ID, subnet IDs, security group IDs
│   │   │   │   ├── variables.tf       # VPC CIDR, AZs, NAT gateway config
│   │   │   │   └── README.md          # 362 lines: architecture, 3 examples, cost optimization
│   │   │   │
│   │   │   ├── compute/aws/           # ✅ EKS Cluster + 3 Node Groups
│   │   │   │   ├── main.tf            # EKS cluster, OIDC provider
│   │   │   │   ├── node_groups.tf     # General (t3), Compute (c5), Memory (r5) node groups
│   │   │   │   ├── addons.tf          # VPC CNI, kube-proxy, CoreDNS, EBS CSI driver
│   │   │   │   ├── security_groups.tf # Cluster control plane security
│   │   │   │   ├── outputs.tf         # Cluster endpoint, OIDC ARN, node group IDs
│   │   │   │   ├── variables.tf       # Cluster version, node sizes, add-on configs
│   │   │   │   └── README.md          # 320 lines: IRSA setup, node workload examples
│   │   │   │
│   │   │   ├── database/aws/          # ✅ RDS PostgreSQL (Multi-AZ, Read Replicas)
│   │   │   │   ├── main.tf            # RDS instance, DB subnet group
│   │   │   │   ├── parameter_group.tf # Optimized PostgreSQL parameters
│   │   │   │   ├── replicas.tf        # Same-region and cross-region read replicas
│   │   │   │   ├── security_groups.tf # Database access control
│   │   │   │   ├── outputs.tf         # Endpoint, connection string, ARN
│   │   │   │   ├── variables.tf       # Instance class, storage, backup config
│   │   │   │   └── README.md          # 457 lines: connection guide, backups, monitoring
│   │   │   │
│   │   │   ├── storage/aws/           # ✅ S3 (4 Buckets) + CloudFront CDN
│   │   │   │   ├── main.tf            # App-data, backups, logs, static-assets buckets
│   │   │   │   ├── bucket_policies.tf # Enforce encryption, deny unencrypted uploads
│   │   │   │   ├── cloudfront.tf      # CDN for static assets (optional)
│   │   │   │   ├── replication.tf     # Cross-region replication (us-west-2)
│   │   │   │   ├── outputs.tf         # Bucket IDs/ARNs, CloudFront domain
│   │   │   │   ├── variables.tf       # Versioning, lifecycle, replication config
│   │   │   │   └── README.md          # 503 lines: 4 usage examples, cost optimization
│   │   │   │
│   │   │   └── observability/aws/     # ✅ KMS Keys + IAM Roles + CloudWatch Logs
│   │   │       ├── main.tf            # CloudWatch log groups (EKS, apps, audit)
│   │   │       ├── kms.tf             # 5 KMS keys (EKS, RDS, S3, EBS, CloudWatch)
│   │   │       ├── iam_eks.tf         # EKS cluster role, node role
│   │   │       ├── iam_pods.tf        # IRSA pod roles (api-gateway, indexer, rpc, ai)
│   │   │       ├── iam_data.tf        # RDS enhanced monitoring role
│   │   │       ├── outputs.tf         # KMS ARNs, IAM role ARNs, log group names
│   │   │       ├── variables.tf       # Log retention, OIDC config, service names
│   │   │       └── README.md          # 326 lines: IRSA prerequisites, security notes
│   │   │
│   │   └── environments/              # ✅ Environment-Specific Configurations
│   │       ├── dev/terraform.tfvars   # Cost-optimized (single NAT, SPOT nodes)
│   │       ├── staging/terraform.tfvars # Production-like (multi-AZ, ON_DEMAND)
│   │       └── prod/terraform.tfvars  # High availability (3 AZs, read replicas)
│   │
│   ├── k8s/                           # Kubernetes manifests ✅ COMPLETED (31 YAML files)
│   │   ├── README.md                  # K8s deployment guide
│   │   ├── IRSA_SETUP.md              # IAM Roles for Service Accounts setup guide
│   │   ├── base/                      # Base Kustomize resources (all backend services)
│   │   │   ├── api-gateway/           # API Gateway (Deployment, Service, ConfigMap, HPA)
│   │   │   ├── indexer/               # Indexer service (CPU-intensive workload)
│   │   │   ├── rpc-orchestrator/      # RPC orchestrator (failover strategy)
│   │   │   ├── ai-engine/             # AI Engine (GPU-ready, memory-intensive)
│   │   │   ├── monitoring/            # Prometheus + Grafana stack (9 files)
│   │   │   └── secrets/               # Secrets management (README + placeholder)
│   │   └── overlays/                  # Environment-specific Kustomize overlays
│   │       ├── dev/                   # Development environment (minimal resources)
│   │       │   ├── README.md
│   │       │   └── kustomization.yaml
│   │       ├── staging/               # Staging environment (production-like)
│   │       │   └── kustomization.yaml
│   │       └── production/            # Production environment (HA, scaled resources)
│   │           └── kustomization.yaml
│   │
│   └── runbooks/                      # Operational procedures ✅ COMPLETED (3,948 lines)
│       ├── README.md                  # Runbook index and emergency contacts
│       ├── node-recovery.md           # EKS node recovery procedures (596 lines)
│       ├── database-restore.md        # RDS restore from snapshots/PITR (812 lines)
│       ├── incident-response.md       # Production incident management (814 lines)
│       ├── rollback-procedure.md      # K8s/Terraform/DB/Frontend rollbacks (885 lines)
│       └── disaster-recovery.md       # Regional failover & DR (841 lines)
│
├── 📚 docs/                           # Documentation
│   ├── README.md
│   ├── roadmap.md                     # Development roadmap
│   ├── arsitektur.md                  # System architecture
│   ├── design-guide.md                # UI/UX design guide
│   ├── mono-repo-structure.md         # Mono-repo guidelines
│   ├── agent-rules.md                 # Agent operational rules (merged to root)
│   │
│   ├── adr/                           # Architecture Decision Records
│   │   ├── README.md
│   │   ├── template.md
│   │   └── [ADR files...]
│   │
│   ├── templates/                     # Documentation templates
│   │   ├── README.md
│   │   ├── technical-design-document.md
│   │   ├── bug-report.md
│   │   ├── feature-request.md
│   │   ├── onboarding-checklist.md
│   │   └── release-notes.md
│   │
│   ├── sprints/                       # Sprint documentation
│   │   ├── README.md
│   │   └── [Sprint folders...]
│   │
│   └── meetings/                      # Meeting notes
│       ├── README.md
│       └── [Meeting notes...]
│
├── 🐳 .devcontainer/                  # DevContainer configurations ✅ COMPLETED
│   ├── README.md                      # DevContainer usage guide
│   ├── VALIDATION.md                  # Security validation documentation
│   ├── devcontainer.json              # Root DevContainer (Node.js 20, Rust, Docker-in-Docker)
│   ├── docker-compose.devcontainer.yml # Docker Compose for DevContainer
│   ├── validate.sh                    # Validation script for DevContainer setup
│   ├── chain/                         # Chain DevContainer (Rust, Cargo, wasm32)
│   │   ├── devcontainer.json
│   │   └── setup.sh
│   └── contracts/                     # Contracts DevContainer (Foundry with SHA256 verification)
│       ├── devcontainer.json
│       └── setup.sh
│
└── ⚙️ .github/                        # GitHub configuration ✅ COMPLETED
    ├── workflows/                     # CI/CD pipelines
    │   ├── backend-ci.yml             # Backend testing (4 services matrix)
    │   ├── frontend-ci.yml            # Frontend testing (3 packages matrix)
    │   ├── contracts-ci.yml           # Smart contract testing (95% coverage enforced)
    │   └── security-scan.yml          # Snyk + CodeQL + Dependabot
    ├── pull_request_template.md       # PR template
    ├── CODEOWNERS                     # Auto-assign reviewers
    └── dependabot.yml                 # Automated dependency updates
```

---

## 🔗 File Relationships

### Documentation Hierarchy

```
agent-rules.md (ROOT - Comprehensive guide)
    ↓
    ├─→ reference-file.md (This file - structure map)
    ├─→ roadmap-tasks.md (Task breakdown)
    ├─→ docs/roadmap.md (Phase roadmap)
    ├─→ docs/arsitektur.md (Architecture)
    ├─→ docs/design-guide.md (Design system)
    └─→ docs/adr/ (Architectural decisions)
```

### Package Dependencies Flow

```
Frontend (packages/frontend/web)
    ↓ API calls
    ├─→ Backend (packages/backend/api-gateway)
    │       ↓ Data queries
    │       ├─→ Database (PostgreSQL)
    │       └─→ Backend Services
    │           ├─→ Indexer (blockchain data)
    │           ├─→ AI Engine (LLM)
    │           └─→ RPC Orchestrator (chain nodes)
    │
    └─→ Smart Contracts (packages/contracts/*)
            ↓ RPC calls
            └─→ Chain Layer (packages/chain/node-core)
```

### Configuration Dependencies

```
Root package.json (workspace definition)
    ↓ defines workspaces
    ├─→ packages/frontend/web/package.json
    ├─→ packages/backend/*/package.json
    └─→ packages/contracts/*/package.json

Root .gitignore
    ├─→ packages/frontend/web/.gitignore
    ├─→ packages/backend/*/.gitignore
    └─→ packages/contracts/*/.gitignore
```

---

## 📊 Dependency Graph

### Frontend Dependencies

**packages/frontend/web/package.json:**
```json
{
  "dependencies": {
    "next": "14.0.4",
    "react": "^19.0.0",
    "@heroui/react": "^2.8.5",
    "three": "^0.152.2",
    "@react-three/fiber": "^8.x",
    "framer-motion": "^12.x",
    "gsap": "^3.12.2"
  }
}
```

**Shared with:** packages/frontend/admin, packages/frontend/components

### Backend Dependencies

**packages/backend/api-gateway/package.json:**
```json
{
  "dependencies": {
    "@nestjs/core": "^10.x",
    "@nestjs/common": "^10.x",
    "prisma": "^5.x",
    "express": "^4.x"
  }
}
```

**Shared with:** packages/backend/indexer, packages/backend/rpc-orchestrator

### Smart Contract Dependencies

**packages/contracts/*/package.json:**
```json
{
  "dependencies": {
    "hardhat": "^2.x",
    "@openzeppelin/contracts": "^5.x",
    "ethers": "^6.x"
  }
}
```

---

## ⚙️ Configuration Files

### Root Level (NO DEPENDENCIES!)

**package.json** (Workspace definition ONLY)
```json
{
  "name": "ghost-protocol-workspace",
  "private": true,
  "workspaces": [
    "packages/frontend/web",
    "packages/frontend/admin",
    "packages/backend/api-gateway",
    "packages/backend/indexer"
  ],
  "scripts": {
    "dev:frontend": "cd packages/frontend/web && npm run dev",
    "dev:backend": "cd packages/backend/api-gateway && npm run dev"
  }
}
```

**CRITICAL:** No `dependencies` or `devDependencies` field allowed!

**.gitignore** (Root)
```gitignore
# Dependencies (each package has its own)
**/node_modules/
**/package-lock.json
**/target/

# Build outputs
**/.next/
**/dist/
**/build/

# Environment
**/.env
**/.env.local

# IDE
.vscode/
.idea/
```

### Frontend Configuration

**packages/frontend/web/next.config.js:**
```javascript
module.exports = {
  reactStrictMode: true,
  swcMinify: true,
  compiler: {
    removeConsole: process.env.NODE_ENV === 'production',
  },
  // CRITICAL: Must allow all hosts for Replit
  async headers() {
    return [
      {
        source: '/:path*',
        headers: [
          { key: 'Access-Control-Allow-Origin', value: '*' },
        ],
      },
    ]
  },
}
```

**packages/frontend/web/tailwind.config.js:**
```javascript
module.exports = {
  content: [
    './pages/**/*.{js,jsx}',
    './src/components/**/*.{js,jsx}',
  ],
  theme: {
    extend: {
      colors: {
        'void-blue': 'rgb(12, 34, 56)',
        'neon-accent': '#3DD1FF',
      },
    },
  },
}
```

### Backend Configuration

**packages/backend/api-gateway/tsconfig.json:**
```json
{
  "compilerOptions": {
    "module": "commonjs",
    "target": "ES2021",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true
  }
}
```

---

## 📖 Documentation Map

### Quick Reference by Topic

| Topic | Primary Doc | Related Docs |
|-------|-------------|--------------|
| **Getting Started** | README.md | agent-rules.md, packages/*/README.md |
| **Development Guidelines** | agent-rules.md | docs/adr/README.md |
| **Architecture** | docs/arsitektur.md | docs/adr/*.md |
| **Roadmap** | docs/roadmap.md | roadmap-tasks.md |
| **Design System** | docs/design-guide.md | packages/frontend/components/ |
| **API Documentation** | packages/backend/*/README.md | docs/adr/api-*.md |
| **Smart Contracts** | packages/contracts/*/README.md | docs/adr/contract-*.md |
| **Infrastructure** | infra/README.md | infra/terraform/README.md |
| **Terraform Networking** | infra/terraform/modules/networking/aws/README.md | infra/terraform/README.md |
| **Terraform Compute** | infra/terraform/modules/compute/aws/README.md | infra/terraform/README.md |
| **Terraform Database** | infra/terraform/modules/database/aws/README.md | infra/terraform/README.md |
| **Operations** | infra/runbooks/ | docs/adr/infra-*.md |

### Documentation Cross-References

**agent-rules.md references:**
- docs/roadmap.md (development phases)
- docs/arsitektur.md (system architecture)
- docs/design-guide.md (UI/UX guidelines)
- docs/adr/ (architectural decisions)
- reference-file.md (this file)

**README.md references:**
- agent-rules.md (must read first)
- reference-file.md (structure reference)
- roadmap-tasks.md (task breakdown)
- docs/roadmap.md (roadmap details)
- packages/*/README.md (package docs)

---

## 🔄 Cross-Package Dependencies

### Type Definitions (Shared)

**packages/frontend/web/src/types/api.ts:**
```typescript
// Shared API types (matches backend)
export interface User {
  id: string;
  walletAddress: string;
  createdAt: string;
}
```

**packages/backend/api-gateway/src/types/user.ts:**
```typescript
// Backend types (MUST match frontend)
export interface User {
  id: string;
  walletAddress: string;
  createdAt: Date;
}
```

**Synchronization Rule:** Backend types are source of truth. Frontend types generated from backend OpenAPI spec.

### Design Tokens (Shared)

**packages/frontend/components/design-tokens.json:**
```json
{
  "colors": {
    "void-blue": "rgb(12, 34, 56)",
    "neon-accent": "#3DD1FF"
  },
  "spacing": {
    "base": "8px"
  }
}
```

**Used by:**
- packages/frontend/web/tailwind.config.js
- packages/frontend/admin/tailwind.config.js
- docs/design-guide.md

### Smart Contract ABIs (Shared)

**packages/contracts/chaing-token/artifacts/ChainGToken.json:**
```json
{
  "abi": [...]
}
```

**Used by:**
- packages/frontend/web/src/contracts/
- packages/backend/indexer/src/contracts/
- packages/backend/rpc-orchestrator/

---

## 📛 File Naming Conventions

### General Rules

**Components (Frontend):**
- PascalCase: `NetworkVisualizer.jsx`, `Card.jsx`
- Co-located styles: `Card.module.css`
- Tests: `Card.test.jsx`

**Services (Backend):**
- kebab-case: `user-service.ts`, `auth-controller.ts`
- Tests: `user-service.spec.ts`

**Contracts:**
- PascalCase: `ChainGToken.sol`, `Marketplace.sol`
- Tests: `ChainGToken.test.js`

**Documentation:**
- kebab-case: `technical-design-document.md`
- ADRs: `ADR-YYYYMMDD-title.md`
- Runbooks: `node-recovery.md`

**Configuration:**
- Standard names: `package.json`, `tsconfig.json`, `next.config.js`
- Environment: `.env`, `.env.local`, `.env.production`

---

## 🔄 Synchronization Rules

### 1. API Contracts

**Source of Truth:** Backend OpenAPI spec  
**Generated:** Frontend TypeScript types  
**Sync Command:** `npm run generate:api-types`

```bash
# Backend changes API
cd packages/backend/api-gateway
npm run build:openapi

# Frontend generates types
cd packages/frontend/web
npm run generate:api-types
```

### 2. Design Tokens

**Source of Truth:** `packages/frontend/components/design-tokens.json`  
**Synced to:**
- `packages/frontend/web/tailwind.config.js`
- `packages/frontend/admin/tailwind.config.js`
- `docs/design-guide.md`

**Manual sync required** (update all files when design tokens change)

### 3. Smart Contract ABIs

**Source of Truth:** Contract compilation output  
**Synced to:** Frontend and backend contract directories  
**Sync Command:** Automated on contract compilation

```bash
# Compile contracts
cd packages/contracts/chaing-token
npx hardhat compile

# Copy ABIs to consumers (automated)
# → packages/frontend/web/src/contracts/
# → packages/backend/indexer/src/contracts/
```

### 4. Environment Variables

**Each package has its own `.env` file:**
- `packages/frontend/web/.env.local`
- `packages/backend/api-gateway/.env`
- `packages/contracts/chaing-token/.env`

**Documented in:** Each package's README.md

### 5. Dependencies

**CRITICAL:** Each package manages its own dependencies  
**NO shared dependencies** at root level

**Version alignment:**
- Use exact versions for critical packages
- Document version decisions in ADRs
- Run `npm audit` per package

---

## 🚨 Critical File Relationships

### Must Be In Sync

| File 1 | File 2 | Sync Method |
|--------|--------|-------------|
| Backend API spec | Frontend types | Auto-generate from OpenAPI |
| Design tokens | Tailwind configs | Manual update (notify team) |
| Contract ABIs | Frontend/Backend contracts | Auto-copy on compile |
| docs/roadmap.md | roadmap-tasks.md | Manual update (versioned) |
| Root .gitignore | Package .gitignore | Manual update (inherit root) |

### Version Control

**Git Workflow:**
```bash
main                # Production code
  └── develop       # Integration branch
      ├── feature/* # New features
      ├── fix/*     # Bug fixes
      └── docs/*    # Documentation updates
```

**Branch Naming:**
- `feature/chainghost-wallet-ui`
- `fix/indexer-memory-leak`
- `docs/update-adr-template`

---

## 📋 Checklist: Adding New Package

When adding a new package to the mono-repo:

- [ ] Create package directory under `packages/[category]/[package-name]`
- [ ] Add `package.json` with correct `name` field
- [ ] Add `README.md` documenting package purpose
- [ ] Add package to root `package.json` workspaces (if Node.js)
- [ ] Add `.gitignore` (inherit from root + package-specific)
- [ ] Add `tsconfig.json` (if TypeScript)
- [ ] Create CI workflow in `.github/workflows/[package]-ci.yml`
- [ ] Document package in this file (reference-file.md)
- [ ] Document package in root `README.md`
- [ ] Update dependency graph if package has dependencies

---

## 📋 Checklist: Adding New Documentation

When adding new documentation:

- [ ] Determine category (docs/, docs/adr/, docs/templates/)
- [ ] Use appropriate template (if available)
- [ ] Follow naming convention (kebab-case)
- [ ] Add to relevant README.md table of contents
- [ ] Add cross-references to related docs
- [ ] Update this file (reference-file.md) Documentation Map
- [ ] Update root README.md if it's a key document

---

## 🔍 Finding Files

### By Purpose

**"I want to..."**

- **Add a new page to the web app:**  
  → `packages/frontend/web/pages/[page-name].jsx`

- **Create a new API endpoint:**  
  → `packages/backend/api-gateway/src/controllers/[name].controller.ts`

- **Deploy a smart contract:**  
  → `packages/contracts/[contract-name]/scripts/deploy.js`

- **Add a runbook:**  
  → `infra/runbooks/[procedure-name].md`

- **Document an architectural decision:**  
  → `docs/adr/ADR-YYYYMMDD-[title].md`

- **Update design system:**  
  → `docs/design-guide.md` + `packages/frontend/components/design-tokens.json`

### By File Type

**Configuration files:**
```bash
find . -name "*.config.js" -not -path "*/node_modules/*"
find . -name "tsconfig.json" -not -path "*/node_modules/*"
```

**Package manifests:**
```bash
find packages -name "package.json" -not -path "*/node_modules/*"
```

**Documentation:**
```bash
find docs -name "*.md"
find . -maxdepth 2 -name "README.md"
```

---

## ✅ Validation Rules

### Pre-Commit Checks

```bash
# 1. No dependencies in root
[ ! -f "node_modules" ] || echo "ERROR: Root dependencies found!"

# 2. All packages have README
find packages -mindepth 2 -maxdepth 2 -type d -exec test -f {}/README.md \; || echo "ERROR: Missing README"

# 3. Consistent naming
find packages -name "*.jsx" | grep -v "^[A-Z]" && echo "ERROR: Component should be PascalCase"
```

### Build Validation

```bash
# All packages build successfully
for pkg in packages/*/; do
  (cd "$pkg" && npm run build) || exit 1
done
```

---

## 🔄 Maintenance Schedule

**Weekly:**
- [ ] Review dependency updates (Dependabot PRs)
- [ ] Update roadmap-tasks.md progress
- [ ] Sync design tokens if changed

**Monthly:**
- [ ] Review and update this file (reference-file.md)
- [ ] Audit cross-package dependencies
- [ ] Update documentation cross-references
- [ ] Review ADRs and mark deprecated ones

**Quarterly:**
- [ ] Full dependency audit
- [ ] Architecture review (docs/arsitektur.md)
- [ ] Refactor outdated patterns
- [ ] Update all README files

---

## 📞 Questions?

**File structure questions:**  
→ Refer to this file (reference-file.md)

**Development guidelines:**  
→ Refer to agent-rules.md

**Architectural decisions:**  
→ Check docs/adr/ or create new ADR

**Package-specific questions:**  
→ Check package README.md

---

**Maintained by:** Ghost Protocol Development Team  
**Last Updated:** November 16, 2025  
**Next Review:** December 16, 2025

---

## 🏗️ Infrastructure Status (Phase 0.4)

### Terraform Modules (70% Complete)

**Status:** In progress - modules implemented, root integration pending

**Completed Modules:**
- ✅ **networking/aws** - 3-tier VPC architecture (public, private-app, private-data subnets)
  - Multi-AZ deployment across 3 availability zones
  - NAT Gateways, Internet Gateway, VPC Endpoints
  - Security groups for ALB, EKS, RDS, Redis
  - VPC Flow Logs support
  
- ✅ **compute/aws** - EKS cluster with managed node groups
  - Kubernetes 1.28+ with OIDC provider for IRSA
  - 3 node groups (general, compute-optimized, memory-optimized)
  - Auto-scaling support with Cluster Autoscaler tags
  - KMS encryption for secrets and EBS volumes
  
- ✅ **database/aws** - RDS PostgreSQL with high availability
  - PostgreSQL 15+ with Multi-AZ deployment
  - Auto-scaling storage (gp3)
  - Read replicas support (same-region and cross-region)
  - Performance Insights and Enhanced Monitoring
  
- ✅ **storage/aws** - S3 buckets with CloudFront CDN
  - Object storage with versioning and encryption
  - CloudFront distribution for global content delivery
  - Cross-region replication support
  
- ✅ **observability/aws** - IAM roles and KMS keys
  - EKS cluster and node IAM roles
  - Pod IAM roles (IRSA support)
  - RDS enhanced monitoring role
  - KMS keys for EKS secrets, EBS, and RDS encryption

**Pending Work:**
- ⏳ Root module integration (main.tf)
- ⏳ Environment-specific tfvars configuration
- ⏳ Remote state backend deployment test

### Kubernetes Manifests (0% Complete)

**Status:** Not started

**Planned:**
- Base manifests (namespaces, ConfigMaps, Secrets)
- Deployment manifests for each service
- Service and Ingress configurations
- Kustomize overlays for dev/staging/prod
- Helm charts for complex deployments

### Monitoring Setup (0% Complete)

**Status:** Not started

**Planned:**
- Prometheus for metrics collection
- Grafana for dashboards and visualization
- Loki for log aggregation
- Jaeger for distributed tracing
- AlertManager for alerting rules

### Runbooks (0% Complete)

**Status:** Not started

**Planned Runbooks:**
- Node Recovery - Restore failed blockchain node
- Database Restore - Recover from database failure
- Incident Response - Security incident procedures
- Rollback Procedure - Revert deployment
- Disaster Recovery - Complete system recovery
