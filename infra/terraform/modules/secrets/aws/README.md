# AWS Secrets Management Module

## Overview

This Terraform module provides centralized secrets management for the Ghost Protocol infrastructure on AWS. It creates AWS Secrets Manager secrets, automatic rotation Lambda functions, and IAM roles for secure secret access following security best practices and compliance requirements (SOC 2, GDPR, ADR-005).

## Features

### AWS Secrets Manager Integration
- **Database Credentials**: JSON-formatted secret with username, password, host, port, and database name
- **Redis Password**: Secure cache authentication
- **OpenAI API Key**: External AI service integration
- **Hugging Face API Key**: ML model access
- **KMS Encryption**: All secrets encrypted using existing `eks_secrets` KMS key from observability module
- **Placeholder Values**: Initial values are placeholders for manual update post-deployment
- **CloudTrail Logging**: Automatic audit trail for all secret access (account-level)

### Automatic Secret Rotation
- **Lambda Function**: Node.js 20 runtime for RDS PostgreSQL password rotation
- **Rotation Schedule**: Configurable rotation period (default: 30 days per ADR-005)
- **4-Step Process**: AWS recommended rotation strategy (createSecret, setSecret, testSecret, finishSecret)
- **VPC Integration**: Lambda deployed in VPC for secure RDS access
- **Zero Downtime**: Seamless credential rotation without service interruption
- **IAM Permissions**: Least privilege access for rotation Lambda

### IRSA (IAM Roles for Service Accounts)
- **External Secrets Operator Role**: Fine-grained access for Kubernetes secret sync
- **Conditional Creation**: Only created when EKS OIDC provider is available (two-stage deployment)
- **Least Privilege**: Access only to Ghost Protocol secrets and KMS decrypt
- **Namespace Isolation**: ServiceAccount scoped to `external-secrets` namespace

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 4.0 |

## Dependencies

This module requires outputs from the observability module:
- `eks_secrets_kms_key_arn`: KMS key for secret encryption
- `eks_oidc_provider_arn`: EKS OIDC provider ARN (for IRSA)
- `eks_oidc_provider_url`: EKS OIDC provider URL (for IRSA)

## Usage

### Basic Usage (Without Rotation)

```hcl
module "secrets" {
  source = "../../modules/secrets/aws"

  name_prefix             = "ghost-dev"
  environment             = "dev"
  aws_region              = "us-east-1"
  aws_account_id          = "123456789012"
  eks_secrets_kms_key_arn = module.observability.kms_eks_secrets_key_arn

  # Database configuration (for secret values)
  database_username       = "ghostadmin"
  database_name           = "ghostprotocol"
  rds_instance_endpoint   = "ghost-dev-db.cluster-abc123.us-east-1.rds.amazonaws.com:5432"

  tags = {
    Project     = "GhostProtocol"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

### Production Usage (With Rotation and IRSA)

```hcl
module "secrets" {
  source = "../../modules/secrets/aws"

  name_prefix             = "ghost-prod"
  environment             = "production"
  aws_region              = data.aws_region.current.name
  aws_account_id          = data.aws_caller_identity.current.account_id
  eks_secrets_kms_key_arn = module.observability.kms_eks_secrets_key_arn

  # IRSA configuration (requires EKS cluster)
  eks_oidc_provider_arn = module.compute.oidc_provider_arn
  eks_oidc_provider_url = module.compute.oidc_provider_url

  # Database configuration
  database_username         = "ghostadmin"
  database_name             = "ghostprotocol"
  rds_instance_endpoint     = module.database.cluster_endpoint
  rds_instance_identifier   = module.database.cluster_id

  # Enable automatic rotation (requires VPC configuration)
  enable_rotation         = true
  database_rotation_days  = 30
  vpc_subnet_ids          = module.networking.private_subnet_ids
  vpc_security_group_ids  = [module.database.security_group_id]

  tags = {
    Project     = "GhostProtocol"
    Environment = "production"
    ManagedBy   = "Terraform"
    Compliance  = "SOC2-GDPR"
  }
}
```

### Two-Stage Deployment Strategy

For new environments where EKS doesn't exist yet:

**Stage 1: Deploy secrets without IRSA**
```hcl
module "secrets" {
  source = "../../modules/secrets/aws"

  name_prefix             = "ghost-staging"
  environment             = "staging"
  aws_region              = var.aws_region
  aws_account_id          = var.aws_account_id
  eks_secrets_kms_key_arn = module.observability.kms_eks_secrets_key_arn

  # IRSA not configured yet - will be added in Stage 2
  # eks_oidc_provider_arn = ""  # Default
  # eks_oidc_provider_url = ""  # Default

  tags = var.tags
}
```

**Stage 2: Add IRSA after EKS deployment**
```hcl
module "secrets" {
  source = "../../modules/secrets/aws"

  # ... (same as Stage 1)

  # Add IRSA configuration
  eks_oidc_provider_arn = module.compute.oidc_provider_arn
  eks_oidc_provider_url = module.compute.oidc_provider_url

  tags = var.tags
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name_prefix | Prefix for resource names | `string` | n/a | yes |
| environment | Environment name (dev, staging, prod/production) | `string` | n/a | yes |
| aws_region | AWS region for resources | `string` | n/a | yes |
| aws_account_id | AWS account ID for ARN construction | `string` | n/a | yes |
| eks_secrets_kms_key_arn | ARN of the KMS key for secrets encryption (from observability module) | `string` | n/a | yes |
| eks_oidc_provider_arn | ARN of the EKS OIDC provider for IRSA (leave empty if EKS not yet created) | `string` | `""` | no |
| eks_oidc_provider_url | URL of the EKS OIDC provider for IRSA (leave empty if EKS not yet created) | `string` | `""` | no |
| database_rotation_days | Number of days between automatic database credential rotation | `number` | `30` | no |
| rds_instance_endpoint | RDS instance endpoint for rotation Lambda (format: hostname:port) | `string` | `""` | no |
| rds_instance_identifier | RDS instance identifier for rotation Lambda | `string` | `""` | no |
| database_name | Database name for rotation Lambda | `string` | `"ghostprotocol"` | no |
| database_username | Master database username for rotation Lambda | `string` | `"ghostadmin"` | no |
| vpc_subnet_ids | VPC subnet IDs for rotation Lambda (required for RDS access) | `list(string)` | `[]` | no |
| vpc_security_group_ids | VPC security group IDs for rotation Lambda (required for RDS access) | `list(string)` | `[]` | no |
| enable_rotation | Enable automatic rotation for database credentials | `bool` | `false` | no |
| tags | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| secret_arns | Map of secret names to their ARNs |
| database_secret_arn | ARN of the database credentials secret |
| database_secret_name | Name of the database credentials secret |
| redis_secret_arn | ARN of the Redis password secret |
| redis_secret_name | Name of the Redis password secret |
| openai_api_key_secret_arn | ARN of the OpenAI API key secret |
| openai_api_key_secret_name | Name of the OpenAI API key secret |
| huggingface_api_key_secret_arn | ARN of the Hugging Face API key secret |
| huggingface_api_key_secret_name | Name of the Hugging Face API key secret |
| rotation_lambda_arn | ARN of the rotation Lambda function (null if rotation disabled) |
| rotation_lambda_name | Name of the rotation Lambda function (null if rotation disabled) |
| rotation_lambda_role_arn | ARN of the rotation Lambda execution role (null if rotation disabled) |
| external_secrets_operator_role_arn | ARN of the External Secrets Operator IAM role (null if IRSA not configured) |
| external_secrets_operator_role_name | Name of the External Secrets Operator IAM role (null if IRSA not configured) |
| secret_names | Map of secret purpose to secret names (for SecretStore configuration) |
| kms_key_arn | ARN of the KMS key used for secret encryption (passthrough from observability module) |

## Rotation Lambda Configuration

### How It Works

The rotation Lambda follows the AWS recommended 4-step rotation strategy:

1. **createSecret**: Generate a new random password using Secrets Manager API
2. **setSecret**: Connect to RDS using current credentials and update the user password
3. **testSecret**: Verify new credentials work by establishing a test connection
4. **finishSecret**: Promote the pending secret to current and demote the old version

### Requirements for Rotation

- **VPC Access**: Lambda must be deployed in the same VPC as RDS
- **Security Groups**: Lambda security group must allow outbound to RDS port (5432)
- **RDS Security Group**: Must allow inbound from Lambda security group
- **IAM Permissions**: Automatic via module (Secrets Manager + KMS decrypt)

### Lambda Runtime Details

- **Runtime**: Node.js 20 (AWS SDK v3)
- **Timeout**: 300 seconds (5 minutes)
- **Memory**: 512 MB
- **Dependencies**: `@aws-sdk/client-secrets-manager`, `pg`

### Monitoring Rotation

```bash
# Check rotation schedule
aws secretsmanager describe-secret \
  --secret-id ghost-protocol/production/database/credentials \
  --query 'RotationEnabled'

# View rotation history
aws secretsmanager list-secret-version-ids \
  --secret-id ghost-protocol/production/database/credentials \
  --include-planned

# Trigger manual rotation (testing)
aws secretsmanager rotate-secret \
  --secret-id ghost-protocol/production/database/credentials
```

## IRSA Setup Instructions

### 1. Deploy External Secrets Operator

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets \
  external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --set installCRDs=true
```

### 2. Create ServiceAccount with IRSA Annotation

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-secrets-operator
  namespace: external-secrets
  annotations:
    eks.amazonaws.com/role-arn: <EXTERNAL_SECRETS_OPERATOR_ROLE_ARN>
```

### 3. Create SecretStore

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
  namespace: ghost-protocol-dev
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-operator
            namespace: external-secrets
```

### 4. Create ExternalSecret

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: ghost-protocol-dev
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: database-credentials
    creationPolicy: Owner
  dataFrom:
    - extract:
        key: ghost-protocol/dev/database/credentials
```

### 5. Verify Secret Sync

```bash
# Check ExternalSecret status
kubectl get externalsecret database-credentials -n ghost-protocol-dev

# Verify Kubernetes secret was created
kubectl get secret database-credentials -n ghost-protocol-dev -o yaml

# Test database connection using the secret
kubectl run -it --rm debug \
  --image=postgres:15 \
  --restart=Never \
  --env="PGHOST=$(kubectl get secret database-credentials -n ghost-protocol-dev -o jsonpath='{.data.host}' | base64 -d)" \
  --env="PGUSER=$(kubectl get secret database-credentials -n ghost-protocol-dev -o jsonpath='{.data.username}' | base64 -d)" \
  --env="PGPASSWORD=$(kubectl get secret database-credentials -n ghost-protocol-dev -o jsonpath='{.data.password}' | base64 -d)" \
  -- psql -c "SELECT 1"
```

## Post-Deployment Steps

### 1. Update Secret Values

After `terraform apply`, update placeholder values with real credentials:

```bash
# Update database credentials
aws secretsmanager put-secret-value \
  --secret-id ghost-protocol/dev/database/credentials \
  --secret-string '{
    "username": "ghostadmin",
    "password": "<STRONG_PASSWORD>",
    "host": "ghost-dev-db.cluster-abc123.us-east-1.rds.amazonaws.com",
    "port": "5432",
    "dbname": "ghostprotocol",
    "engine": "postgres"
  }'

# Update Redis password
aws secretsmanager put-secret-value \
  --secret-id ghost-protocol/dev/redis/password \
  --secret-string "<STRONG_REDIS_PASSWORD>"

# Update OpenAI API key
aws secretsmanager put-secret-value \
  --secret-id ghost-protocol/dev/api-keys/openai \
  --secret-string "sk-..."

# Update Hugging Face API key
aws secretsmanager put-secret-value \
  --secret-id ghost-protocol/dev/api-keys/huggingface \
  --secret-string "hf_..."
```

### 2. Verify Secrets Are Encrypted

```bash
# Check KMS key is being used
aws secretsmanager describe-secret \
  --secret-id ghost-protocol/dev/database/credentials \
  --query 'KmsKeyId'

# Verify CloudTrail logging is enabled (account-level)
aws cloudtrail get-trail-status --name <TRAIL_NAME>
```

### 3. Test Rotation (If Enabled)

```bash
# Trigger test rotation
aws secretsmanager rotate-secret \
  --secret-id ghost-protocol/production/database/credentials

# Monitor Lambda execution
aws logs tail /aws/lambda/ghost-prod-secret-rotation --follow

# Verify new secret version
aws secretsmanager get-secret-value \
  --secret-id ghost-protocol/production/database/credentials \
  --version-stage AWSCURRENT
```

## Security Considerations

### Encryption at Rest
- All secrets encrypted with KMS `eks_secrets` key from observability module
- KMS key supports automatic rotation (annual)
- Encryption applies to secret values and metadata

### Encryption in Transit
- AWS Secrets Manager API uses TLS 1.2+
- Rotation Lambda connects to RDS using SSL/TLS
- IRSA uses AWS STS with secure token exchange

### Access Control
- **IAM Policies**: Least privilege for External Secrets Operator and rotation Lambda
- **KMS Grants**: Explicit decrypt permissions required for secret access
- **IRSA**: ServiceAccount-level isolation, no long-lived credentials
- **Secret ARNs**: Specific secret ARNs in policies (no wildcards)

### Audit and Compliance
- **CloudTrail**: Account-level logging of all Secrets Manager API calls (per ADR-005)
- **Secret Versions**: Full version history maintained for audit trail
- **Tags**: Compliance tags (`Purpose`, `SecretType`, `Rotation`) for reporting
- **GDPR/SOC2**: Supports data encryption, access logging, and credential rotation requirements

### Network Isolation
- **Rotation Lambda**: Deployed in private subnets with VPC endpoints
- **RDS Access**: Security group rules restrict Lambda-to-RDS communication
- **No Public Access**: Secrets Manager uses VPC endpoints (no internet traffic)

### Rotation Best Practices
- **30-Day Rotation**: Default rotation period per ADR-005 (configurable)
- **Zero Downtime**: Multi-version rotation ensures service continuity
- **Automated Testing**: Lambda tests new credentials before finalization
- **Rollback Support**: Previous version available for emergency rollback

## Integration Examples

### Using Secrets in Kubernetes Deployments

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
spec:
  template:
    spec:
      containers:
        - name: api-gateway
          env:
            - name: DB_HOST
              valueFrom:
                secretKeyRef:
                  name: database-credentials
                  key: host
            - name: DB_USERNAME
              valueFrom:
                secretKeyRef:
                  name: database-credentials
                  key: username
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: database-credentials
                  key: password
            - name: OPENAI_API_KEY
              valueFrom:
                secretKeyRef:
                  name: openai-api-key
                  key: api-key
```

### Using Secrets in Terraform Outputs

```hcl
# In root module main.tf
output "external_secrets_operator_role_arn" {
  description = "ARN for IRSA annotation in Kubernetes ServiceAccount"
  value       = module.secrets.external_secrets_operator_role_arn
}

output "secret_arns" {
  description = "All secret ARNs for SecretStore configuration"
  value       = module.secrets.secret_arns
  sensitive   = true
}
```

## References

- **ADR-005**: Infrastructure & Deployment Strategy - Secrets Management Requirements
- **AWS Secrets Manager**: https://docs.aws.amazon.com/secretsmanager/
- **RDS Password Rotation**: https://docs.aws.amazon.com/secretsmanager/latest/userguide/rotating-secrets-rds.html
- **External Secrets Operator**: https://external-secrets.io/
- **IRSA Documentation**: https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html

## Compliance

This module satisfies the following compliance requirements:

- **SOC 2 Type II**:
  - CC6.1: Encryption of sensitive data at rest (KMS)
  - CC6.6: Secure credential management and rotation
  - CC7.2: Audit logging of secret access (CloudTrail)

- **GDPR**:
  - Article 32: Security of processing (encryption, access control)
  - Article 30: Records of processing activities (audit logs)

- **ADR-005 Requirements**:
  - ✅ Secrets encrypted with KMS
  - ✅ Automatic credential rotation (30 days)
  - ✅ CloudTrail audit logging
  - ✅ IRSA for Kubernetes workloads
  - ✅ No hardcoded credentials in code/config

## Troubleshooting

### Rotation Lambda Fails

```bash
# Check Lambda logs
aws logs tail /aws/lambda/<PREFIX>-secret-rotation --follow

# Common issues:
# 1. VPC connectivity - verify Lambda is in correct subnets
# 2. Security groups - ensure Lambda can reach RDS on port 5432
# 3. KMS permissions - verify Lambda role has kms:Decrypt

# Test VPC connectivity
aws lambda invoke \
  --function-name <PREFIX>-secret-rotation \
  --payload '{"test": "connectivity"}' \
  response.json
```

### IRSA Role Not Working

```bash
# Verify OIDC provider exists
aws iam get-open-id-connect-provider \
  --open-id-connect-provider-arn <OIDC_PROVIDER_ARN>

# Check role trust policy
aws iam get-role --role-name <PREFIX>-external-secrets-operator-role \
  --query 'Role.AssumeRolePolicyDocument'

# Verify ServiceAccount annotation
kubectl get sa external-secrets-operator -n external-secrets -o yaml

# Check pod identity
kubectl exec -it <POD_NAME> -n external-secrets -- env | grep AWS
```

### Secret Not Syncing to Kubernetes

```bash
# Check ExternalSecret status
kubectl describe externalsecret <SECRET_NAME> -n <NAMESPACE>

# View External Secrets Operator logs
kubectl logs -l app.kubernetes.io/name=external-secrets -n external-secrets

# Verify SecretStore connection
kubectl get secretstore -n <NAMESPACE>
kubectl describe secretstore aws-secrets-manager -n <NAMESPACE>
```

## License

This module is maintained by the Ghost Protocol infrastructure team and follows the project's open-source license.
