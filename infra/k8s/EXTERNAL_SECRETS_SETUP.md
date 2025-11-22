# External Secrets Operator Setup Guide

**Version:** 1.0  
**Date:** 2025-11-16  
**Author:** Ghost Protocol DevOps Team  
**Phase:** 0.4.11 - External Secrets Integration  
**Status:** Production Ready

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [Installation](#installation)
5. [Verification](#verification)
6. [Configuration](#configuration)
7. [Using Secrets in Applications](#using-secrets-in-applications)
8. [Secret Rotation](#secret-rotation)
9. [Monitoring](#monitoring)
10. [Troubleshooting](#troubleshooting)
11. [Security Best Practices](#security-best-practices)
12. [References](#references)

---

## Overview

The External Secrets Operator (ESO) synchronizes secrets from AWS Secrets Manager into Kubernetes secrets, providing a secure and automated approach to secrets management for the Ghost Protocol platform.

### Key Features

- **Automatic Synchronization**: Secrets from AWS Secrets Manager are automatically synced to Kubernetes
- **IRSA Authentication**: Uses IAM Roles for Service Accounts (IRSA) for secure, credential-less AWS access
- **Multi-Environment Support**: Separate secret stores for dev, staging, and production
- **Automatic Refresh**: Secrets are refreshed every hour (configurable)
- **Template Engine**: Transform AWS secret data into Kubernetes secret format
- **High Availability**: 2 replicas with pod anti-affinity for resilience

### Why External Secrets?

**Problems Solved:**
- ❌ Manual secret creation in each environment
- ❌ Secrets stored in Git (security risk)
- ❌ Difficult secret rotation across environments
- ❌ No audit trail for secret access
- ❌ Manual synchronization between AWS and Kubernetes

**Benefits:**
- ✅ Single source of truth (AWS Secrets Manager)
- ✅ Automatic synchronization to Kubernetes
- ✅ Centralized secret rotation
- ✅ CloudTrail audit logging
- ✅ GitOps-friendly (no secrets in Git)
- ✅ Per-environment isolation

---

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Account                              │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           AWS Secrets Manager                            │  │
│  │                                                          │  │
│  │  ghost-protocol/production/database/credentials         │  │
│  │  ghost-protocol/production/redis/password               │  │
│  │  ghost-protocol/production/api-keys/openai              │  │
│  │  ghost-protocol/production/api-keys/huggingface         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              │                                  │
│                              │ IRSA (IAM Role)                  │
│                              ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                     EKS Cluster                          │  │
│  │                                                          │  │
│  │  ┌────────────────────────────────────────────────────┐ │  │
│  │  │  Namespace: external-secrets                       │ │  │
│  │  │                                                    │ │  │
│  │  │  ┌──────────────────────────────────────────┐     │ │  │
│  │  │  │  External Secrets Operator               │     │ │  │
│  │  │  │  - Deployment (2 replicas)               │     │ │  │
│  │  │  │  - ServiceAccount (IRSA)                 │     │ │  │
│  │  │  │  - ClusterRole + ClusterRoleBinding      │     │ │  │
│  │  │  └──────────────────────────────────────────┘     │ │  │
│  │  └────────────────────────────────────────────────────┘ │  │
│  │                              │                          │  │
│  │                              │ Watches                  │  │
│  │                              ▼                          │  │
│  │  ┌────────────────────────────────────────────────────┐ │  │
│  │  │  Namespace: ghost-protocol-prod                    │ │  │
│  │  │                                                    │ │  │
│  │  │  ┌──────────────────────────────────────────┐     │ │  │
│  │  │  │  SecretStore (aws-secretstore)           │     │ │  │
│  │  │  │  - Provider: AWS Secrets Manager         │     │ │  │
│  │  │  │  - Auth: IRSA                            │     │ │  │
│  │  │  └──────────────────────────────────────────┘     │ │  │
│  │  │                                                    │ │  │
│  │  │  ┌──────────────────────────────────────────┐     │ │  │
│  │  │  │  ExternalSecret (database-credentials)   │     │ │  │
│  │  │  │  ExternalSecret (redis-credentials)      │     │ │  │
│  │  │  │  ExternalSecret (openai-api-key)         │     │ │  │
│  │  │  │  ExternalSecret (huggingface-api-key)    │     │ │  │
│  │  │  └──────────────────────────────────────────┘     │ │  │
│  │  │                              │                     │ │  │
│  │  │                              │ Creates              │ │  │
│  │  │                              ▼                     │ │  │
│  │  │  ┌──────────────────────────────────────────┐     │ │  │
│  │  │  │  Kubernetes Secrets (Opaque)             │     │ │  │
│  │  │  │  - database-credentials                  │     │ │  │
│  │  │  │  - redis-credentials                     │     │ │  │
│  │  │  │  - openai-api-key                        │     │ │  │
│  │  │  │  - huggingface-api-key                   │     │ │  │
│  │  │  └──────────────────────────────────────────┘     │ │  │
│  │  │                              │                     │ │  │
│  │  │                              │ Mounted as volumes  │ │  │
│  │  │                              ▼                     │ │  │
│  │  │  ┌──────────────────────────────────────────┐     │ │  │
│  │  │  │  Application Pods                        │     │ │  │
│  │  │  │  - API Gateway                           │     │ │  │
│  │  │  │  - Indexer                               │     │ │  │
│  │  │  │  - RPC Orchestrator                      │     │ │  │
│  │  │  │  - AI Engine                             │     │ │  │
│  │  │  └──────────────────────────────────────────┘     │ │  │
│  │  └────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Sync Flow

1. **ExternalSecret Created**: Deployed via Kustomize to app namespace
2. **Operator Watches**: External Secrets Operator detects ExternalSecret resource
3. **AWS Authentication**: Operator uses IRSA to authenticate with AWS
4. **Fetch from AWS**: Operator retrieves secret from AWS Secrets Manager
5. **Transform**: Template engine transforms AWS secret data
6. **Create K8s Secret**: Operator creates/updates Kubernetes secret
7. **Refresh**: Process repeats every hour (refreshInterval: 1h)

### Secret Naming Convention

**AWS Secrets Manager Path Structure:**
```
ghost-protocol/{environment}/{category}/{name}

Examples:
- ghost-protocol/production/database/credentials
- ghost-protocol/staging/redis/password
- ghost-protocol/dev/api-keys/openai
```

**Kubernetes Secret Names:**
```
{purpose}-{type}

Examples:
- database-credentials
- redis-credentials
- openai-api-key
- huggingface-api-key
```

---

## Prerequisites

### 1. Terraform Secrets Module Deployed

The Terraform secrets module must be deployed first to create:
- AWS Secrets Manager secrets
- Rotation Lambda function (production only)
- IRSA role for External Secrets Operator
- KMS encryption keys

**Verify Terraform deployment:**
```bash
cd infra/terraform
terraform output -json | jq '.secrets'
```

**Required outputs:**
- `external_secrets_operator_role_arn`: IAM role ARN for IRSA
- `database_secret_name`: AWS Secrets Manager secret name
- `redis_secret_name`: AWS Secrets Manager secret name
- `openai_api_key_secret_name`: AWS Secrets Manager secret name
- `huggingface_api_key_secret_name`: AWS Secrets Manager secret name

**Reference:** See `infra/terraform/modules/secrets/aws/README.md` for Terraform module documentation

### 2. EKS Cluster with OIDC Provider

External Secrets Operator requires IRSA, which needs EKS OIDC provider.

**Verify OIDC provider:**
```bash
aws eks describe-cluster --name ghost-protocol-production \
  --query "cluster.identity.oidc.issuer" --output text
```

**Reference:** See `infra/k8s/IRSA_SETUP.md` for IRSA configuration

### 3. Install External Secrets CRDs

External Secrets Operator Custom Resource Definitions (CRDs) must be installed cluster-wide.

**Install CRDs:**
```bash
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/v0.9.11/deploy/crds/bundle.yaml
```

**Verify CRDs installed:**
```bash
kubectl get crd | grep external-secrets.io
```

Expected output:
```
clustersecretstores.external-secrets.io      2025-11-16T10:30:00Z
externalsecrets.external-secrets.io          2025-11-16T10:30:00Z
secretstores.external-secrets.io             2025-11-16T10:30:00Z
```

### 4. AWS Secrets Populated

Secrets must exist in AWS Secrets Manager with proper structure.

**Database secret structure:**
```json
{
  "host": "ghost-prod-db.cluster-xyz.us-east-1.rds.amazonaws.com",
  "port": "5432",
  "dbname": "ghostprotocol",
  "username": "ghostadmin",
  "password": "SECURE_PASSWORD_HERE"
}
```

**Redis secret structure:**
```json
{
  "password": "REDIS_PASSWORD_HERE"
}
```

**API key secret structure:**
```json
{
  "api_key": "sk-..."
}
```

**Create/update secrets manually (if needed):**
```bash
# Database credentials
aws secretsmanager put-secret-value \
  --secret-id ghost-protocol/production/database/credentials \
  --secret-string '{
    "host": "ghost-prod-db.cluster-xyz.us-east-1.rds.amazonaws.com",
    "port": "5432",
    "dbname": "ghostprotocol",
    "username": "ghostadmin",
    "password": "YOUR_SECURE_PASSWORD"
  }'

# Redis password
aws secretsmanager put-secret-value \
  --secret-id ghost-protocol/production/redis/password \
  --secret-string '{
    "password": "YOUR_REDIS_PASSWORD"
  }'

# OpenAI API key
aws secretsmanager put-secret-value \
  --secret-id ghost-protocol/production/api-keys/openai \
  --secret-string '{
    "api_key": "sk-..."
  }'

# Hugging Face API key
aws secretsmanager put-secret-value \
  --secret-id ghost-protocol/production/api-keys/huggingface \
  --secret-string '{
    "api_key": "hf_..."
  }'
```

### 5. Update .env Files

Update environment-specific .env files with Terraform outputs.

**Production (.env):**
```bash
cd infra/k8s/overlays/production

# Update .env file with Terraform outputs
EXTERNAL_SECRETS_OPERATOR_ROLE_ARN=$(cd ../../../terraform && terraform output -raw external_secrets_operator_role_arn)
echo "EXTERNAL_SECRETS_OPERATOR_ROLE_ARN=$EXTERNAL_SECRETS_OPERATOR_ROLE_ARN" >> .env
echo "TARGET_NAMESPACE=ghost-protocol-prod" >> .env
echo "ENVIRONMENT=production" >> .env
```

**Development (.env):**
```bash
cd infra/k8s/overlays/dev

# Update .env file with Terraform outputs
EXTERNAL_SECRETS_OPERATOR_ROLE_ARN=$(cd ../../../terraform && terraform output -raw external_secrets_operator_role_arn)
echo "EXTERNAL_SECRETS_OPERATOR_ROLE_ARN=$EXTERNAL_SECRETS_OPERATOR_ROLE_ARN" >> .env
echo "TARGET_NAMESPACE=ghost-protocol-dev" >> .env
echo "ENVIRONMENT=dev" >> .env
```

**Staging (.env):**
```bash
cd infra/k8s/overlays/staging

# Update .env file with Terraform outputs
EXTERNAL_SECRETS_OPERATOR_ROLE_ARN=$(cd ../../../terraform && terraform output -raw external_secrets_operator_role_arn)
echo "EXTERNAL_SECRETS_OPERATOR_ROLE_ARN=$EXTERNAL_SECRETS_OPERATOR_ROLE_ARN" >> .env
echo "TARGET_NAMESPACE=ghost-protocol-staging" >> .env
echo "ENVIRONMENT=staging" >> .env
```

---

## Installation

### Development Environment

**1. Deploy External Secrets Operator and resources:**
```bash
cd infra/k8s/overlays/dev
kubectl apply -k .
```

**2. Verify deployment:**
```bash
# Check operator pods
kubectl get pods -n external-secrets

# Check ExternalSecrets status
kubectl get externalsecrets -n ghost-protocol-dev

# Check created Kubernetes secrets
kubectl get secrets -n ghost-protocol-dev | grep -E "database|redis|openai|huggingface"
```

### Staging Environment

**1. Deploy External Secrets Operator and resources:**
```bash
cd infra/k8s/overlays/staging
kubectl apply -k .
```

**2. Verify deployment:**
```bash
kubectl get pods -n external-secrets
kubectl get externalsecrets -n ghost-protocol-staging
kubectl get secrets -n ghost-protocol-staging | grep -E "database|redis|openai|huggingface"
```

### Production Environment

**1. Deploy External Secrets Operator and resources:**
```bash
cd infra/k8s/overlays/production
kubectl apply -k .
```

**2. Verify deployment:**
```bash
kubectl get pods -n external-secrets
kubectl get externalsecrets -n ghost-protocol-prod
kubectl get secrets -n ghost-protocol-prod | grep -E "database|redis|openai|huggingface"
```

**3. Production-specific checks:**
```bash
# Verify HA configuration (2 replicas)
kubectl get deployment external-secrets-operator -n external-secrets -o yaml | grep replicas

# Check pod anti-affinity (pods on different nodes)
kubectl get pods -n external-secrets -o wide
```

---

## Verification

### 1. Operator Health Check

**Check operator pods are running:**
```bash
kubectl get pods -n external-secrets

# Expected output:
# NAME                                        READY   STATUS    RESTARTS   AGE
# external-secrets-operator-xxxxxxxxxx-xxxxx   1/1     Running   0          5m
# external-secrets-operator-xxxxxxxxxx-xxxxx   1/1     Running   0          5m
```

**Check operator logs:**
```bash
kubectl logs -n external-secrets deployment/external-secrets-operator --tail=50
```

**Expected log entries:**
- `"msg":"successfully reconciled ExternalSecret"`
- `"msg":"secret synced"`

### 2. SecretStore Status

**Check SecretStore status:**
```bash
kubectl get secretstore -n ghost-protocol-prod

# Expected output:
# NAME              AGE   STATUS   READY
# aws-secretstore   5m    Valid    True
```

**Describe SecretStore for details:**
```bash
kubectl describe secretstore aws-secretstore -n ghost-protocol-prod
```

**Expected status conditions:**
```yaml
Status:
  Conditions:
    Status:  True
    Type:    Ready
```

### 3. ExternalSecret Status

**Check all ExternalSecrets:**
```bash
kubectl get externalsecrets -n ghost-protocol-prod

# Expected output:
# NAME                     STORE             REFRESH INTERVAL   STATUS
# database-credentials     aws-secretstore   1h                 SecretSynced
# redis-credentials        aws-secretstore   1h                 SecretSynced
# openai-api-key           aws-secretstore   1h                 SecretSynced
# huggingface-api-key      aws-secretstore   1h                 SecretSynced
```

**Describe specific ExternalSecret:**
```bash
kubectl describe externalsecret database-credentials -n ghost-protocol-prod
```

**Expected status conditions:**
```yaml
Status:
  Binding:
    Name:  database-credentials
  Conditions:
    Status:  True
    Type:    Ready
  Refresh Time:  2025-11-16T10:45:00Z
  Synced Resource Version:  v1
```

### 4. Kubernetes Secret Verification

**List created secrets:**
```bash
kubectl get secrets -n ghost-protocol-prod | grep -E "database|redis|openai|huggingface"

# Expected output:
# database-credentials     Opaque   5      5m
# redis-credentials        Opaque   1      5m
# openai-api-key           Opaque   1      5m
# huggingface-api-key      Opaque   1      5m
```

**Inspect secret structure (database example):**
```bash
kubectl get secret database-credentials -n ghost-protocol-prod -o yaml
```

**Expected secret keys:**
```yaml
data:
  DB_HOST: <base64-encoded>
  DB_PORT: <base64-encoded>
  DB_NAME: <base64-encoded>
  DB_USERNAME: <base64-encoded>
  DB_PASSWORD: <base64-encoded>
```

**Decode secret values (for verification only):**
```bash
kubectl get secret database-credentials -n ghost-protocol-prod -o json | \
  jq -r '.data | to_entries[] | "\(.key): \(.value | @base64d)"'
```

⚠️ **SECURITY WARNING**: Never log or save decoded secrets. Use this only for debugging in secure environments.

### 5. IRSA Verification

**Check ServiceAccount annotation:**
```bash
kubectl get serviceaccount external-secrets-operator -n external-secrets -o yaml | grep eks.amazonaws.com/role-arn
```

**Expected output:**
```yaml
annotations:
  eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/ghost-protocol-prod-external-secrets-operator-role
```

**Verify IAM role trust policy:**
```bash
ROLE_ARN=$(kubectl get sa external-secrets-operator -n external-secrets -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}')
ROLE_NAME=$(echo $ROLE_ARN | awk -F'/' '{print $NF}')

aws iam get-role --role-name $ROLE_NAME --query 'Role.AssumeRolePolicyDocument'
```

**Expected trust policy includes:**
```json
{
  "StringEquals": {
    "oidc.eks.us-east-1.amazonaws.com/id/XXXXXXXX:sub": "system:serviceaccount:external-secrets:external-secrets-operator"
  }
}
```

---

## Configuration

### Refresh Interval

Per ADR-005, secrets are refreshed every hour to balance security and API costs.

**Current configuration:**
```yaml
spec:
  refreshInterval: 1h
```

**Modify refresh interval (if needed):**
```bash
# Edit ExternalSecret
kubectl edit externalsecret database-credentials -n ghost-protocol-prod

# Update refreshInterval value
spec:
  refreshInterval: 30m  # or 2h, 6h, etc.
```

**Trade-offs:**
- **Shorter interval (15m)**: Faster propagation, higher AWS API costs
- **Longer interval (6h)**: Lower costs, slower propagation

### AWS Region

Default region is `us-east-1`. Change via SecretStore configuration.

**Update region:**
```bash
kubectl edit secretstore aws-secretstore -n ghost-protocol-prod

# Update region field
spec:
  provider:
    aws:
      region: us-west-2
```

### Secret Templates

ExternalSecret templates transform AWS secret data into Kubernetes secret format.

**Database template (current):**
```yaml
template:
  type: Opaque
  engineVersion: v2
  data:
    DB_HOST: "{{ .host }}"
    DB_PORT: "{{ .port }}"
    DB_NAME: "{{ .dbname }}"
    DB_USERNAME: "{{ .username }}"
    DB_PASSWORD: "{{ .password }}"
```

**Custom template example:**
```yaml
template:
  type: Opaque
  engineVersion: v2
  data:
    DATABASE_URL: "postgresql://{{ .username }}:{{ .password }}@{{ .host }}:{{ .port }}/{{ .dbname }}"
    DB_HOST: "{{ .host }}"
```

**Reference:** [External Secrets Template Documentation](https://external-secrets.io/latest/guides/templating/)

---

## Using Secrets in Applications

### Environment Variables

**Inject all secret keys as environment variables:**
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
        image: api-gateway:latest
        envFrom:
        - secretRef:
            name: database-credentials
        - secretRef:
            name: redis-credentials
        - secretRef:
            name: openai-api-key
```

**Inject specific secret keys:**
```yaml
env:
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: database-credentials
      key: DB_HOST
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: database-credentials
      key: DB_PASSWORD
```

### Volume Mounts

**Mount secrets as files:**
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
        volumeMounts:
        - name: db-creds
          mountPath: /etc/secrets/database
          readOnly: true
      volumes:
      - name: db-creds
        secret:
          secretName: database-credentials
```

**Access secret files in application:**
```bash
# Inside container
cat /etc/secrets/database/DB_PASSWORD
```

### Init Containers

**Use init container to verify secrets before app starts:**
```yaml
initContainers:
- name: check-secrets
  image: busybox
  command:
  - sh
  - -c
  - |
    if [ -z "$DB_PASSWORD" ]; then
      echo "ERROR: DB_PASSWORD not set"
      exit 1
    fi
    echo "Secrets verified"
  envFrom:
  - secretRef:
      name: database-credentials
```

---

## Secret Rotation

### Automatic Rotation (Production)

Production database credentials are automatically rotated every 30 days via Lambda function.

**Check rotation schedule:**
```bash
aws secretsmanager describe-secret \
  --secret-id ghost-protocol/production/database/credentials \
  --query 'RotationEnabled'
```

**View rotation history:**
```bash
aws secretsmanager list-secret-version-ids \
  --secret-id ghost-protocol/production/database/credentials \
  --include-planned
```

### Manual Secret Rotation

**Rotate database credentials manually:**
```bash
# 1. Trigger rotation in AWS
aws secretsmanager rotate-secret \
  --secret-id ghost-protocol/production/database/credentials

# 2. Wait for rotation to complete (5-10 minutes)
aws secretsmanager describe-secret \
  --secret-id ghost-protocol/production/database/credentials \
  --query 'RotationEnabled'

# 3. External Secrets Operator will sync within refreshInterval (1h)
# Or force immediate sync:
kubectl annotate externalsecret database-credentials \
  -n ghost-protocol-prod \
  force-sync="$(date +%s)" --overwrite

# 4. Verify new secret version
kubectl get secret database-credentials -n ghost-protocol-prod -o yaml

# 5. Restart application pods to pick up new credentials
kubectl rollout restart deployment/api-gateway -n ghost-protocol-prod
```

### Rotation Best Practices

1. **Test in dev/staging first**: Always test rotation in lower environments
2. **Monitor applications**: Watch application logs during rotation
3. **Graceful handling**: Applications should reconnect on credential failures
4. **Rollback plan**: Keep previous secret version available
5. **Communication**: Notify team before production rotation

---

## Monitoring

### Metrics

External Secrets Operator exposes Prometheus metrics on port 8080.

**Key metrics:**
- `externalsecret_sync_calls_total`: Total number of sync calls
- `externalsecret_sync_calls_error`: Number of sync errors
- `externalsecret_status_condition`: ExternalSecret status (0=False, 1=True)

**Query metrics via Prometheus:**
```promql
# Sync error rate
rate(externalsecret_sync_calls_error[5m])

# ExternalSecrets not synced
externalsecret_status_condition{condition="Ready",status="False"} == 1
```

**Grafana dashboard:** Import dashboard ID 14541 from Grafana.com

### Logs

**View operator logs:**
```bash
kubectl logs -n external-secrets deployment/external-secrets-operator -f
```

**Common log patterns:**
- `"msg":"successfully reconciled ExternalSecret"` - Success
- `"msg":"error getting secret from provider"` - AWS Secrets Manager access issue
- `"msg":"error setting secret"` - Kubernetes secret creation failed

**Export logs to Loki:**
```bash
# Logs are automatically scraped by Promtail DaemonSet
# Query in Grafana:
{namespace="external-secrets"}
```

### Alerts

**Recommended Prometheus alerts:**

```yaml
groups:
- name: external-secrets
  rules:
  - alert: ExternalSecretSyncFailure
    expr: externalsecret_status_condition{condition="Ready",status="False"} == 1
    for: 15m
    annotations:
      summary: "ExternalSecret {{ $labels.name }} sync failed"
      description: "ExternalSecret {{ $labels.name }} in namespace {{ $labels.namespace }} has failed to sync for 15+ minutes"

  - alert: ExternalSecretHighErrorRate
    expr: rate(externalsecret_sync_calls_error[5m]) > 0.1
    for: 5m
    annotations:
      summary: "High External Secrets sync error rate"
      description: "External Secrets Operator is experiencing {{ $value }} errors/sec"
```

**Reference:** See `infra/k8s/base/monitoring/prometheus-alerts-phase2.yaml`

---

## Troubleshooting

### Issue: ExternalSecret Status "SecretSyncedError"

**Symptoms:**
```bash
kubectl get externalsecret database-credentials -n ghost-protocol-prod
# NAME                     STORE             STATUS
# database-credentials     aws-secretstore   SecretSyncedError
```

**Diagnosis:**
```bash
kubectl describe externalsecret database-credentials -n ghost-protocol-prod
```

**Common causes:**

1. **Secret doesn't exist in AWS Secrets Manager**
   ```bash
   # Verify secret exists
   aws secretsmanager describe-secret \
     --secret-id ghost-protocol/production/database/credentials
   ```

2. **IAM permissions insufficient**
   ```bash
   # Check IAM role policy
   ROLE_ARN=$(kubectl get sa external-secrets-operator -n external-secrets -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}')
   ROLE_NAME=$(echo $ROLE_ARN | awk -F'/' '{print $NF}')
   aws iam get-role-policy --role-name $ROLE_NAME --policy-name ExternalSecretsPolicy
   ```

3. **Wrong secret path in ExternalSecret**
   ```bash
   # Check dataFrom.extract.key value
   kubectl get externalsecret database-credentials -n ghost-protocol-prod -o yaml | grep key:
   ```

**Resolution:**
- Create missing secret in AWS Secrets Manager
- Update IAM role policy with required permissions
- Correct secret path in ExternalSecret manifest

### Issue: IRSA Authentication Failure

**Symptoms:**
```
Error: failed to get credentials: WebIdentityErr: failed to retrieve credentials
```

**Diagnosis:**
```bash
# Check ServiceAccount annotation
kubectl get sa external-secrets-operator -n external-secrets -o yaml

# Verify OIDC provider exists
aws eks describe-cluster --name ghost-protocol-production \
  --query "cluster.identity.oidc.issuer" --output text

# Check IAM role trust policy
aws iam get-role --role-name ghost-protocol-prod-external-secrets-operator-role \
  --query 'Role.AssumeRolePolicyDocument'
```

**Resolution:**
1. Ensure `eks.amazonaws.com/role-arn` annotation is present
2. Verify IAM role trust policy allows OIDC provider
3. Check namespace and ServiceAccount name match trust policy
4. Restart operator pods after fixing

### Issue: Secret Not Refreshing

**Symptoms:**
- AWS secret updated but Kubernetes secret unchanged after 1+ hour

**Diagnosis:**
```bash
# Check ExternalSecret refresh time
kubectl get externalsecret database-credentials -n ghost-protocol-prod -o yaml | grep refreshTime

# Check operator logs for sync events
kubectl logs -n external-secrets deployment/external-secrets-operator | grep database-credentials
```

**Resolution:**
```bash
# Force immediate sync
kubectl annotate externalsecret database-credentials \
  -n ghost-protocol-prod \
  force-sync="$(date +%s)" --overwrite

# Verify sync occurred
kubectl get externalsecret database-credentials -n ghost-protocol-prod -o yaml | grep refreshTime
```

### Issue: Template Rendering Error

**Symptoms:**
```
Error: failed to execute template: template: :1: unexpected <.dbname>
```

**Diagnosis:**
```bash
# Check ExternalSecret template
kubectl get externalsecret database-credentials -n ghost-protocol-prod -o yaml | grep -A 10 template

# Verify AWS secret structure
aws secretsmanager get-secret-value \
  --secret-id ghost-protocol/production/database/credentials \
  --query 'SecretString' --output text | jq .
```

**Resolution:**
- Ensure AWS secret has required fields (host, port, dbname, username, password)
- Fix template syntax (use `{{ .fieldname }}`)
- Match AWS secret field names with template variables

### Issue: Operator Pods CrashLoopBackOff

**Symptoms:**
```bash
kubectl get pods -n external-secrets
# NAME                                        READY   STATUS             RESTARTS
# external-secrets-operator-xxxxxxxxxx-xxxxx   0/1     CrashLoopBackOff   5
```

**Diagnosis:**
```bash
kubectl logs -n external-secrets deployment/external-secrets-operator --previous
kubectl describe pod -n external-secrets -l app=external-secrets-operator
```

**Common causes:**
- CRDs not installed
- RBAC permissions missing
- Image pull errors

**Resolution:**
```bash
# Install CRDs
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/v0.9.11/deploy/crds/bundle.yaml

# Verify RBAC
kubectl get clusterrole external-secrets-operator
kubectl get clusterrolebinding external-secrets-operator

# Check image accessibility
kubectl run test --image=ghcr.io/external-secrets/external-secrets:v0.9.11 --rm -it --restart=Never -- /bin/sh
```

---

## Security Best Practices

### 1. Principle of Least Privilege

**IAM Role Permissions:**
- Grant only `secretsmanager:GetSecretValue` on specific secrets
- No `secretsmanager:*` wildcard permissions
- Restrict to `ghost-protocol/*` path prefix

**Kubernetes RBAC:**
- Operator has cluster-wide secret permissions (required)
- Application pods should NOT have secret list/get permissions
- Use namespace isolation

### 2. Secret Encryption

**At Rest:**
- AWS Secrets Manager: KMS encryption (aws/secretsmanager key)
- Kubernetes: etcd encryption (configure via EKS)

**In Transit:**
- AWS API calls: TLS 1.2+
- Kubernetes API: TLS (default)

### 3. Audit Logging

**AWS CloudTrail:**
```bash
# Query secret access logs
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=ghost-protocol/production/database/credentials \
  --max-items 10
```

**Kubernetes Audit Logs:**
- Enable EKS control plane logging
- Monitor secret creation/access events

### 4. Secret Rotation

**Mandatory rotation:**
- Database passwords: Every 30 days (automated)
- API keys: Every 90 days (manual)
- Redis passwords: Every 90 days (manual)

**Reference:** ADR-005 Section on Secret Management

### 5. Network Policies

**Restrict access to external-secrets namespace:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-external-secrets-ingress
  namespace: external-secrets
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: kube-system
```

### 6. Image Security

**Use specific image tags:**
- ❌ Don't use: `latest` or `stable`
- ✅ Use: `v0.9.11` (specific version)

**Verify image signatures:**
```bash
# Check image digest
kubectl get deployment external-secrets-operator -n external-secrets -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### 7. Secret Access Monitoring

**Monitor unusual access patterns:**
- Multiple failed secret retrievals
- Access outside business hours
- Cross-namespace secret access attempts

**Prometheus query:**
```promql
sum(rate(externalsecret_sync_calls_error[5m])) by (namespace, name) > 0.05
```

---

## References

### Official Documentation

- **External Secrets Operator**: https://external-secrets.io/latest/
- **AWS Secrets Manager**: https://docs.aws.amazon.com/secretsmanager/
- **IRSA (IAM Roles for Service Accounts)**: https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html
- **Kustomize**: https://kustomize.io/

### Ghost Protocol Documentation

- **ADR-005**: Infrastructure & Deployment Strategy (`docs/adr/ADR-20251115-005-infrastructure-deployment-strategy.md`)
  - Section: Security Architecture
  - Section: Secrets Management Strategy
  - Section: Encryption at Rest
- **Terraform Secrets Module**: `infra/terraform/modules/secrets/aws/README.md`
- **IRSA Setup Guide**: `infra/k8s/IRSA_SETUP.md`
- **Kustomize Replacements Guide**: `infra/k8s/KUSTOMIZE_REPLACEMENTS_GUIDE.md`

### Internal References

**K8s Manifests:**
- Base manifests: `infra/k8s/base/external-secrets/`
- Production overlay: `infra/k8s/overlays/production/kustomization.yaml` (lines 333-397)
- Dev overlay: `infra/k8s/overlays/dev/kustomization.yaml`
- Staging overlay: `infra/k8s/overlays/staging/kustomization.yaml`

**Terraform:**
- Secrets module: `infra/terraform/modules/secrets/aws/`
- IRSA role: `infra/terraform/modules/secrets/aws/iam.tf`
- Rotation Lambda: `infra/terraform/modules/secrets/aws/rotation.tf`

### External Resources

- **GitHub**: https://github.com/external-secrets/external-secrets
- **Helm Chart**: https://github.com/external-secrets/external-secrets/tree/main/deploy/charts/external-secrets
- **Grafana Dashboard**: https://grafana.com/grafana/dashboards/14541

---

## Appendix

### A. Secret Path Mapping

| AWS Secrets Manager Path                              | Kubernetes Secret Name      | Used By            |
|-------------------------------------------------------|-----------------------------|--------------------|
| `ghost-protocol/production/database/credentials`     | `database-credentials`      | All services       |
| `ghost-protocol/production/redis/password`           | `redis-credentials`         | API Gateway, Cache |
| `ghost-protocol/production/api-keys/openai`          | `openai-api-key`            | AI Engine          |
| `ghost-protocol/production/api-keys/huggingface`     | `huggingface-api-key`       | AI Engine          |

### B. IAM Role Trust Policy Template

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/oidc.eks.REGION.amazonaws.com/id/OIDC_ID"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.REGION.amazonaws.com/id/OIDC_ID:sub": "system:serviceaccount:external-secrets:external-secrets-operator",
          "oidc.eks.REGION.amazonaws.com/id/OIDC_ID:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

### C. IAM Role Policy Template

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:REGION:ACCOUNT_ID:secret:ghost-protocol/ENVIRONMENT/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": [
        "arn:aws:kms:REGION:ACCOUNT_ID:key/KMS_KEY_ID"
      ],
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "secretsmanager.REGION.amazonaws.com"
        }
      }
    }
  ]
}
```

### D. Emergency Rollback Procedure

**If External Secrets integration causes issues:**

1. **Disable ExternalSecrets (keep operator running):**
   ```bash
   kubectl delete externalsecrets --all -n ghost-protocol-prod
   ```

2. **Create manual secrets (fallback):**
   ```bash
   kubectl create secret generic database-credentials \
     --from-literal=DB_HOST=ghost-prod-db.cluster-xyz.us-east-1.rds.amazonaws.com \
     --from-literal=DB_PORT=5432 \
     --from-literal=DB_NAME=ghostprotocol \
     --from-literal=DB_USERNAME=ghostadmin \
     --from-literal=DB_PASSWORD=YOUR_PASSWORD \
     -n ghost-protocol-prod
   ```

3. **Restart application pods:**
   ```bash
   kubectl rollout restart deployment -n ghost-protocol-prod
   ```

4. **Investigate and fix root cause**

5. **Re-enable ExternalSecrets:**
   ```bash
   kubectl apply -k infra/k8s/overlays/production
   ```

---

**Document Version:** 1.0  
**Last Updated:** 2025-11-16  
**Next Review:** 2025-12-16  
**Owner:** Ghost Protocol DevOps Team
