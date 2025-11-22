# AWS Observability & IAM Primitives Module

## Overview

This Terraform module provides centralized observability and IAM resources for the Ghost Protocol infrastructure on AWS. It creates CloudWatch log groups, KMS encryption keys, and shared IAM roles following security best practices and compliance requirements (SOC 2, GDPR).

## Features

### CloudWatch Log Groups
- **EKS Cluster Logs**: Control plane and cluster logs
- **Application Logs**: Per-service log groups (API Gateway, Indexer, RPC Orchestrator, AI Engine)
- **VPC Flow Logs**: Network traffic monitoring (optional)
- **RDS Logs**: Database query and error logs
- **Lambda Logs**: Serverless function logs (optional)
- **Audit Logs**: Compliance and security audit trail
- **Encryption**: All logs encrypted with KMS
- **Retention**: Configurable retention policies (7/30/90/365 days)

### KMS Encryption Keys
- **EKS Secrets Key**: Encrypts Kubernetes secrets in etcd
- **RDS Key**: Database encryption at rest
- **S3 Key**: Bucket server-side encryption
- **CloudWatch Logs Key**: Log data encryption
- **EBS Key**: Worker node volume encryption
- **Key Policies**: Least privilege, no wildcard principals
- **Key Rotation**: Annual automatic rotation enabled
- **Aliases**: Easy key reference (`alias/{prefix}-eks-secrets`)

### IAM Roles
- **EKS Cluster Role**: Control plane operations
- **EKS Node Role**: Worker node operations (ECR, CloudWatch, SSM, EBS CSI)
- **IRSA Pod Roles**: Fine-grained service permissions
  - `api-gateway-role`: RDS, Secrets Manager, S3, CloudWatch
  - `indexer-role`: RDS write, S3 write, CloudWatch
  - `rpc-orchestrator-role`: EC2 describe, CloudWatch
  - `ai-engine-role`: S3, CloudWatch
- **RDS Enhanced Monitoring Role**: Database performance metrics
- **Lambda Execution Role**: Serverless function execution (optional)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Usage

### Basic Usage

```hcl
module "observability" {
  source = "../../modules/observability/aws"

  name_prefix      = "ghost-dev"
  environment      = "dev"
  eks_cluster_name = "ghost-dev-eks"
  aws_account_id   = "123456789012"
  aws_region       = "us-east-1"

  # Optional: Enable IRSA roles (requires EKS OIDC provider)
  eks_oidc_provider_arn = module.eks.oidc_provider_arn
  eks_oidc_provider_url = module.eks.oidc_provider_url

  # Log retention (compliance-based)
  eks_log_retention_days         = 7
  application_log_retention_days = 30
  vpc_flow_log_retention_days    = 7
  rds_log_retention_days         = 7
  audit_log_retention_days       = 90

  tags = {
    Project     = "GhostProtocol"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### Production Usage

```hcl
module "observability" {
  source = "../../modules/observability/aws"

  name_prefix      = "ghost-prod"
  environment      = "production"
  eks_cluster_name = "ghost-prod-eks"
  aws_account_id   = data.aws_caller_identity.current.account_id
  aws_region       = data.aws_region.current.name

  # IRSA configuration
  eks_oidc_provider_arn = module.eks.oidc_provider_arn
  eks_oidc_provider_url = module.eks.oidc_provider_url

  # Application services
  application_services  = ["api-gateway", "indexer", "rpc-orchestrator", "ai-engine"]
  rds_instance_names    = ["main", "analytics"]
  lambda_function_names = ["data-processor", "alert-handler"]

  # Compliance retention policies
  eks_log_retention_days         = 30
  application_log_retention_days = 90
  vpc_flow_log_retention_days    = 30
  rds_log_retention_days         = 30
  lambda_log_retention_days      = 90
  audit_log_retention_days       = 365

  # Enable all features
  enable_rds_enhanced_monitoring = true
  enable_lambda_roles            = true
  enable_kms_key_rotation        = true
  create_vpc_flow_log_group      = false  # Using networking module's log group

  tags = {
    Project     = "GhostProtocol"
    Environment = "production"
    ManagedBy   = "Terraform"
    Compliance  = "SOC2-GDPR"
  }
}
```

### Using Outputs in Other Modules

```hcl
# EKS Module
module "eks" {
  source = "../../modules/compute/aws"

  cluster_role_arn           = module.observability.eks_cluster_role_arn
  node_role_arn              = module.observability.eks_node_role_arn
  node_instance_profile_name = module.observability.eks_node_instance_profile_name
  
  encryption_config = {
    provider_key_arn = module.observability.kms_eks_secrets_key_arn
  }
}

# RDS Module
module "rds" {
  source = "../../modules/database/aws"

  kms_key_id                      = module.observability.kms_rds_key_id
  monitoring_role_arn             = module.observability.rds_enhanced_monitoring_role_arn
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
}

# S3 Module
module "s3" {
  source = "../../modules/storage/aws"

  kms_master_key_id = module.observability.kms_s3_key_id
}

# Kubernetes ServiceAccount (IRSA)
resource "kubernetes_service_account" "api_gateway" {
  metadata {
    name      = "api-gateway"
    namespace = var.environment
    annotations = {
      "eks.amazonaws.com/role-arn" = module.observability.api_gateway_pod_role_arn
    }
  }
}
```

### Loki HA Configuration

The module automatically creates S3 buckets and IAM roles for Loki High Availability deployment with S3 backend storage:

```hcl
module "observability" {
  source = "../../modules/observability/aws"

  name_prefix      = "ghost-prod"
  environment      = "production"
  project_name     = "ghost-protocol"
  eks_cluster_name = "ghost-prod-eks"
  aws_account_id   = data.aws_caller_identity.current.account_id
  aws_region       = data.aws_region.current.name

  # IRSA configuration (required for Loki)
  eks_oidc_provider_arn = module.eks.oidc_provider_arn
  eks_oidc_provider_url = module.eks.oidc_provider_url

  # Loki configuration
  loki_chunks_retention_days      = 30
  loki_enable_intelligent_tiering = true
  loki_namespace                  = "ghost-protocol-monitoring"
  logs_bucket_name                = "ghost-protocol-production-logs"

  tags = {
    Project     = "GhostProtocol"
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# Loki ServiceAccount with IRSA
resource "kubernetes_service_account" "loki" {
  metadata {
    name      = "loki"
    namespace = "ghost-protocol-monitoring"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.observability.loki_irsa_role_arn
    }
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# Loki ConfigMap (example S3 configuration)
resource "kubernetes_config_map" "loki_config" {
  metadata {
    name      = "loki-config"
    namespace = "ghost-protocol-monitoring"
  }

  data = {
    "loki.yaml" = yamlencode({
      schema_config = {
        configs = [{
          from         = "2024-01-01"
          store        = "tsdb"
          object_store = "s3"
          schema       = "v13"
          index = {
            prefix = "index_"
            period = "24h"
          }
        }]
      }
      storage_config = {
        aws = {
          s3                = "s3://${module.observability.loki_chunks_bucket_name}"
          s3forcepathstyle  = false
          bucketnames       = module.observability.loki_chunks_bucket_name
          region            = data.aws_region.current.name
        }
        tsdb_shipper = {
          active_index_directory = "/loki/index"
          cache_location         = "/loki/index-cache"
        }
      }
      ruler = {
        storage = {
          type = "s3"
          s3 = {
            bucketnames = module.observability.loki_ruler_bucket_name
            region      = data.aws_region.current.name
          }
        }
      }
    })
  }
}

# Output bucket names for Helm values
output "loki_buckets" {
  description = "Loki S3 bucket configuration"
  value = {
    chunks_bucket = module.observability.loki_chunks_bucket_name
    ruler_bucket  = module.observability.loki_ruler_bucket_name
    region        = data.aws_region.current.name
    irsa_role_arn = module.observability.loki_irsa_role_arn
  }
}
```

**Key Features:**
- **S3 Buckets:** 
  - `{project_name}-{environment}-loki-chunks`: Stores compressed log chunks with 30-day retention
  - `{project_name}-{environment}-loki-ruler`: Stores alerting/recording rules with versioning
- **Lifecycle Management:** Intelligent-Tiering for cost optimization (chunks transition to archive after 31 days)
- **Encryption:** KMS encryption using the S3 KMS key
- **Access Logging:** S3 access logs sent to logs bucket
- **IRSA Role:** IAM role with least-privilege S3 permissions for Loki pods
- **ServiceAccount:** Kubernetes ServiceAccount with IRSA annotation for automatic credential injection

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix for resource names | `string` | n/a | yes |
| environment | Environment name (dev, staging, production) | `string` | n/a | yes |
| eks_cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| aws_account_id | AWS account ID for KMS key policies | `string` | n/a | yes |
| aws_region | AWS region for resources | `string` | n/a | yes |
| eks_oidc_provider_arn | ARN of the EKS OIDC provider for IRSA | `string` | `""` | no |
| eks_oidc_provider_url | URL of the EKS OIDC provider for IRSA | `string` | `""` | no |
| application_services | List of application service names | `list(string)` | `["api-gateway", "indexer", "rpc-orchestrator", "ai-engine"]` | no |
| rds_instance_names | List of RDS instance names | `list(string)` | `["main"]` | no |
| lambda_function_names | List of Lambda function names | `list(string)` | `[]` | no |
| eks_log_retention_days | EKS cluster log retention in days | `number` | `7` | no |
| application_log_retention_days | Application log retention in days | `number` | `30` | no |
| vpc_flow_log_retention_days | VPC flow log retention in days | `number` | `7` | no |
| rds_log_retention_days | RDS log retention in days | `number` | `7` | no |
| lambda_log_retention_days | Lambda log retention in days | `number` | `30` | no |
| audit_log_retention_days | Audit log retention in days (compliance) | `number` | `90` | no |
| enable_kms_key_rotation | Enable automatic KMS key rotation | `bool` | `true` | no |
| kms_deletion_window_days | KMS key deletion window in days | `number` | `30` | no |
| enable_rds_enhanced_monitoring | Enable RDS enhanced monitoring IAM role | `bool` | `true` | no |
| enable_lambda_roles | Enable Lambda execution IAM roles | `bool` | `false` | no |
| create_vpc_flow_log_group | Create CloudWatch log group for VPC flow logs | `bool` | `false` | no |
| project_name | Project name for S3 bucket naming | `string` | `"ghost-protocol"` | no |
| loki_chunks_retention_days | Retention period for Loki chunks in S3 (days) | `number` | `30` | no |
| loki_enable_intelligent_tiering | Enable S3 Intelligent-Tiering for Loki chunks | `bool` | `true` | no |
| loki_namespace | Kubernetes namespace for Loki deployment | `string` | `"ghost-protocol-monitoring"` | no |
| logs_bucket_name | Name of the logs bucket for S3 access logging | `string` | `""` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

### CloudWatch Log Groups

| Name | Description |
|------|-------------|
| eks_cluster_log_group_name | Name of the EKS cluster CloudWatch log group |
| eks_cluster_log_group_arn | ARN of the EKS cluster CloudWatch log group |
| application_log_group_names | Map of application service names to log group names |
| application_log_group_arns | Map of application service names to log group ARNs |
| audit_log_group_name | Name of the audit CloudWatch log group |
| audit_log_group_arn | ARN of the audit CloudWatch log group |

### KMS Keys

| Name | Description |
|------|-------------|
| kms_eks_secrets_key_id | ID of the KMS key for EKS secrets encryption |
| kms_eks_secrets_key_arn | ARN of the KMS key for EKS secrets encryption |
| kms_rds_key_id | ID of the KMS key for RDS encryption |
| kms_rds_key_arn | ARN of the KMS key for RDS encryption |
| kms_s3_key_id | ID of the KMS key for S3 encryption |
| kms_s3_key_arn | ARN of the KMS key for S3 encryption |
| kms_cloudwatch_logs_key_id | ID of the KMS key for CloudWatch Logs encryption |
| kms_cloudwatch_logs_key_arn | ARN of the KMS key for CloudWatch Logs encryption |
| kms_ebs_key_id | ID of the KMS key for EBS volume encryption |
| kms_ebs_key_arn | ARN of the KMS key for EBS volume encryption |
| kms_keys | Map of all KMS key details (id, arn, alias) |

### IAM Roles

| Name | Description |
|------|-------------|
| eks_cluster_role_arn | ARN of the EKS cluster IAM role |
| eks_node_role_arn | ARN of the EKS node IAM role |
| eks_node_instance_profile_name | Name of the EKS node instance profile |
| api_gateway_pod_role_arn | ARN of the API Gateway pod IAM role (IRSA) |
| indexer_pod_role_arn | ARN of the Indexer pod IAM role (IRSA) |
| rpc_orchestrator_pod_role_arn | ARN of the RPC Orchestrator pod IAM role (IRSA) |
| ai_engine_pod_role_arn | ARN of the AI Engine pod IAM role (IRSA) |
| loki_irsa_role_arn | ARN of the Loki pod IAM role (IRSA) |
| loki_irsa_role_name | Name of the Loki pod IAM role (IRSA) |
| rds_enhanced_monitoring_role_arn | ARN of the RDS enhanced monitoring IAM role |
| pod_roles | Map of all pod IAM role details (arn, name) |

### Loki S3 Buckets

| Name | Description |
|------|-------------|
| loki_chunks_bucket_name | Name of the Loki chunks S3 bucket |
| loki_chunks_bucket_arn | ARN of the Loki chunks S3 bucket |
| loki_ruler_bucket_name | Name of the Loki ruler S3 bucket |
| loki_ruler_bucket_arn | ARN of the Loki ruler S3 bucket |
| loki_s3_buckets | Map of Loki S3 bucket details (chunks, ruler) |

## Security Considerations

### KMS Key Policies
- **No Wildcard Principals**: All key policies restrict access to specific services and roles
- **Least Privilege**: Each key policy grants minimum required permissions
- **Service Conditions**: Key usage restricted to specific AWS services via conditions
- **Root Account**: Root account access retained for key management (Terraform requirement)

### IAM Roles
- **Least Privilege**: Each role has minimum required permissions
- **IRSA (IAM Roles for Service Accounts)**: Fine-grained pod-level permissions
- **Service-Specific**: Roles scoped to specific Kubernetes namespaces and service accounts
- **Read-Only Where Possible**: Write permissions granted only when necessary
- **Audit Trail**: All IAM actions logged via CloudTrail

### CloudWatch Logs
- **Encryption**: All log groups encrypted with KMS
- **Retention**: Compliance-based retention policies
- **Access Control**: Log access restricted via IAM policies
- **Audit Logs**: Separate log group for compliance and security events

### Compliance
- **SOC 2**: Audit logs retained for 90+ days
- **GDPR**: Data encryption at rest and in transit
- **Key Rotation**: Annual automatic rotation enabled
- **Monitoring**: Enhanced monitoring for RDS

## Notes

### IRSA Prerequisites
IRSA pod roles are only created when both `eks_oidc_provider_arn` and `eks_oidc_provider_url` are provided. This allows the module to be used during initial infrastructure setup before EKS cluster exists.

### VPC Flow Logs
Set `create_vpc_flow_log_group = false` if using the networking module's VPC flow log group to avoid duplication.

### RDS CloudWatch Log Group Naming
**CRITICAL for Phase 0.4 Compliance**: RDS log groups must use AWS's official naming pattern to ensure logs land in managed, encrypted groups instead of auto-created unencrypted ones.

**Correct naming pattern:** `/aws/rds/instance/{db_instance_identifier}/{engine_type}`

This module creates log groups for **PostgreSQL** databases using the pattern:
```
/aws/rds/instance/${instance_name}/postgresql
```

When you configure your RDS instance with `enabled_cloudwatch_logs_exports = ["postgresql"]`, the logs will automatically flow into these pre-created, KMS-encrypted log groups.

**Engine-specific log types:**
- **PostgreSQL**: `postgresql`, `upgrade`
- **MySQL/MariaDB**: `error`, `general`, `slowquery`, `audit` (if enabled)
- **Oracle**: `alert`, `audit`, `trace`, `listener`
- **SQL Server**: `error`, `agent`

**Why this matters:**
- ❌ **Wrong pattern** (`/aws/rds/${name}`): RDS creates its own unencrypted log groups
- ✅ **Correct pattern** (`/aws/rds/instance/${name}/postgresql`): Logs use pre-created KMS-encrypted groups
- Meets SOC 2, GDPR compliance for encryption at rest
- Ensures consistent retention policies across all database logs

**For non-PostgreSQL databases:** Modify the `aws_cloudwatch_log_group.rds` resource in `main.tf` to create additional log groups with the appropriate engine suffixes.

### Service Account Annotations
When using IRSA, annotate Kubernetes service accounts with the role ARN:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: api-gateway
  namespace: production
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/ghost-prod-api-gateway-pod-role
```

### Key Deletion
KMS keys have a 30-day deletion window by default. Plan key deletion carefully in production environments.

### Cost Optimization
- Development environments can use shorter retention periods (7 days)
- Production should use compliance-based retention (30-365 days)
- KMS key requests are charged per API call; enable bucket keys for S3 to reduce costs

## References

- [ADR-005: Infrastructure & Deployment Strategy](../../../../docs/adr/ADR-20251115-005-infrastructure-deployment-strategy.md)
- [AWS KMS Best Practices](https://docs.aws.amazon.com/kms/latest/developerguide/best-practices.html)
- [EKS IAM Roles for Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [CloudWatch Logs Encryption](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html)
