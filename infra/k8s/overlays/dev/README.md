# Development Environment Deployment

This directory contains Kustomize overlays for deploying Ghost Protocol to a development Kubernetes cluster.

## Prerequisites

- **kubectl** configured for dev cluster
- **Docker Compose** running (PostgreSQL, Redis) - optional for local development
- **AWS CLI** configured (for IRSA role substitution)

## Deployment Steps

### 1. Start Local Dependencies (Optional)

If you're developing locally and not using external databases:

```bash
# From project root
docker-compose up -d postgres redis
```

### 2. Create Development Secrets

Development secrets are NOT committed to Git for security. Create them using the provided script:

```bash
cd infra/k8s/overlays/dev
./create-dev-secrets.sh
```

This creates three secrets with placeholder values:
- `database-secret` - PostgreSQL connection credentials
- `redis-secret` - Redis connection credentials
- `ai-engine-secret` - AI service API keys

**IMPORTANT**: Update the secrets with actual values for your environment:

```bash
kubectl edit secret database-secret -n ghost-protocol-dev
kubectl edit secret redis-secret -n ghost-protocol-dev
kubectl edit secret ai-engine-secret -n ghost-protocol-dev
```

### 3. Substitute AWS Account ID

All ServiceAccount patches use the `REPLACE_WITH_AWS_ACCOUNT_ID` placeholder. Run the substitution script to replace it with your actual AWS account ID:

```bash
cd infra/k8s
./substitute-aws-account-id.sh
```

Or manually replace the placeholder in all `*-sa-patch.yaml` files:

```bash
# Get your AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Replace in all patch files
find overlays/dev -name "*-sa-patch.yaml" -exec sed -i "s/REPLACE_WITH_AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" {} \;
```

### 4. Apply Kubernetes Manifests

```bash
# From infra/k8s/overlays/dev directory
kubectl apply -k .
```

Or from the project root:

```bash
kubectl apply -k infra/k8s/overlays/dev
```

### 5. Verify Deployment

```bash
# Check pods
kubectl get pods -n ghost-protocol-dev

# Check services
kubectl get svc -n ghost-protocol-dev

# Check deployments
kubectl get deployments -n ghost-protocol-dev

# View logs
kubectl logs -n ghost-protocol-dev -l app=api-gateway --tail=50
```

## Configuration

### Resource Allocation

Development environment uses minimal resources:

| Service | Replicas | CPU Request | Memory Request | CPU Limit | Memory Limit |
|---------|----------|-------------|----------------|-----------|--------------|
| **api-gateway** | 2 | 100m | 256Mi | 500m | 512Mi |
| **indexer** | 1 | 200m | 384Mi | 800m | 768Mi |
| **rpc-orchestrator** | 1 | 150m | 256Mi | 600m | 512Mi |
| **ai-engine** | 1 | 250m | 1Gi | 1000m | 2Gi |

### Auto-scaling

HPA (Horizontal Pod Autoscaler) settings:

- **api-gateway**: 2-4 replicas
- **indexer**: 1-3 replicas
- **rpc-orchestrator**: 1-3 replicas
- **ai-engine**: 1-2 replicas

## Updating the Deployment

After making changes to manifests:

```bash
kubectl apply -k .
```

To force a rollout restart:

```bash
kubectl rollout restart deployment -n ghost-protocol-dev
```

## Cleanup

To remove all resources:

```bash
kubectl delete -k .
```

To remove just the secrets:

```bash
kubectl delete secret database-secret redis-secret ai-engine-secret -n ghost-protocol-dev
```

## Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n ghost-protocol-dev

# Check events
kubectl get events -n ghost-protocol-dev --sort-by='.lastTimestamp'
```

### Secret not found errors

Make sure you've run the `create-dev-secrets.sh` script:

```bash
./create-dev-secrets.sh
```

### IRSA authentication errors

Verify that AWS account ID has been substituted in ServiceAccount patches:

```bash
grep -r "REPLACE_WITH_AWS_ACCOUNT_ID" .
```

If found, run the substitution script.

## Security Notes

- Development secrets use placeholder values and should be updated with real (but non-production) credentials
- Never commit actual credentials to Git
- For production deployments, use AWS Secrets Manager with External Secrets Operator
- IRSA role ARNs are environment-specific and auto-substituted during deployment

## Next Steps

After successful deployment:

1. Test service endpoints
2. Verify database connections
3. Check monitoring dashboards (Grafana)
4. Review logs for any errors

For production deployment, see `../production/README.md`.
