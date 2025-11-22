# ArgoCD Setup Guide for Ghost Protocol

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [ArgoCD Applications](#argocd-applications)
- [RBAC Configuration](#rbac-configuration)
- [Access Control](#access-control)
- [Sync Policies](#sync-policies)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

---

## Overview

This guide provides step-by-step instructions for setting up **ArgoCD** as the GitOps deployment platform for the Ghost Protocol Web3 Super-App ecosystem.

### What is ArgoCD?

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes. It automates the deployment of applications from Git repositories to Kubernetes clusters, ensuring that the desired state in Git matches the actual state in the cluster.

### Benefits for Ghost Protocol

- ✅ **Declarative GitOps** - All deployment configuration versioned in Git
- ✅ **Automated Sync** - Continuous delivery for dev/staging environments
- ✅ **Manual Approval** - Production deployments require explicit approval
- ✅ **Rollback Capability** - Easy rollback to any previous Git commit
- ✅ **Multi-Environment** - Manage dev, staging, and production from one interface
- ✅ **RBAC** - Fine-grained access control for different teams
- ✅ **Audit Trail** - Complete history of all deployments

---

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                        ArgoCD Architecture                            │
└──────────────────────────────────────────────────────────────────────┘

┌────────────────┐         ┌────────────────────────────────────────┐
│  Git Repository │◄────────│         ArgoCD Server               │
│  (GitHub)       │         │  - UI Dashboard                        │
│                 │         │  - API Server                          │
│  - base/        │         │  - RBAC Engine                         │
│  - overlays/    │         └────────────────────────────────────────┘
│    - dev/       │                        │
│    - staging/   │                        │
│    - prod/      │                        ▼
└────────────────┘         ┌────────────────────────────────────────┐
                           │     ArgoCD Application Controller      │
                           │  - Sync Loop (every 3 minutes)         │
                           │  - Health Checks                       │
                           │  - Auto-Healing                        │
                           └────────────────────────────────────────┘
                                          │
                                          ▼
         ┌────────────────────────────────────────────────────────────┐
         │                    Kubernetes Cluster                       │
         │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
         │  │ ghost-       │  │ ghost-       │  │ ghost-       │   │
         │  │ protocol-dev │  │ protocol-    │  │ protocol-prod│   │
         │  │              │  │ staging      │  │              │   │
         │  │ Auto-Sync ✅ │  │ Auto-Sync ✅ │  │ Manual Sync ⚠│   │
         │  └──────────────┘  └──────────────┘  └──────────────┘   │
         └────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

1. **Kubernetes Cluster Running**
   - EKS cluster deployed via Terraform
   - kubectl configured with cluster access
   - Cluster admin permissions

2. **Git Repository**
   - Ghost Protocol repository accessible
   - SSH/HTTPS credentials configured

3. **Tools Installed**
   - kubectl (v1.20+)
   - argocd CLI (v2.8+)
   - kustomize (v4.5+)

4. **Infrastructure Ready**
   - All Kustomize overlays configured with replacements pattern
   - .env files generated for each environment
   - IRSA roles created (for production)

---

## Installation

### Step 1: Install ArgoCD

```bash
# Navigate to ArgoCD directory
cd infra/k8s/argocd

# Apply ArgoCD installation
kubectl apply -k base/

# Wait for ArgoCD pods to be ready
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
```

**Expected Output:**
```
namespace/argocd created
customresourcedefinition.apiextensions.k8s.io/applications.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/applicationsets.argoproj.io created
customresourcedefinition.apiextensions.k8s.io/appprojects.argoproj.io created
...
deployment.apps/argocd-server created
deployment.apps/argocd-repo-server created
deployment.apps/argocd-application-controller created
...
pod/argocd-server-xxx condition met
pod/argocd-repo-server-xxx condition met
pod/argocd-application-controller-xxx condition met
```

### Step 2: Verify Installation

```bash
# Check all ArgoCD pods are running
kubectl get pods -n argocd

# Expected output:
# NAME                                  READY   STATUS    RESTARTS   AGE
# argocd-application-controller-xxx     1/1     Running   0          2m
# argocd-dex-server-xxx                 1/1     Running   0          2m
# argocd-redis-xxx                      1/1     Running   0          2m
# argocd-repo-server-xxx                1/1     Running   0          2m
# argocd-server-xxx                     1/1     Running   0          2m
```

### Step 3: Install ArgoCD CLI

**macOS:**
```bash
brew install argocd
```

**Linux:**
```bash
# Download latest ArgoCD CLI
VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v$VERSION/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
```

**Verify:**
```bash
argocd version --client
```

### Step 4: Access ArgoCD UI

**Option A: Port Forward (Development)**
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Access at: https://localhost:8080

**Option B: LoadBalancer (Production)**
```bash
# Create LoadBalancer service
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Get external IP
kubectl get svc argocd-server -n argocd
```

### Step 5: Get Initial Admin Password

```bash
# Get initial admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Admin Password: $ARGOCD_PASSWORD"
```

### Step 6: Login via CLI

```bash
# Login to ArgoCD
argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure

# Change admin password (recommended)
argocd account update-password
```

---

## Configuration

### Update Repository URL

Before deploying applications, update the repository URL in all Application manifests:

```bash
# Find and replace placeholder repository URL
cd infra/k8s/argocd/applications
sed -i 's|https://github.com/your-org/ghost-protocol.git|https://github.com/YOUR_ACTUAL_ORG/ghost-protocol.git|g' *.yaml
```

### Configure Repository Access

**For Private Repositories:**

```bash
# Add repository credentials
argocd repo add https://github.com/your-org/ghost-protocol.git \
  --username your-username \
  --password your-token \
  --name ghost-protocol-repo

# Verify repository is connected
argocd repo list
```

**For SSH Access:**

```bash
# Add SSH repository
argocd repo add git@github.com:your-org/ghost-protocol.git \
  --ssh-private-key-path ~/.ssh/id_rsa \
  --name ghost-protocol-repo
```

---

## ArgoCD Applications

### Deploy AppProject

```bash
# Deploy the Ghost Protocol AppProject
kubectl apply -f infra/k8s/argocd/applications/appproject-ghost-protocol.yaml

# Verify AppProject
argocd proj get ghost-protocol
```

### Deploy Applications

**Deploy All Applications at Once:**
```bash
# Deploy all applications for all environments
kubectl apply -k infra/k8s/argocd/applications/

# This creates:
# - 4 services × 3 environments = 12 applications
```

**Deploy Specific Environment:**
```bash
# Deploy only development applications
kubectl apply -f infra/k8s/argocd/applications/*-dev.yaml

# Deploy only staging applications
kubectl apply -f infra/k8s/argocd/applications/*-staging.yaml

# Deploy only production applications
kubectl apply -f infra/k8s/argocd/applications/*-prod.yaml
```

### Verify Applications

```bash
# List all applications
argocd app list

# Get specific application status
argocd app get api-gateway-dev

# Watch application sync
argocd app sync api-gateway-dev --watch
```

---

## RBAC Configuration

### User Roles

ArgoCD is configured with 4 roles:

| Role | Permissions | Use Case |
|------|-------------|----------|
| **admin** | Full access to all resources | Platform administrators |
| **developer** | Full access to dev/staging, read-only to prod | Development team |
| **prod-operator** | Sync production apps only | Operations team |
| **readonly** | View-only access | Auditors, stakeholders |

### Create Local Users

```bash
# Create developer user
argocd account update-password --account developer --new-password 'dev-password'

# Create prod-operator user
argocd account update-password --account prod-operator --new-password 'ops-password'

# Create readonly user (API key only, no login)
argocd account generate-token --account readonly
```

### Test User Permissions

```bash
# Login as developer
argocd login localhost:8080 --username developer --password dev-password --insecure

# Try to sync dev application (should succeed)
argocd app sync api-gateway-dev

# Try to delete prod application (should fail)
argocd app delete api-gateway-prod
# Expected: permission denied
```

---

## Access Control

### Project-Level RBAC

The Ghost Protocol AppProject defines role bindings:

```yaml
roles:
- name: developer
  policies:
  - p, proj:ghost-protocol:developer, applications, *, ghost-protocol/ghost-protocol-dev*, allow
  - p, proj:ghost-protocol:developer, applications, *, ghost-protocol/ghost-protocol-staging*, allow
  groups:
  - github:developer-team

- name: prod-operator
  policies:
  - p, proj:ghost-protocol:prod-operator, applications, sync, ghost-protocol/ghost-protocol-prod*, allow
  groups:
  - github:ops-team
```

### Global RBAC Policies

Located in: `infra/k8s/argocd/base/argocd-rbac-cm.yaml`

**Key policies:**
```
# Developers can manage dev/staging
p, role:developer, applications, *, ghost-protocol-dev/*, allow
p, role:developer, applications, *, ghost-protocol-staging/*, allow

# Production operators can only sync production
p, role:prod-operator, applications, sync, ghost-protocol-prod/*, allow

# Default policy is readonly
policy.default: role:readonly
```

---

## Sync Policies

### Automated Sync (Dev & Staging)

Dev and staging environments use automated sync:

```yaml
syncPolicy:
  automated:
    prune: true        # Delete resources not in Git
    selfHeal: true     # Auto-correct manual changes
    allowEmpty: false  # Prevent empty sync
  syncOptions:
  - CreateNamespace=true
  - PrunePropagationPolicy=foreground
  retry:
    limit: 5
    backoff:
      duration: 5s
      factor: 2
      maxDuration: 3m
```

**Behavior:**
- ArgoCD checks Git every 3 minutes
- Automatically applies changes found in Git
- Reverts any manual kubectl changes (selfHeal)
- Retries on failure with exponential backoff

### Manual Sync (Production)

Production applications require manual approval:

```yaml
syncPolicy:
  # No automated section - manual sync only
  syncOptions:
  - CreateNamespace=true
  - PrunePropagationPolicy=foreground
  retry:
    limit: 3
```

**Workflow:**
1. Developer/Operator reviews changes in Git
2. Manually triggers sync via UI or CLI
3. ArgoCD applies changes
4. Manual verification before marking healthy

### Sync Production Application

```bash
# Review changes before syncing
argocd app diff api-gateway-prod

# Dry-run sync (preview)
argocd app sync api-gateway-prod --dry-run

# Actually sync
argocd app sync api-gateway-prod

# Watch sync progress
argocd app sync api-gateway-prod --watch
```

---

## Troubleshooting

### Issue 1: Application Not Syncing

**Symptoms:**
- Application stuck in "OutOfSync" state
- Sync fails with errors

**Diagnosis:**
```bash
# Check application status
argocd app get api-gateway-dev

# View sync errors
argocd app sync api-gateway-dev --dry-run

# Check logs
kubectl logs -n argocd deployment/argocd-application-controller
```

**Common Causes:**
1. **Invalid Kustomize configuration** - Check `kustomization.yaml` syntax
2. **Missing .env file** - Generate .env using automation script
3. **Repository access denied** - Verify repository credentials
4. **Resource quota exceeded** - Check namespace quotas

**Solution:**
```bash
# Regenerate .env file
cd infra/k8s
./scripts/generate-env-from-terraform.sh dev

# Validate Kustomize build
kubectl kustomize overlays/dev

# Force refresh
argocd app get api-gateway-dev --refresh
```

### Issue 2: Plugin Not Found (kustomize-replacements)

**Error:**
```
plugin 'kustomize-replacements' not found
```

**Solution:**

The Config Management Plugin is defined in `argocd-cm.yaml`:

```yaml
configManagementPlugins: |
  - name: kustomize-replacements
    generate:
      command: ["sh", "-c"]
      args:
        - |
          if [ ! -f .env ]; then
            echo "WARNING: .env file not found, using .env.example"
            cp .env.example .env
          fi
          kustomize build --enable-alpha-plugins .
```

Verify ArgoCD ConfigMap was applied:
```bash
kubectl get cm argocd-cm -n argocd -o yaml | grep kustomize-replacements
```

### Issue 3: RBAC Permission Denied

**Symptoms:**
- User cannot perform action (sync, delete, etc.)
- "permission denied" errors

**Diagnosis:**
```bash
# Check user's effective permissions
argocd account can-i sync applications '*'

# View RBAC policy
kubectl get cm argocd-rbac-cm -n argocd -o yaml
```

**Solution:**

Update RBAC policy in `argocd-rbac-cm.yaml`:

```yaml
policy.csv: |
  # Add specific permission
  p, role:developer, applications, sync, ghost-protocol-dev/api-gateway-dev, allow
```

Apply changes:
```bash
kubectl apply -f infra/k8s/argocd/base/argocd-rbac-cm.yaml
```

### Issue 4: Application Health Unknown

**Symptoms:**
- Application shows "Unknown" health status
- Resources created but health check fails

**Diagnosis:**
```bash
# Check resource health
argocd app get api-gateway-dev --show-operation

# Check pod status
kubectl get pods -n ghost-protocol-dev
```

**Common Causes:**
1. Custom resource without health check definition
2. Pod stuck in ImagePullBackOff
3. Missing liveness/readiness probes

**Solution:**

Add custom health check in `argocd-cm.yaml`:
```yaml
resource.customizations: |
  networking.k8s.io/Ingress:
    health.lua: |
      hs = {}
      hs.status = "Healthy"
      return hs
```

---

## Best Practices

### 1. Environment Promotion Strategy

```
Development (Auto-Sync)
    │
    ├─► Git Push → Auto Deploy
    │
    ▼
Staging (Auto-Sync)
    │
    ├─► Automated Tests
    │
    ▼
Production (Manual Sync)
    │
    ├─► Manual Review
    ├─► Manual Sync
    └─► Post-Deployment Verification
```

### 2. Git Workflow

**Feature Development:**
```bash
# 1. Create feature branch
git checkout -b feature/new-api-endpoint

# 2. Make changes to overlays/dev
vim infra/k8s/overlays/dev/api-gateway-configmap.yaml

# 3. Commit and push
git commit -am "Add new API endpoint configuration"
git push origin feature/new-api-endpoint

# 4. ArgoCD auto-syncs to dev environment

# 5. Test in dev, then merge to main for staging
git checkout main
git merge feature/new-api-endpoint
git push origin main

# 6. ArgoCD auto-syncs to staging

# 7. Manual sync to production after approval
argocd app sync api-gateway-prod
```

### 3. Rollback Procedure

**Quick Rollback:**
```bash
# Rollback to previous version
argocd app rollback api-gateway-prod

# Rollback to specific revision
argocd app rollback api-gateway-prod 5
```

**Git-Based Rollback:**
```bash
# Revert Git commit
git revert HEAD
git push origin main

# Sync to apply rollback
argocd app sync api-gateway-prod
```

### 4. Monitoring and Alerts

**Key Metrics to Monitor:**
- Application sync status
- Sync failure rate
- Time to sync
- Number of out-of-sync resources

**Setup Prometheus Monitoring:**
```bash
# ArgoCD exposes metrics at :8082/metrics
kubectl port-forward -n argocd svc/argocd-metrics 8082:8082
```

**Example Alerts:**
```yaml
- alert: ArgoCDAppOutOfSync
  expr: argocd_app_info{sync_status="OutOfSync"} > 0
  for: 10m
  annotations:
    summary: "ArgoCD application {{ $labels.name }} is out of sync"
```

### 5. Backup and Disaster Recovery

**Backup ArgoCD Configuration:**
```bash
# Backup all ArgoCD resources
kubectl get applications -n argocd -o yaml > argocd-apps-backup.yaml
kubectl get appprojects -n argocd -o yaml > argocd-projects-backup.yaml
kubectl get secrets -n argocd -o yaml > argocd-secrets-backup.yaml
```

**Restore:**
```bash
kubectl apply -f argocd-apps-backup.yaml
kubectl apply -f argocd-projects-backup.yaml
```

---

## References

- [ArgoCD Official Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [Kustomize Documentation](https://kustomize.io/)
- [GitOps Principles](https://www.gitops.tech/)

---

## Support

For issues or questions:
1. Check ArgoCD application logs: `kubectl logs -n argocd deployment/argocd-application-controller`
2. Review ArgoCD UI for sync errors
3. Verify Kustomize build: `kubectl kustomize overlays/{env}`
4. Check repository access: `argocd repo list`
