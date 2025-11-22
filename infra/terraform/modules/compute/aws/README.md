# EKS Compute Module

This module provisions an Amazon EKS (Elastic Kubernetes Service) cluster with managed node groups, OIDC provider for IRSA, and essential add-ons.

## Features

- **EKS Cluster**: Kubernetes 1.28+ with configurable endpoint access
- **OIDC Provider**: IAM Roles for Service Accounts (IRSA) support
- **Encryption**: Secrets encrypted at rest using KMS
- **Control Plane Logging**: Full audit trail of cluster API activities
- **Managed Node Groups**: Three node groups optimized for different workloads:
  - **General**: `t3.medium/large` for stateless applications
  - **Compute-Optimized**: `c5.2xlarge` for blockchain nodes
  - **Memory-Optimized**: `r5.large` for databases and caching layers
- **Auto-Scaling**: Configurable min/max/desired sizes per node group
- **Security**: IMDSv2 enforced, encrypted EBS volumes, isolated subnets
- **Add-ons**: VPC CNI, kube-proxy, CoreDNS, EBS CSI driver

## Architecture

```
┌────────────────────── EKS Cluster ──────────────────────┐
│                                                          │
│  Control Plane (Managed by AWS)                         │
│  ├─ API Server (HTTPS endpoint)                         │
│  ├─ etcd (KMS encrypted)                                │
│  ├─ Controller Manager                                  │
│  └─ Scheduler                                           │
│                                                          │
│  Node Groups (Private Subnets)                          │
│  ├─ General (t3.medium x2-5)                            │
│  │  └─ Labels: workload=general, tier=application       │
│  ├─ Compute-Optimized (c5.2xlarge x0-3)                 │
│  │  ├─ Labels: workload=compute-intensive,              │
│  │  │           tier=blockchain                         │
│  │  └─ Taints: workload=compute-intensive:NoSchedule    │
│  └─ Memory-Optimized (r5.large x0-3)                    │
│     ├─ Labels: workload=memory-intensive, tier=data     │
│     └─ Taints: workload=memory-intensive:NoSchedule     │
│                                                          │
│  Add-ons                                                 │
│  ├─ vpc-cni (networking)                                │
│  ├─ kube-proxy (service proxy)                          │
│  ├─ coredns (DNS)                                       │
│  └─ aws-ebs-csi-driver (persistent volumes)             │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

## Usage

### Basic Example

```hcl
module "eks" {
  source = "./modules/compute/aws"

  cluster_name              = "ghost-protocol-prod"
  cluster_version           = "1.28"
  cluster_role_arn          = module.observability.eks_cluster_role_arn
  node_role_arn             = module.observability.eks_node_role_arn
  private_subnet_ids        = module.networking.private_app_subnet_ids
  cluster_security_group_id = module.networking.eks_cluster_security_group_id
  nodes_security_group_id   = module.networking.eks_nodes_security_group_id
  kms_key_arn               = module.observability.kms_eks_secrets_key_arn
  ebs_kms_key_arn           = module.observability.kms_ebs_key_arn

  tags = {
    Environment = "production"
    Project     = "ghost-protocol"
    ManagedBy   = "terraform"
  }
}
```

### Production Configuration

```hcl
module "eks_prod" {
  source = "./modules/compute/aws"

  cluster_name    = "ghost-protocol-prod"
  cluster_version = "1.28"

  cluster_role_arn          = module.observability.eks_cluster_role_arn
  node_role_arn             = module.observability.eks_node_role_arn
  private_subnet_ids        = module.networking.private_app_subnet_ids
  cluster_security_group_id = module.networking.eks_cluster_security_group_id
  nodes_security_group_id   = module.networking.eks_nodes_security_group_id
  kms_key_arn               = module.observability.kms_eks_secrets_key_arn
  ebs_kms_key_arn           = module.observability.kms_ebs_key_arn

  endpoint_private_access = true
  endpoint_public_access  = false

  general_node_group_instance_types = ["t3.large"]
  general_node_group_min_size       = 2
  general_node_group_max_size       = 6
  general_node_group_desired_size   = 3

  compute_node_group_min_size     = 1
  compute_node_group_max_size     = 5
  compute_node_group_desired_size = 3

  memory_node_group_min_size     = 1
  memory_node_group_max_size     = 3
  memory_node_group_desired_size = 2

  tags = {
    Environment = "production"
    Project     = "ghost-protocol"
    ManagedBy   = "terraform"
  }
}
```

### Development Configuration

```hcl
module "eks_dev" {
  source = "./modules/compute/aws"

  cluster_name    = "ghost-protocol-dev"
  cluster_version = "1.28"

  cluster_role_arn          = module.observability.eks_cluster_role_arn
  node_role_arn             = module.observability.eks_node_role_arn
  private_subnet_ids        = module.networking.private_app_subnet_ids
  cluster_security_group_id = module.networking.eks_cluster_security_group_id
  nodes_security_group_id   = module.networking.eks_nodes_security_group_id
  kms_key_arn               = module.observability.kms_eks_secrets_key_arn
  ebs_kms_key_arn           = module.observability.kms_ebs_key_arn

  general_node_group_instance_types = ["t3.medium"]
  general_node_group_capacity_type  = "SPOT"
  general_node_group_min_size       = 1
  general_node_group_max_size       = 3
  general_node_group_desired_size   = 2

  compute_node_group_min_size     = 0
  compute_node_group_max_size     = 1
  compute_node_group_desired_size = 0

  memory_node_group_min_size     = 0
  memory_node_group_max_size     = 1
  memory_node_group_desired_size = 0

  tags = {
    Environment = "development"
    Project     = "ghost-protocol"
    ManagedBy   = "terraform"
  }
}
```

## Node Group Workload Assignment

### General Node Group
- **Workloads**: API Gateway, Frontend, Admin Dashboard
- **Characteristics**: Stateless, horizontal scaling
- **Scheduling**: No taints, pods scheduled freely

### Compute-Optimized Node Group
- **Workloads**: Blockchain validator nodes
- **Characteristics**: CPU-intensive, stateful (StatefulSets)
- **Scheduling**: Requires toleration for `workload=compute-intensive:NoSchedule`

Example pod spec:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: blockchain-node
spec:
  nodeSelector:
    workload: compute-intensive
  tolerations:
  - key: workload
    operator: Equal
    value: compute-intensive
    effect: NoSchedule
  containers:
  - name: validator
    image: chainghost/validator:latest
```

### Memory-Optimized Node Group
- **Workloads**: Redis cache, in-memory databases
- **Characteristics**: Memory-intensive, stateful
- **Scheduling**: Requires toleration for `workload=memory-intensive:NoSchedule`

Example pod spec:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: redis-cache
spec:
  nodeSelector:
    workload: memory-intensive
  tolerations:
  - key: workload
    operator: Equal
    value: memory-intensive
    effect: NoSchedule
  containers:
  - name: redis
    image: redis:7-alpine
```

## IRSA (IAM Roles for Service Accounts)

This module creates an OIDC provider for IRSA, enabling Kubernetes pods to assume IAM roles.

### Example Service Account with IRSA

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: api-gateway-sa
  namespace: production
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/api-gateway-pod-role
```

Use this output to configure pod IAM roles in the observability module:
```hcl
oidc_provider_arn = module.eks.oidc_provider_arn
```

## Accessing the Cluster

### Configure kubectl

```bash
aws eks update-kubeconfig --name ghost-protocol-prod --region us-east-1
kubectl get nodes
kubectl get pods --all-namespaces
```

### Verify Add-ons

```bash
kubectl get daemonset -n kube-system aws-node
kubectl get deployment -n kube-system coredns
kubectl get daemonset -n kube-system kube-proxy
kubectl get daemonset -n kube-system ebs-csi-node
```

## Cluster Autoscaler

Node groups are tagged for Cluster Autoscaler support:
- `k8s.io/cluster-autoscaler/<cluster-name>: owned`
- `k8s.io/cluster-autoscaler/enabled: true`

Deploy Cluster Autoscaler after cluster creation:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
```

## Security Best Practices

1. **Private Subnets**: Nodes deployed only in private subnets
2. **IMDSv2**: Instance metadata v2 enforced
3. **Encrypted EBS**: All node volumes encrypted with KMS
4. **RBAC**: Use Kubernetes RBAC for access control
5. **Network Policies**: Implement Calico or Cilium for pod-level network policies
6. **Pod Security Policies**: Enforce restricted PSPs

## Troubleshooting

### Nodes Not Joining Cluster

```bash
aws eks describe-cluster --name ghost-protocol-prod --query cluster.status
aws autoscaling describe-auto-scaling-groups
kubectl get nodes
```

Check CloudWatch Logs for node bootstrap errors:
```bash
aws logs tail /aws/eks/ghost-protocol-prod/cluster --follow
```

### Pod Scheduling Issues

```bash
kubectl describe node <node-name>
kubectl get pods -o wide
kubectl describe pod <pod-name>
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Name of the EKS cluster | string | - | yes |
| cluster_version | Kubernetes version (1.28+) | string | "1.28" | no |
| cluster_role_arn | IAM role ARN for cluster | string | - | yes |
| node_role_arn | IAM role ARN for nodes | string | - | yes |
| private_subnet_ids | Private subnet IDs | list(string) | - | yes |
| cluster_security_group_id | Cluster security group ID | string | - | yes |
| nodes_security_group_id | Nodes security group ID | string | - | yes |
| kms_key_arn | KMS key ARN for secrets | string | - | yes |
| ebs_kms_key_arn | KMS key ARN for EBS | string | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| cluster_endpoint | EKS cluster API endpoint |
| cluster_certificate_authority_data | Base64 encoded CA cert |
| oidc_provider_arn | OIDC provider ARN for IRSA |
| node_group_ids | Map of node group IDs |

## License

MIT
