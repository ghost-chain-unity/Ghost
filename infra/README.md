# Infrastructure

Infrastructure as Code (IaC) for Ghost Protocol deployment and operations.

## Structure

```
infra/
├── terraform/      # Infrastructure provisioning
├── k8s/            # Kubernetes manifests
└── runbooks/       # Operational procedures
```

## Terraform

Infrastructure provisioning for cloud resources.

### Directory Structure

```
terraform/
├── modules/        # Reusable Terraform modules
├── environments/
│   ├── dev/
│   ├── staging/
│   └── production/
└── README.md
```

### Usage

```bash
cd terraform/environments/dev

# Initialize
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy (careful!)
terraform destroy
```

### Status
📋 Planned (not implemented)

## Kubernetes (k8s)

Kubernetes manifests for service deployment.

### Directory Structure

```
k8s/
├── base/           # Base configurations (Kustomize)
├── overlays/
│   ├── dev/
│   ├── staging/
│   └── production/
└── helm/           # Helm charts
```

### Usage

```bash
# Apply base config
kubectl apply -k k8s/base

# Apply environment-specific config
kubectl apply -k k8s/overlays/production

# Using Helm
helm install ghost-protocol k8s/helm/ghost-protocol
```

### Status
📋 Planned (not implemented)

## Runbooks

Operational procedures for critical flows.

### Required Runbooks

- **Node Recovery** - Restore failed blockchain node
- **Database Restore** - Recover from database failure
- **Incident Response** - Security incident procedures
- **Rollback Procedure** - Revert deployment
- **Disaster Recovery** - Complete system recovery

### Format

Each runbook follows this structure:

```markdown
# [Procedure Name]

**Status:** [Active | Deprecated]
**Last Updated:** YYYY-MM-DD
**Owner:** [Team/Person]

## Overview
[Brief description]

## Prerequisites
- [Prerequisite 1]
- [Prerequisite 2]

## Procedure
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Verification
- [ ] [Check 1]
- [ ] [Check 2]

## Rollback
[How to undo if needed]

## Notes
[Additional context]
```

### Status
📋 Planned (not implemented)

## Best Practices

### Infrastructure as Code
- ✅ All infrastructure versioned in Git
- ✅ No manual infrastructure changes
- ✅ Use Terraform for provisioning
- ✅ Use Helm for Kubernetes deployments
- ✅ Environment parity (dev, staging, prod)

### Security
- ✅ Secrets in Vault / KMS (never in code)
- ✅ Network policies for service isolation
- ✅ Resource limits on all containers
- ✅ Regular security scans

### Monitoring
- ✅ Prometheus for metrics
- ✅ Grafana for dashboards
- ✅ Loki for logs
- ✅ Jaeger for tracing
- ✅ PagerDuty for alerting

## Environment Variables

Required environment variables are documented per-environment:
- `terraform/environments/dev/README.md`
- `k8s/overlays/production/README.md`

## Deployment Process

1. **Terraform** provisions infrastructure
2. **Kubernetes** deploys services
3. **Monitoring** verifies health
4. **Runbooks** handle incidents

---

**Last Updated:** November 15, 2025
