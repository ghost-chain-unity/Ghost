# Kubernetes Manifests

This directory contains Kubernetes manifests for deploying Ghost Protocol services to EKS clusters.

## Directory Structure

```
k8s/
├── base/                    # Base manifests (environment-agnostic)
│   ├── namespace.yaml
│   ├── api-gateway/        # API Gateway service
│   ├── indexer/            # Blockchain indexer service
│   ├── rpc-orchestrator/   # RPC orchestration service
│   ├── ai-engine/          # AI/ML service
│   └── monitoring/         # Prometheus + Grafana stack
├── overlays/               # Environment-specific overlays (Kustomize)
│   ├── dev/               # Development environment
│   ├── staging/           # Staging environment
│   └── production/        # Production environment
└── helm/                  # Helm charts (future)
```

## Deployment Strategy

We use **Kustomize** for managing environment-specific configurations:

1. **Base manifests** define core resources (Deployments, Services, ConfigMaps)
2. **Overlays** patch base manifests with environment-specific values (replicas, resources, images)

## Prerequisites

- kubectl >= 1.28
- kustomize >= 5.0 (built into kubectl)
- AWS CLI configured
- EKS cluster access (kubeconfig)

## Quick Start

### 1. Configure kubectl for EKS

```bash
aws eks update-kubeconfig --name ghost-protocol-prod --region us-east-1
kubectl get nodes
```

### 2. Deploy to Development

```bash
kubectl apply -k overlays/dev
```

### 3. Deploy to Staging

```bash
kubectl apply -k overlays/staging
```

### 4. Deploy to Production

```bash
kubectl apply -k overlays/production
```

## Verify Deployment

```bash
# Check all resources
kubectl get all -n ghost-protocol-prod

# Check pods
kubectl get pods -n ghost-protocol-prod

# Check services
kubectl get svc -n ghost-protocol-prod

# Check ingress
kubectl get ingress -n ghost-protocol-prod

# View logs
kubectl logs -n ghost-protocol-prod -l app=api-gateway --tail=100 -f
```

## Services

### API Gateway
- **Port:** 3000
- **Type:** ClusterIP (exposed via Ingress)
- **Replicas:** Dev: 2, Staging: 2, Prod: 3
- **Resources:** See overlays for environment-specific limits

### Indexer
- **Port:** 3001
- **Type:** ClusterIP (internal only)
- **Replicas:** Dev: 1, Staging: 2, Prod: 3
- **Resources:** See overlays for environment-specific limits

### RPC Orchestrator
- **Port:** 3002
- **Type:** ClusterIP (internal only)
- **Replicas:** Dev: 1, Staging: 2, Prod: 3
- **Resources:** See overlays for environment-specific limits

### AI Engine
- **Port:** 3003
- **Type:** ClusterIP (internal only)
- **Replicas:** Dev: 1, Staging: 1, Prod: 2
- **Resources:** See overlays for environment-specific limits

## Monitoring

Prometheus and Grafana are deployed in the `ghost-protocol-monitoring` namespace:

```bash
# Check monitoring stack
kubectl get all -n ghost-protocol-monitoring

# Access Grafana (port-forward)
kubectl port-forward -n ghost-protocol-monitoring svc/grafana 3000:3000

# Access Prometheus (port-forward)
kubectl port-forward -n ghost-protocol-monitoring svc/prometheus 9090:9090
```

Default credentials:
- Grafana: admin / admin (change on first login)

## Secrets Management

Secrets are managed using AWS Secrets Manager with IRSA (IAM Roles for Service Accounts):

1. Create secrets in AWS Secrets Manager
2. Service accounts are annotated with IAM role ARN (from Terraform observability module)
3. Pods can access secrets via AWS SDK

Example secret creation:

```bash
aws secretsmanager create-secret \
  --name ghost-protocol/prod/database-url \
  --secret-string "postgresql://user:pass@rds-endpoint:5432/db" \
  --region us-east-1
```

## Troubleshooting

### Pods not starting

```bash
kubectl describe pod <pod-name> -n ghost-protocol-prod
kubectl logs <pod-name> -n ghost-protocol-prod --previous
```

### ImagePullBackOff

```bash
# Check ECR authentication
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <aws-account-id>.dkr.ecr.us-east-1.amazonaws.com

# Verify image exists
aws ecr describe-images --repository-name ghost-protocol/api-gateway --region us-east-1
```

### Service not accessible

```bash
kubectl get svc -n ghost-protocol-prod
kubectl get endpoints -n ghost-protocol-prod
kubectl describe ingress -n ghost-protocol-prod
```

## Scaling

### Manual Scaling

```bash
kubectl scale deployment api-gateway --replicas=5 -n ghost-protocol-prod
```

### Horizontal Pod Autoscaling (HPA)

HPA is configured for all services based on CPU/memory utilization:

```bash
kubectl get hpa -n ghost-protocol-prod
```

## Updates and Rollouts

### Update Image

```bash
kubectl set image deployment/api-gateway api-gateway=<new-image> -n ghost-protocol-prod
```

### Check Rollout Status

```bash
kubectl rollout status deployment/api-gateway -n ghost-protocol-prod
```

### Rollback

```bash
kubectl rollout undo deployment/api-gateway -n ghost-protocol-prod
```

## Clean Up

```bash
# Delete all resources in an environment
kubectl delete -k overlays/dev

# Delete monitoring stack
kubectl delete -k base/monitoring
```

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kustomize Documentation](https://kustomize.io/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
