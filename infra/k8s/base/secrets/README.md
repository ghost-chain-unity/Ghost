# Kubernetes Secrets Management

This directory contains Kubernetes Secret manifests for the Ghost Protocol platform. Secrets are managed using **environment-specific approaches**:

## Environment-Specific Secret Management

### Development Environment
- **Approach**: Script-generated Kubernetes Secrets (NOT committed to Git)
- **Files**: None - secrets are created via `overlays/dev/create-dev-secrets.sh` script
- **Deployment**: Run `./create-dev-secrets.sh` before applying manifests
- **Values**: Placeholder credentials that must be updated manually for local development
- **Security**: No credentials committed to Git; secrets created locally and updated as needed
- **Documentation**: See `overlays/dev/README.md` for detailed deployment instructions

### Staging/Production Environments
- **Approach**: AWS Secrets Manager with External Secrets Operator
- **Files**: `database-secret.yaml`, `redis-secret.yaml`, `ai-engine-secret.yaml` (ExternalSecret definitions only)
- **Deployment**: ExternalSecret syncs from AWS Secrets Manager automatically
- **Values**: Real credentials stored securely in AWS Secrets Manager
- **Security**: Automatic rotation, encryption at rest, audit logging via CloudTrail

---

## Secret Management Strategy

1. **Base Directory**: Contains only ExternalSecret definitions (no literal secrets)
2. **Dev Overlay**: Uses script-generated secrets (`create-dev-secrets.sh`) - no secret files committed to Git
3. **Staging/Prod Overlays**: Rely on ExternalSecret from base (no additional secret files needed)

## Table of Contents

- [Prerequisites](#prerequisites)
- [Secret Types](#secret-types)
- [Deployment Methods](#deployment-methods)
  - [Method 1: Manual Secrets (kubectl)](#method-1-manual-secrets-kubectl)
  - [Method 2: AWS Secrets Manager with External Secrets Operator](#method-2-aws-secrets-manager-with-external-secrets-operator)
- [Creating Secrets from Terraform Outputs](#creating-secrets-from-terraform-outputs)
- [Security Best Practices](#security-best-practices)

---

## Prerequisites

### For Manual Secrets
- `kubectl` CLI configured with cluster access
- Base64 encoding tool (built into most systems)

### For External Secrets Operator
- External Secrets Operator installed in the cluster:
  ```bash
  helm repo add external-secrets https://charts.external-secrets.io
  helm repo update
  helm install external-secrets \
    external-secrets/external-secrets \
    -n external-secrets-system \
    --create-namespace
  ```
- AWS CLI configured with appropriate permissions
- IRSA (IAM Roles for Service Accounts) configured for External Secrets Operator
- AWS Secrets Manager access

---

## Secret Types

### 1. Database Secret (`database-secret`)
Contains PostgreSQL/RDS connection credentials:
- `url`: Full PostgreSQL connection string
- `host`: Database hostname
- `port`: Database port (default: 5432)
- `database`: Database name
- `username`: Database username
- `password`: Database password

### 2. Redis Secret (`redis-secret`)
Contains ElastiCache Redis connection credentials:
- `url`: Full Redis connection string
- `host`: Redis hostname
- `port`: Redis port (default: 6379)
- `password`: Redis authentication password

### 3. AI Engine Secret (`ai-engine-secret`)
Contains API keys and tokens for AI services:
- `openai-api-key`: OpenAI API key for GPT models
- `huggingface-token`: HuggingFace token for model downloads
- `model-encryption-key`: Encryption key for model artifacts

---

## Deployment Methods

### Method 1: Manual Secrets (kubectl)

**Use Case**: Development, testing, or environments without AWS Secrets Manager

#### Step 1: Create secrets using kubectl

**Database Secret:**
```bash
kubectl create secret generic database-secret \
  --from-literal=url='postgresql://dbuser:dbpass@postgres.example.com:5432/ghostprotocol?schema=public' \
  --from-literal=host='postgres.example.com' \
  --from-literal=port='5432' \
  --from-literal=database='ghostprotocol' \
  --from-literal=username='dbuser' \
  --from-literal=password='dbpass' \
  -n ghost-protocol-dev
```

**Redis Secret:**
```bash
kubectl create secret generic redis-secret \
  --from-literal=url='redis://:redispass@redis.example.com:6379/0' \
  --from-literal=host='redis.example.com' \
  --from-literal=port='6379' \
  --from-literal=password='redispass' \
  -n ghost-protocol-dev
```

**AI Engine Secret:**
```bash
kubectl create secret generic ai-engine-secret \
  --from-literal=openai-api-key='sk-...' \
  --from-literal=huggingface-token='hf_...' \
  --from-literal=model-encryption-key='base64-encoded-key' \
  -n ghost-protocol-dev
```

#### Step 2: Verify secrets
```bash
kubectl get secrets -n ghost-protocol-dev
kubectl describe secret database-secret -n ghost-protocol-dev
```

---

### Method 2: AWS Secrets Manager with External Secrets Operator

**Use Case**: Staging and Production environments for enhanced security and secret rotation

#### Step 1: Create secrets in AWS Secrets Manager

**Database Secret (from Terraform outputs):**
```bash
# Get values from Terraform outputs
export RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
export RDS_ADDRESS=$(terraform output -raw rds_address)
export RDS_PORT=$(terraform output -raw rds_port)
export RDS_DATABASE=$(terraform output -raw rds_database_name)
export DB_USERNAME="ghostprotocol_admin"
export DB_PASSWORD="$(openssl rand -base64 32)"

# Create in AWS Secrets Manager
aws secretsmanager create-secret \
  --name ghost-protocol/database \
  --description "Ghost Protocol PostgreSQL database credentials" \
  --secret-string "{
    \"url\": \"postgresql://${DB_USERNAME}:${DB_PASSWORD}@${RDS_ADDRESS}:${RDS_PORT}/${RDS_DATABASE}?schema=public\",
    \"host\": \"${RDS_ADDRESS}\",
    \"port\": \"${RDS_PORT}\",
    \"database\": \"${RDS_DATABASE}\",
    \"username\": \"${DB_USERNAME}\",
    \"password\": \"${DB_PASSWORD}\"
  }" \
  --region us-east-1
```

**Redis Secret:**
```bash
export REDIS_ENDPOINT="your-redis-cluster.cache.amazonaws.com"
export REDIS_PASSWORD="$(openssl rand -base64 32)"

aws secretsmanager create-secret \
  --name ghost-protocol/redis \
  --description "Ghost Protocol Redis cache credentials" \
  --secret-string "{
    \"url\": \"redis://:${REDIS_PASSWORD}@${REDIS_ENDPOINT}:6379/0\",
    \"host\": \"${REDIS_ENDPOINT}\",
    \"port\": \"6379\",
    \"password\": \"${REDIS_PASSWORD}\"
  }" \
  --region us-east-1
```

**AI Engine Secret:**
```bash
export OPENAI_API_KEY="sk-your-openai-key"
export HUGGINGFACE_TOKEN="hf_your-token"
export MODEL_ENCRYPTION_KEY="$(openssl rand -base64 32)"

aws secretsmanager create-secret \
  --name ghost-protocol/ai-engine \
  --description "Ghost Protocol AI Engine API keys" \
  --secret-string "{
    \"openai-api-key\": \"${OPENAI_API_KEY}\",
    \"huggingface-token\": \"${HUGGINGFACE_TOKEN}\",
    \"model-encryption-key\": \"${MODEL_ENCRYPTION_KEY}\"
  }" \
  --region us-east-1
```

#### Step 2: Configure IRSA for External Secrets Operator

Create an IAM policy for External Secrets Operator:

```bash
cat > external-secrets-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:*:secret:ghost-protocol/*"
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name GhostProtocolExternalSecretsPolicy \
  --policy-document file://external-secrets-policy.json
```

Create IRSA role for External Secrets Operator:
```bash
eksctl create iamserviceaccount \
  --name external-secrets-sa \
  --namespace external-secrets-system \
  --cluster ghost-protocol-prod \
  --attach-policy-arn arn:aws:iam::ACCOUNT_ID:policy/GhostProtocolExternalSecretsPolicy \
  --approve
```

#### Step 3: Deploy External Secrets

Apply the External Secrets manifests:
```bash
kubectl apply -f infra/k8s/base/secrets/ -n ghost-protocol-prod
```

#### Step 4: Verify synchronization

Check that External Secrets are syncing properly:
```bash
kubectl get externalsecrets -n ghost-protocol-prod
kubectl get secrets -n ghost-protocol-prod
kubectl describe externalsecret database-secret-sync -n ghost-protocol-prod
```

Expected output:
```
NAME                   STORE                  REFRESH INTERVAL   STATUS
database-secret-sync   aws-secrets-manager    1h                 SecretSynced
redis-secret-sync      aws-secrets-manager    1h                 SecretSynced
ai-engine-secret-sync  aws-secrets-manager    1h                 SecretSynced
```

---

## Creating Secrets from Terraform Outputs

After deploying infrastructure with Terraform, use this script to automatically create secrets:

```bash
#!/bin/bash
set -e

# Navigate to Terraform directory
cd infra/terraform

# Get Terraform outputs
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
RDS_ADDRESS=$(terraform output -raw rds_address)
RDS_PORT=$(terraform output -raw rds_port)
RDS_DATABASE=$(terraform output -raw rds_database_name)

# Generate secure passwords
DB_PASSWORD="$(openssl rand -base64 32)"
REDIS_PASSWORD="$(openssl rand -base64 32)"

# Get Redis endpoint (assuming you have it in outputs or manually set it)
REDIS_ENDPOINT="your-elasticache-endpoint.cache.amazonaws.com"

# Create database secret
aws secretsmanager create-secret \
  --name ghost-protocol/database \
  --secret-string "{
    \"url\": \"postgresql://ghostprotocol_admin:${DB_PASSWORD}@${RDS_ADDRESS}:${RDS_PORT}/${RDS_DATABASE}?schema=public\",
    \"host\": \"${RDS_ADDRESS}\",
    \"port\": \"${RDS_PORT}\",
    \"database\": \"${RDS_DATABASE}\",
    \"username\": \"ghostprotocol_admin\",
    \"password\": \"${DB_PASSWORD}\"
  }" \
  --region us-east-1

# Create Redis secret
aws secretsmanager create-secret \
  --name ghost-protocol/redis \
  --secret-string "{
    \"url\": \"redis://:${REDIS_PASSWORD}@${REDIS_ENDPOINT}:6379/0\",
    \"host\": \"${REDIS_ENDPOINT}\",
    \"port\": \"6379\",
    \"password\": \"${REDIS_PASSWORD}\"
  }" \
  --region us-east-1

echo "✅ Secrets created successfully in AWS Secrets Manager"
echo "⚠️  IMPORTANT: Save the DB_PASSWORD and REDIS_PASSWORD to a secure location"
echo "DB_PASSWORD: ${DB_PASSWORD}"
echo "REDIS_PASSWORD: ${REDIS_PASSWORD}"
```

---

## Secret Rotation

### Automatic Rotation (AWS Secrets Manager)

Configure automatic rotation for database credentials:

```bash
aws secretsmanager rotate-secret \
  --secret-id ghost-protocol/database \
  --rotation-lambda-arn arn:aws:lambda:us-east-1:ACCOUNT_ID:function:SecretsManagerRotation \
  --rotation-rules AutomaticallyAfterDays=30
```

### Manual Rotation

1. **Update secret in AWS Secrets Manager:**
   ```bash
   aws secretsmanager update-secret \
     --secret-id ghost-protocol/database \
     --secret-string '{"password": "new-password"}'
   ```

2. **External Secrets Operator will automatically sync** (within refresh interval)

3. **Restart pods to pick up new secrets:**
   ```bash
   kubectl rollout restart deployment/api-gateway -n ghost-protocol-prod
   kubectl rollout restart deployment/indexer -n ghost-protocol-prod
   ```

---

## Security Best Practices

### 1. Never Commit Secrets to Git
- All secret files in this directory contain placeholders
- Real values should only exist in AWS Secrets Manager or kubectl

### 2. Use Strong Passwords
```bash
# Generate cryptographically secure passwords
openssl rand -base64 32
```

### 3. Enable Encryption at Rest
- AWS Secrets Manager encrypts secrets using KMS by default
- Ensure Kubernetes etcd encryption is enabled for manual secrets

### 4. Restrict Access
- Use RBAC to limit who can read secrets:
  ```yaml
  apiVersion: rbac.authorization.k8s.io/v1
  kind: Role
  metadata:
    name: secret-reader
  rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list"]
  ```

### 5. Audit Secret Access
- Enable CloudTrail for AWS Secrets Manager
- Enable Kubernetes audit logging for secret access

### 6. Use Separate Secrets per Environment
- `ghost-protocol-dev/*`
- `ghost-protocol-staging/*`
- `ghost-protocol-prod/*`

---

## Troubleshooting

### Secret Not Found
```bash
# Check if secret exists
kubectl get secret database-secret -n ghost-protocol-prod

# Check External Secret status
kubectl describe externalsecret database-secret-sync -n ghost-protocol-prod
```

### External Secret Not Syncing
```bash
# Check External Secrets Operator logs
kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets

# Verify SecretStore configuration
kubectl get secretstore -n ghost-protocol-prod
kubectl describe secretstore aws-secrets-manager -n ghost-protocol-prod

# Verify IRSA permissions
kubectl get sa external-secrets-sa -n external-secrets-system -o yaml
```

### Pod Cannot Access Secret
```bash
# Check if secret is mounted
kubectl describe pod <pod-name> -n ghost-protocol-prod

# Check pod logs
kubectl logs <pod-name> -n ghost-protocol-prod
```

---

## References

- [Kubernetes Secrets Documentation](https://kubernetes.io/docs/concepts/configuration/secret/)
- [External Secrets Operator](https://external-secrets.io/)
- [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/)
- [IRSA - IAM Roles for Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
