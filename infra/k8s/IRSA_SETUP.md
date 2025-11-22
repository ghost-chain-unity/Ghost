# IRSA (IAM Roles for Service Accounts) Setup Guide

This guide provides step-by-step instructions to wire Terraform-created IAM role ARNs into Kubernetes ServiceAccount annotations for Ghost Protocol services.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Architecture](#architecture)
- [Step-by-Step Setup](#step-by-step-setup)
  - [Step 1: Deploy Infrastructure with Terraform](#step-1-deploy-infrastructure-with-terraform)
  - [Step 2: Retrieve IRSA Role ARNs](#step-2-retrieve-irsa-role-arns)
  - [Step 3: Update Kustomize Overlays](#step-3-update-kustomize-overlays)
  - [Step 4: Deploy to Kubernetes](#step-4-deploy-to-kubernetes)
  - [Step 5: Verify IRSA Configuration](#step-5-verify-irsa-configuration)
- [Automated Script](#automated-script)
- [Per-Environment Configuration](#per-environment-configuration)
- [Troubleshooting](#troubleshooting)

---

## Overview

**IRSA (IAM Roles for Service Accounts)** allows Kubernetes pods to assume AWS IAM roles, enabling secure access to AWS services without managing long-lived credentials.

### Services Using IRSA

| Service | AWS Resources Accessed |
|---------|----------------------|
| **api-gateway** | S3 (app data), CloudWatch Logs, Secrets Manager |
| **indexer** | S3 (backup), CloudWatch Logs, DynamoDB (optional) |
| **rpc-orchestrator** | CloudWatch Logs, S3 (logs) |
| **ai-engine** | S3 (model storage), Secrets Manager, CloudWatch Logs |

---

## Prerequisites

1. **Terraform Infrastructure Deployed**: EKS cluster with OIDC provider configured
2. **kubectl Configured**: Cluster access with appropriate permissions
3. **AWS CLI Installed**: Version 2.x or higher
4. **Kustomize**: Version 4.x or higher (bundled with kubectl 1.14+)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Account                               │
│                                                              │
│  ┌──────────────┐         ┌──────────────────────────────┐ │
│  │ EKS Cluster  │         │  IAM (Terraform-created)     │ │
│  │              │         │                              │ │
│  │  ┌────────┐  │  OIDC   │  ┌────────────────────────┐ │ │
│  │  │  Pod   │◄─┼─────────┼──│ api-gateway-irsa-role  │ │ │
│  │  │        │  │  Trust  │  │ indexer-irsa-role      │ │ │
│  │  │  SA ───┤  │  Policy │  │ rpc-orchestrator-role  │ │ │
│  │  │  (K8s) │  │         │  │ ai-engine-irsa-role    │ │ │
│  │  └────────┘  │         │  └────────────────────────┘ │ │
│  └──────────────┘         └──────────────────────────────┘ │
│                                       │                     │
│                                       ▼                     │
│                           ┌────────────────────┐            │
│                           │  AWS Resources     │            │
│                           │  (S3, Secrets,     │            │
│                           │   CloudWatch)      │            │
│                           └────────────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

---

## Step-by-Step Setup

### Step 1: Deploy Infrastructure with Terraform

Deploy the infrastructure to create IAM roles:

```bash
cd infra/terraform

# Initialize Terraform
terraform init

# Deploy infrastructure (creates IRSA roles)
terraform apply -var-file="environments/prod/terraform.tfvars"
```

> **Note**: IRSA roles are created in **Stage 2** of the deployment. Ensure you've followed the two-stage deployment process documented in `DEPLOYMENT_GUIDE.md`.

### Step 2: Retrieve IRSA Role ARNs

After successful Terraform deployment, retrieve the IRSA role ARNs:

```bash
# Navigate to Terraform directory
cd infra/terraform

# Get all IRSA role ARNs
export API_GATEWAY_ROLE_ARN=$(terraform output -raw api_gateway_irsa_role_arn)
export INDEXER_ROLE_ARN=$(terraform output -raw indexer_irsa_role_arn)
export RPC_ORCHESTRATOR_ROLE_ARN=$(terraform output -raw rpc_orchestrator_irsa_role_arn)
export AI_ENGINE_ROLE_ARN=$(terraform output -raw ai_engine_irsa_role_arn)

# Verify the values
echo "API Gateway Role: $API_GATEWAY_ROLE_ARN"
echo "Indexer Role: $INDEXER_ROLE_ARN"
echo "RPC Orchestrator Role: $RPC_ORCHESTRATOR_ROLE_ARN"
echo "AI Engine Role: $AI_ENGINE_ROLE_ARN"
```

Expected output format:
```
arn:aws:iam::123456789012:role/ghost-protocol-prod-api-gateway-pod-role
arn:aws:iam::123456789012:role/ghost-protocol-prod-indexer-pod-role
arn:aws:iam::123456789012:role/ghost-protocol-prod-rpc-orchestrator-pod-role
arn:aws:iam::123456789012:role/ghost-protocol-prod-ai-engine-pod-role
```

### Step 3: Automated Account ID Substitution (RECOMMENDED)

All ServiceAccount patch files use the placeholder `REPLACE_WITH_AWS_ACCOUNT_ID` instead of hardcoded account IDs. Use this script to automatically substitute the placeholder with your actual AWS account ID:

```bash
#!/bin/bash
# Script: substitute-aws-account-id.sh
# Description: Replace REPLACE_WITH_AWS_ACCOUNT_ID with actual account ID in all patches

set -e

# Get AWS account ID from current credentials
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

if [[ -z "$AWS_ACCOUNT_ID" ]]; then
  echo "❌ Error: Could not retrieve AWS account ID. Please configure AWS CLI credentials."
  exit 1
fi

echo "🔍 Found AWS Account ID: $AWS_ACCOUNT_ID"
echo "📝 Updating ServiceAccount patches..."

# Navigate to k8s directory
cd "$(dirname "$0")"

# Replace placeholder in all ServiceAccount patch files
find overlays/ -name "*-sa-patch.yaml" -exec sed -i "s/REPLACE_WITH_AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" {} \;

echo "✅ Successfully updated all ServiceAccount patches with account ID: $AWS_ACCOUNT_ID"
echo ""
echo "Updated files:"
find overlays/ -name "*-sa-patch.yaml"
```

**To use this script:**

1. Save it as `infra/k8s/substitute-aws-account-id.sh`
2. Make it executable: `chmod +x substitute-aws-account-id.sh`
3. Run it: `./substitute-aws-account-id.sh`

**Note**: This script automatically detects your AWS account ID using `aws sts get-caller-identity`. Ensure your AWS CLI is configured with credentials for the target account before running.

### Step 4: Update Kustomize Overlays (Manual Alternative)

#### Option A: Manual Update

Edit the appropriate overlay kustomization file:

**For Production (`infra/k8s/overlays/production/kustomization.yaml`):**

Add ServiceAccount patches at the end of the file:

```yaml
patches:
# ... existing deployment patches ...

# IRSA ServiceAccount patches
- target:
    kind: ServiceAccount
    name: api-gateway
  patch: |-
    - op: replace
      path: /metadata/annotations/eks.amazonaws.com~1role-arn
      value: arn:aws:iam::ACCOUNT_ID:role/ghost-protocol-prod-api-gateway-pod-role

- target:
    kind: ServiceAccount
    name: indexer
  patch: |-
    - op: replace
      path: /metadata/annotations/eks.amazonaws.com~1role-arn
      value: arn:aws:iam::ACCOUNT_ID:role/ghost-protocol-prod-indexer-pod-role

- target:
    kind: ServiceAccount
    name: rpc-orchestrator
  patch: |-
    - op: replace
      path: /metadata/annotations/eks.amazonaws.com~1role-arn
      value: arn:aws:iam::ACCOUNT_ID:role/ghost-protocol-prod-rpc-orchestrator-pod-role

- target:
    kind: ServiceAccount
    name: ai-engine
  patch: |-
    - op: replace
      path: /metadata/annotations/eks.amazonaws.com~1role-arn
      value: arn:aws:iam::ACCOUNT_ID:role/ghost-protocol-prod-ai-engine-pod-role
```

> **Note**: In JSON Patch path, use `~1` to escape `/` in annotation keys (e.g., `eks.amazonaws.com~1role-arn`).

#### Option B: Automated Update with sed

Use this script to automatically update overlay files:

```bash
#!/bin/bash
set -e

ENVIRONMENT="production"  # or "dev" or "staging"
OVERLAY_FILE="infra/k8s/overlays/${ENVIRONMENT}/kustomization.yaml"

# Get role ARNs from Terraform
cd infra/terraform
API_GATEWAY_ROLE_ARN=$(terraform output -raw api_gateway_irsa_role_arn)
INDEXER_ROLE_ARN=$(terraform output -raw indexer_irsa_role_arn)
RPC_ORCHESTRATOR_ROLE_ARN=$(terraform output -raw rpc_orchestrator_irsa_role_arn)
AI_ENGINE_ROLE_ARN=$(terraform output -raw ai_engine_irsa_role_arn)
cd -

# Create ServiceAccount patches
cat >> "${OVERLAY_FILE}" <<EOF

# IRSA ServiceAccount patches
- target:
    kind: ServiceAccount
    name: api-gateway
  patch: |-
    - op: replace
      path: /metadata/annotations/eks.amazonaws.com~1role-arn
      value: ${API_GATEWAY_ROLE_ARN}

- target:
    kind: ServiceAccount
    name: indexer
  patch: |-
    - op: replace
      path: /metadata/annotations/eks.amazonaws.com~1role-arn
      value: ${INDEXER_ROLE_ARN}

- target:
    kind: ServiceAccount
    name: rpc-orchestrator
  patch: |-
    - op: replace
      path: /metadata/annotations/eks.amazonaws.com~1role-arn
      value: ${RPC_ORCHESTRATOR_ROLE_ARN}

- target:
    kind: ServiceAccount
    name: ai-engine
  patch: |-
    - op: replace
      path: /metadata/annotations/eks.amazonaws.com~1role-arn
      value: ${AI_ENGINE_ROLE_ARN}
EOF

echo "✅ IRSA patches added to ${OVERLAY_FILE}"
```

### Step 4: Deploy to Kubernetes

Apply the updated Kustomize configuration:

```bash
# For production
kubectl apply -k infra/k8s/overlays/production

# For staging
kubectl apply -k infra/k8s/overlays/staging

# For development
kubectl apply -k infra/k8s/overlays/dev
```

### Step 5: Verify IRSA Configuration

#### Check ServiceAccount Annotations

```bash
# Production namespace
kubectl get sa api-gateway -n ghost-protocol-prod -o yaml | grep role-arn
kubectl get sa indexer -n ghost-protocol-prod -o yaml | grep role-arn
kubectl get sa rpc-orchestrator -n ghost-protocol-prod -o yaml | grep role-arn
kubectl get sa ai-engine -n ghost-protocol-prod -o yaml | grep role-arn
```

Expected output:
```yaml
eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/ghost-protocol-prod-api-gateway-pod-role
```

#### Verify Pod Environment Variables

When pods are running with IRSA, they should have AWS credential environment variables:

```bash
# Get a pod name
POD_NAME=$(kubectl get pods -n ghost-protocol-prod -l app=api-gateway -o jsonpath='{.items[0].metadata.name}')

# Check environment variables
kubectl exec -n ghost-protocol-prod $POD_NAME -- env | grep AWS
```

Expected output:
```
AWS_ROLE_ARN=arn:aws:iam::123456789012:role/ghost-protocol-prod-api-gateway-pod-role
AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token
AWS_REGION=us-east-1
```

#### Test AWS Access from Pod

```bash
# Test S3 access from api-gateway pod
kubectl exec -n ghost-protocol-prod $POD_NAME -- aws s3 ls

# Test Secrets Manager access
kubectl exec -n ghost-protocol-prod $POD_NAME -- \
  aws secretsmanager list-secrets --region us-east-1
```

---

## Automated Script

Complete automation script to set up IRSA for all environments:

```bash
#!/bin/bash
# File: scripts/setup-irsa.sh

set -e

ENVIRONMENT="${1:-production}"
OVERLAY_DIR="infra/k8s/overlays/${ENVIRONMENT}"
KUSTOMIZATION_FILE="${OVERLAY_DIR}/kustomization.yaml"

echo "🔧 Setting up IRSA for environment: ${ENVIRONMENT}"

# Step 1: Get Terraform outputs
echo "📥 Retrieving Terraform outputs..."
cd infra/terraform

API_GATEWAY_ROLE_ARN=$(terraform output -raw api_gateway_irsa_role_arn)
INDEXER_ROLE_ARN=$(terraform output -raw indexer_irsa_role_arn)
RPC_ORCHESTRATOR_ROLE_ARN=$(terraform output -raw rpc_orchestrator_irsa_role_arn)
AI_ENGINE_ROLE_ARN=$(terraform output -raw ai_engine_irsa_role_arn)

cd - > /dev/null

# Validate ARNs
if [[ -z "$API_GATEWAY_ROLE_ARN" ]] || [[ "$API_GATEWAY_ROLE_ARN" == "null" ]]; then
  echo "❌ ERROR: IRSA roles not found in Terraform outputs"
  echo "   Make sure you've completed Stage 2 deployment"
  exit 1
fi

echo "✅ Retrieved IRSA role ARNs:"
echo "   API Gateway: $API_GATEWAY_ROLE_ARN"
echo "   Indexer: $INDEXER_ROLE_ARN"
echo "   RPC Orchestrator: $RPC_ORCHESTRATOR_ROLE_ARN"
echo "   AI Engine: $AI_ENGINE_ROLE_ARN"

# Step 2: Backup existing kustomization
echo "💾 Backing up existing kustomization..."
cp "${KUSTOMIZATION_FILE}" "${KUSTOMIZATION_FILE}.backup"

# Step 3: Check if IRSA patches already exist
if grep -q "IRSA ServiceAccount patches" "${KUSTOMIZATION_FILE}"; then
  echo "⚠️  IRSA patches already exist, removing old ones..."
  sed -i '/# IRSA ServiceAccount patches/,$d' "${KUSTOMIZATION_FILE}"
fi

# Step 4: Add IRSA patches
echo "📝 Adding IRSA patches to kustomization..."
cat >> "${KUSTOMIZATION_FILE}" <<EOF

# IRSA ServiceAccount patches
- target:
    kind: ServiceAccount
    name: api-gateway
  patch: |-
    - op: replace
      path: /metadata/annotations/eks.amazonaws.com~1role-arn
      value: ${API_GATEWAY_ROLE_ARN}

- target:
    kind: ServiceAccount
    name: indexer
  patch: |-
    - op: replace
      path: /metadata/annotations/eks.amazonaws.com~1role-arn
      value: ${INDEXER_ROLE_ARN}

- target:
    kind: ServiceAccount
    name: rpc-orchestrator
  patch: |-
    - op: replace
      path: /metadata/annotations/eks.amazonaws.com~1role-arn
      value: ${RPC_ORCHESTRATOR_ROLE_ARN}

- target:
    kind: ServiceAccount
    name: ai-engine
  patch: |-
    - op: replace
      path: /metadata/annotations/eks.amazonaws.com~1role-arn
      value: ${AI_ENGINE_ROLE_ARN}
EOF

# Step 5: Validate kustomization
echo "🔍 Validating kustomization..."
kubectl kustomize "${OVERLAY_DIR}" > /dev/null

echo "✅ IRSA setup complete for ${ENVIRONMENT}"
echo ""
echo "Next steps:"
echo "  1. Review changes: git diff ${KUSTOMIZATION_FILE}"
echo "  2. Apply to cluster: kubectl apply -k ${OVERLAY_DIR}"
echo "  3. Verify: kubectl get sa -n ghost-protocol-${ENVIRONMENT/-/}-${ENVIRONMENT##*-} -o yaml | grep role-arn"
```

**Usage:**
```bash
chmod +x scripts/setup-irsa.sh
./scripts/setup-irsa.sh production
./scripts/setup-irsa.sh staging
./scripts/setup-irsa.sh dev
```

---

## Per-Environment Configuration

### Development Environment

```bash
export ENVIRONMENT="dev"
export NAMESPACE="ghost-protocol-dev"

# Apply IRSA patches
./scripts/setup-irsa.sh dev

# Deploy
kubectl apply -k infra/k8s/overlays/dev
```

### Staging Environment

```bash
export ENVIRONMENT="staging"
export NAMESPACE="ghost-protocol-staging"

# Apply IRSA patches
./scripts/setup-irsa.sh staging

# Deploy
kubectl apply -k infra/k8s/overlays/staging
```

### Production Environment

```bash
export ENVIRONMENT="production"
export NAMESPACE="ghost-protocol-prod"

# Apply IRSA patches
./scripts/setup-irsa.sh production

# Deploy
kubectl apply -k infra/k8s/overlays/production
```

---

## Troubleshooting

### Issue 1: IRSA Role ARN is "null" or empty

**Cause**: IRSA roles not created (Stage 2 not completed)

**Solution**:
1. Check Terraform outputs:
   ```bash
   cd infra/terraform
   terraform output pod_roles
   ```
2. If null, follow the two-stage deployment in `DEPLOYMENT_GUIDE.md`
3. Ensure `eks_oidc_provider_arn` and `eks_oidc_provider_url` are set in `terraform.tfvars`

### Issue 2: Pod cannot assume IAM role

**Symptoms**:
```
An error occurred (InvalidIdentityToken) when calling the GetCallerIdentity operation
```

**Diagnosis**:
```bash
# Check ServiceAccount annotation
kubectl get sa api-gateway -n ghost-protocol-prod -o yaml

# Check pod environment variables
kubectl exec <pod-name> -n ghost-protocol-prod -- env | grep AWS

# Check OIDC provider trust policy
aws iam get-role --role-name ghost-protocol-prod-api-gateway-pod-role \
  --query 'Role.AssumeRolePolicyDocument'
```

**Common Causes**:
1. ServiceAccount annotation missing or incorrect
2. OIDC provider not configured in trust policy
3. Namespace mismatch in trust policy condition

### Issue 3: kustomize build fails

**Error**: `json: cannot unmarshal string into Go value`

**Cause**: Incorrect JSON Patch syntax

**Solution**: Ensure proper escaping in path:
- ✅ Correct: `/metadata/annotations/eks.amazonaws.com~1role-arn`
- ❌ Wrong: `/metadata/annotations/eks.amazonaws.com/role-arn`

### Issue 4: Access Denied to AWS Resources

**Diagnosis**:
```bash
# Check IAM role permissions
aws iam list-attached-role-policies \
  --role-name ghost-protocol-prod-api-gateway-pod-role

# Check inline policies
aws iam list-role-policies \
  --role-name ghost-protocol-prod-api-gateway-pod-role
```

**Solution**: Verify IAM policies in `infra/terraform/modules/observability/aws/iam_pods.tf`

---

## References

- [AWS EKS IRSA Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [Kubernetes ServiceAccount](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)
- [Kustomize JSON Patch](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patches/)
- [Terraform EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)
