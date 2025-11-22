# Terraform Infrastructure Deployment Guide

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Understanding the Two-Stage Deployment](#understanding-the-two-stage-deployment)
- [Stage 1: Initial Infrastructure Deployment](#stage-1-initial-infrastructure-deployment)
- [Stage 2: Enable IRSA Roles](#stage-2-enable-irsa-roles)
- [Validation Steps](#validation-steps)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

---

## Overview

This infrastructure uses a **two-stage deployment workflow** controlled by a single `deployment_stage` variable to resolve a circular dependency between the Observability and Compute modules regarding OIDC provider configuration for IRSA (IAM Roles for Service Accounts).

### Why Two Stages?

**The Problem:**
- The Observability module creates KMS keys, IAM roles, and log groups needed by other modules
- The Compute module creates the EKS cluster which generates the OIDC provider
- Both modules need OIDC provider values to create IRSA resources
- But the OIDC provider doesn't exist until the EKS cluster is created → chicken-and-egg problem

**The Solution - Simple Deployment Stage Toggle:**
- **Stage 1** (`deployment_stage = "stage1"`): Deploy infrastructure without IRSA → No IRSA pod roles created yet
- **Stage 2** (`deployment_stage = "stage2"`): Re-deploy with OIDC values → IRSA roles are created

The `deployment_stage` variable automatically controls:
- OIDC values passed to the observability module
- IRSA enablement in the compute module
- This ensures both modules are properly coordinated

---

## Prerequisites

Before starting the deployment, ensure you have:

### Required Tools
- **Terraform**: Version 1.5.0 or higher
  ```bash
  terraform version
  ```
- **AWS CLI**: Configured with appropriate credentials
  ```bash
  aws --version
  aws sts get-caller-identity
  ```

### AWS Permissions
Your AWS IAM user/role must have permissions to create:
- VPC, Subnets, NAT Gateways, Internet Gateways
- EKS Clusters, Node Groups
- RDS Instances
- S3 Buckets, CloudFront Distributions
- KMS Keys
- IAM Roles and Policies
- CloudWatch Log Groups
- Security Groups

### Environment Selection
Choose your target environment:
- `dev` - Development (cost-optimized)
- `staging` - Staging (production-like)
- `prod` - Production (high availability)

### Secret Management

The infrastructure requires sensitive values that **MUST NEVER** be committed to version control:

#### Database Master Password (`db_master_password`)

This variable is marked as `sensitive = true` in Terraform and requires special handling:

**Development/Staging:**
```bash
export TF_VAR_db_master_password="your-secure-password-here"
terraform apply -var-file="environments/dev/terraform.tfvars"
```

**Production (Recommended):**
Use AWS Secrets Manager for automatic password rotation:

1. Create secret in AWS Secrets Manager:
   ```bash
   aws secretsmanager create-secret \
     --name ghost-protocol-prod-db-password \
     --secret-string "your-secure-password-here" \
     --region us-east-1
   ```

2. Reference in Terraform using data source:
   ```hcl
   data "aws_secretsmanager_secret_version" "db_password" {
     secret_id = "ghost-protocol-prod-db-password"
   }
   
   locals {
     db_master_password = data.aws_secretsmanager_secret_version.db_password.secret_string
   }
   ```

**SECURITY RULES:**
- ❌ **NEVER** add `db_master_password` to `.tfvars` files
- ❌ **NEVER** commit passwords to Git
- ✅ **ALWAYS** use environment variables or Secrets Manager
- ✅ **ALWAYS** use strong passwords (min 16 characters, mixed case, numbers, symbols)
- ✅ **ROTATE** passwords regularly in production

---

## Understanding the Two-Stage Deployment

### Stage 1: Initial Infrastructure
```
┌─────────────────────────────────────────────────────────────┐
│ STAGE 1: deployment_stage = "stage1"                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Observability Module                                   │
│     ├─ KMS Keys (EKS, RDS, S3, EBS, CloudWatch)           │
│     ├─ IAM Roles (EKS Cluster, Node Groups)               │
│     ├─ CloudWatch Log Groups                              │
│     └─ ❌ NO IRSA Pod Roles (deployment_stage = stage1)   │
│                                                             │
│  2. Networking Module                                      │
│     ├─ VPC, Subnets, Route Tables                         │
│     ├─ NAT Gateways, Internet Gateway                     │
│     └─ Security Groups                                     │
│                                                             │
│  3. Compute Module                                         │
│     ├─ EKS Cluster                                         │
│     ├─ Node Groups                                         │
│     ├─ ✅ OIDC Provider (CREATED!)                        │
│     └─ ❌ IRSA Disabled (deployment_stage = stage1)       │
│                                                             │
│  4. Database & Storage Modules                             │
│     ├─ RDS PostgreSQL                                      │
│     └─ S3 Buckets                                          │
│                                                             │
│  OUTPUT: terraform output oidc_provider_for_stage_2        │
│          └─ Get OIDC ARN and URL for Stage 2               │
└─────────────────────────────────────────────────────────────┘
```

### Stage 2: Enable IRSA
```
┌─────────────────────────────────────────────────────────────┐
│ STAGE 2: deployment_stage = "stage2"                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Update terraform.tfvars:                               │
│     deployment_stage = "stage2"                            │
│     eks_oidc_provider_arn = "arn:aws:iam::..."            │
│     eks_oidc_provider_url = "https://oidc.eks..."         │
│                                                             │
│  2. Run terraform apply again                              │
│                                                             │
│  3. Observability Module (UPDATE)                          │
│     └─ ✅ IRSA Pod Roles NOW CREATED                      │
│        ├─ AWS Load Balancer Controller Role                │
│        ├─ External DNS Role                                │
│        ├─ Cluster Autoscaler Role                          │
│        ├─ EBS CSI Driver Role                              │
│        └─ FluentBit Role                                   │
│                                                             │
│  4. Compute Module (UPDATE)                                │
│     └─ ✅ IRSA NOW ENABLED                                │
│                                                             │
│  5. Other modules (NO CHANGE)                              │
│                                                             │
│  RESULT: Full infrastructure with IRSA enabled!            │
└─────────────────────────────────────────────────────────────┘
```

---

## Stage 1: Initial Infrastructure Deployment

### Step 1: Initialize Terraform Backend

Navigate to the terraform directory:
```bash
cd infra/terraform
```

Initialize Terraform (downloads providers and sets up backend):
```bash
terraform init
```

Expected output:
```
Terraform has been successfully initialized!
```

### Step 2: Review Configuration

Choose your environment and review the tfvars file:
```bash
# For development
cat environments/dev/terraform.tfvars

# For staging
cat environments/staging/terraform.tfvars

# For production
cat environments/prod/terraform.tfvars
```

**IMPORTANT**: Verify that `deployment_stage = "stage1"` is set:
```hcl
# Stage 1 configuration:
deployment_stage = "stage1"

# OIDC values should be empty for Stage 1:
eks_oidc_provider_arn = ""
eks_oidc_provider_url = ""
```

This ensures that IRSA resources are NOT created in Stage 1 (since the OIDC provider doesn't exist yet).

### Step 3: Create Terraform Plan

Generate an execution plan to review what will be created:

```bash
# Development
terraform plan -var-file=environments/dev/terraform.tfvars -out=dev-stage1.tfplan

# Staging
terraform plan -var-file=environments/staging/terraform.tfvars -out=staging-stage1.tfplan

# Production
terraform plan -var-file=environments/prod/terraform.tfvars -out=prod-stage1.tfplan
```

Review the plan output carefully:
- Check resource counts (should be 100+ resources)
- Verify no errors or warnings
- Confirm all expected resources are included

### Step 4: Apply Infrastructure (Stage 1)

Apply the Terraform configuration:

```bash
# Development (10-15 minutes)
terraform apply dev-stage1.tfplan

# Staging (15-20 minutes)
terraform apply staging-stage1.tfplan

# Production (20-25 minutes)
terraform apply prod-stage1.tfplan
```

**What's happening:**
- VPC and networking resources are created
- KMS keys are created
- IAM roles for EKS are created
- EKS cluster is provisioned (takes 10-15 minutes)
- Node groups are created
- RDS database is provisioned
- S3 buckets are created
- **IRSA pod roles are NOT created (expected)**

Wait for the apply to complete successfully. You should see:
```
Apply complete! Resources: 120 added, 0 changed, 0 destroyed.
```

### Step 5: Retrieve OIDC Provider Values

After Stage 1 completes successfully, get the OIDC provider values:

```bash
terraform output oidc_provider_for_stage_2
```

Example output:
```hcl
{
  "eks_oidc_provider_arn" = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
  "eks_oidc_provider_url" = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
  "instructions" = "Add these to your terraform.tfvars, then run 'terraform apply' again to create IRSA pod roles"
}
```

**IMPORTANT**: Copy both the ARN and URL values - you'll need them for Stage 2.

---

## Stage 2: Enable IRSA Roles

### Step 1: Update terraform.tfvars

Edit your environment's terraform.tfvars file:

```bash
# Development
vim environments/dev/terraform.tfvars

# Staging
vim environments/staging/terraform.tfvars

# Production
vim environments/prod/terraform.tfvars
```

Make TWO changes:
1. Change `deployment_stage` from "stage1" to "stage2"
2. Uncomment and populate the OIDC values from Stage 1 output

**BEFORE (Stage 1):**
```hcl
# START WITH STAGE 1 for initial deployment
deployment_stage = "stage1"

# STAGE 1: Leave these empty (required but not used)
eks_oidc_provider_arn = ""
eks_oidc_provider_url = ""

# STAGE 2: After first apply, get values from:
#   terraform output oidc_provider_for_stage_2
# Then uncomment and populate:
# deployment_stage = "stage2"
# eks_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
# eks_oidc_provider_url = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
```

**AFTER (Stage 2):**
```hcl
# STAGE 2: OIDC values from Stage 1 output
deployment_stage = "stage2"

# Actual OIDC values from terraform output
eks_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
eks_oidc_provider_url = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
```

Save the file.

### Step 2: Create Terraform Plan (Stage 2)

Generate a new execution plan:

```bash
# Development
terraform plan -var-file=environments/dev/terraform.tfvars -out=dev-stage2.tfplan

# Staging
terraform plan -var-file=environments/staging/terraform.tfvars -out=staging-stage2.tfplan

# Production
terraform plan -var-file=environments/prod/terraform.tfvars -out=prod-stage2.tfplan
```

**Expected changes:**
- You should see ~5-10 resources will be **added** (IRSA pod IAM roles)
- No resources should be **destroyed** or significantly **changed**
- Look for resources like:
  - `aws_iam_role.aws_load_balancer_controller`
  - `aws_iam_role.external_dns`
  - `aws_iam_role.cluster_autoscaler`
  - `aws_iam_role.ebs_csi_driver`
  - `aws_iam_role.fluentbit`

### Step 3: Apply Infrastructure (Stage 2)

Apply the Stage 2 configuration:

```bash
# Development (2-3 minutes)
terraform apply dev-stage2.tfplan

# Staging (2-3 minutes)
terraform apply staging-stage2.tfplan

# Production (2-3 minutes)
terraform apply prod-stage2.tfplan
```

You should see:
```
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

**Congratulations!** Your infrastructure is now fully deployed with IRSA enabled! 🎉

---

## Validation Steps

### 1. Verify EKS Cluster

Configure kubectl to connect to your cluster:

```bash
# Get cluster name from output
CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
AWS_REGION=$(terraform output -raw aws_region)

# Update kubeconfig
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION

# Verify connection
kubectl get nodes
```

Expected output:
```
NAME                          STATUS   ROLES    AGE   VERSION
ip-10-0-1-123.ec2.internal   Ready    <none>   15m   v1.28.x
ip-10-0-2-234.ec2.internal   Ready    <none>   15m   v1.28.x
```

### 2. Verify OIDC Provider

Check that the OIDC provider exists:

```bash
# Get OIDC provider ARN
OIDC_ARN=$(terraform output -raw eks_oidc_provider_arn)

# Verify in AWS
aws iam list-open-id-connect-providers | grep $OIDC_ARN
```

### 3. Verify IRSA Roles

List the created IRSA roles:

```bash
aws iam list-roles | grep -E "(aws-load-balancer-controller|external-dns|cluster-autoscaler|ebs-csi-driver|fluentbit)"
```

You should see 5+ IAM roles for various Kubernetes service accounts.

### 4. Verify RDS Database

Check RDS instance status:

```bash
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
echo "RDS Endpoint: $RDS_ENDPOINT"

aws rds describe-db-instances --query 'DBInstances[].DBInstanceStatus'
```

Expected: `"available"`

### 5. Verify S3 Buckets

List created S3 buckets:

```bash
terraform output s3_bucket_ids
```

Verify buckets exist:

```bash
aws s3 ls | grep ghost-protocol
```

---

## Troubleshooting

### Issue: Terraform Init Fails

**Symptom:**
```
Error: Failed to get existing workspaces
```

**Solution:**
1. Check AWS credentials: `aws sts get-caller-identity`
2. Verify S3 backend bucket exists
3. Check DynamoDB lock table exists
4. Ensure you have permissions to access backend resources

### Issue: Stage 1 Apply Fails - EKS Cluster Timeout

**Symptom:**
```
Error: error waiting for EKS Cluster to be created: timeout while waiting
```

**Solution:**
1. EKS cluster creation takes 10-15 minutes - be patient
2. Check AWS Service Health Dashboard for EKS issues
3. Verify you have sufficient EKS quota in your AWS account
4. If timeout persists, increase timeout in `modules/compute/aws/main.tf`

### Issue: Cannot Get OIDC Output After Stage 1

**Symptom:**
```
Error: Output not found: oidc_provider_for_stage_2
```

**Solution:**
1. Ensure Stage 1 completed successfully
2. Run `terraform refresh` to update state
3. Try `terraform output` to see all outputs
4. Manually get OIDC from AWS Console:
   - EKS → Clusters → [Your Cluster] → Configuration → Details → OpenID Connect provider URL

### Issue: Stage 2 Shows No Changes

**Symptom:**
```
No changes. Your infrastructure matches the configuration.
```

**Solution:**
1. Verify you changed `deployment_stage` to "stage2" in terraform.tfvars
2. Verify you uncommented and populated the OIDC variables in terraform.tfvars
3. Check that the OIDC values match exactly from Stage 1 output
4. Remove any leading/trailing spaces or quotes
5. Run `terraform plan` with `-var-file` flag explicitly
6. Check `modules/observability/aws/iam_pods.tf` - IRSA roles should have conditions checking for empty OIDC values

### Issue: Permission Denied Errors

**Symptom:**
```
Error: AccessDenied: User is not authorized to perform: iam:CreateRole
```

**Solution:**
1. Verify your AWS IAM user/role has sufficient permissions
2. Check for SCP (Service Control Policies) restrictions
3. Review the permission boundary if one is applied
4. Contact your AWS administrator for required permissions

### Issue: Rate Limiting / Too Many Requests

**Symptom:**
```
Error: error creating EKS Node Group: TooManyRequestsException: Rate exceeded
```

**Solution:**
1. Wait a few minutes and retry
2. Consider deploying to different AWS region if persistent
3. Contact AWS Support to increase API rate limits

---

## FAQ

### Q: Can I skip Stage 1 and go directly to Stage 2?

**A:** No. You must complete Stage 1 first to create the EKS cluster and OIDC provider. The OIDC values don't exist until the EKS cluster is created.

### Q: What happens if I run Stage 2 multiple times?

**A:** It's safe. Terraform is idempotent - running apply multiple times with the same configuration won't create duplicate resources.

### Q: Can I destroy and recreate just the IRSA roles?

**A:** Yes, but it's not recommended. If you need to recreate IRSA roles:
```bash
terraform destroy -target=module.observability.aws_iam_role.aws_load_balancer_controller
terraform apply -var-file=environments/{env}/terraform.tfvars
```

### Q: How do I upgrade the EKS cluster version?

**A:** 
1. Update `eks_cluster_version` in terraform.tfvars
2. Run `terraform plan` to see upgrade path
3. Run `terraform apply` - EKS will perform rolling upgrade
4. Note: Major version upgrades should be done incrementally (1.27 → 1.28 → 1.29)

### Q: What if I need to add more IRSA roles later?

**A:** 
1. Add the new IAM role in `modules/observability/aws/iam_pods.tf`
2. Ensure it uses the OIDC provider variables
3. Run `terraform plan` and `terraform apply`
4. The OIDC values are already configured from Stage 2

### Q: Can I use this in CI/CD pipelines?

**A:** Yes! Example GitLab CI or GitHub Actions:

```yaml
# Stage 1
stage1:
  script:
    - terraform init
    - terraform apply -auto-approve -var-file=environments/dev/terraform.tfvars
    - terraform output -json oidc_provider_for_stage_2 > oidc.json

# Stage 2
stage2:
  script:
    - export TF_VAR_deployment_stage="stage2"
    - export TF_VAR_eks_oidc_provider_arn=$(cat oidc.json | jq -r '.eks_oidc_provider_arn')
    - export TF_VAR_eks_oidc_provider_url=$(cat oidc.json | jq -r '.eks_oidc_provider_url')
    - terraform apply -auto-approve -var-file=environments/dev/terraform.tfvars
```

### Q: How much does this infrastructure cost?

**A:** Approximate monthly costs:

- **Development**: $150-200/month
  - EKS cluster: $72
  - t3.small nodes (1 node): $15
  - RDS db.t3.micro: $15
  - NAT Gateway (1): $32
  - Other services: $20-40

- **Staging**: $400-500/month
  - EKS cluster: $72
  - t3.medium nodes (2 nodes): $60
  - RDS db.t3.small Multi-AZ: $60
  - NAT Gateways (2): $64
  - Other services: $144-244

- **Production**: $1,500-2,000/month
  - EKS cluster: $72
  - t3.large/c5.xlarge/r5.xlarge nodes: $600-800
  - RDS db.r5.large Multi-AZ + replicas: $500-600
  - NAT Gateways (2): $64
  - CloudFront, S3, monitoring: $264-464

### Q: Is there a way to automate both stages?

**A:** Yes, with a script:

```bash
#!/bin/bash
set -e

ENV=$1  # dev, staging, or prod

echo "=== STAGE 1: Initial Deployment (deployment_stage=stage1) ==="
terraform apply -auto-approve -var-file=environments/${ENV}/terraform.tfvars

echo "=== Retrieving OIDC values ==="
OIDC_ARN=$(terraform output -raw eks_oidc_provider_arn)
OIDC_URL=$(terraform output -raw eks_oidc_provider_url)

echo "=== STAGE 2: Enabling IRSA (deployment_stage=stage2) ==="
terraform apply -auto-approve \
  -var-file=environments/${ENV}/terraform.tfvars \
  -var="deployment_stage=stage2" \
  -var="eks_oidc_provider_arn=${OIDC_ARN}" \
  -var="eks_oidc_provider_url=${OIDC_URL}"

echo "=== Deployment Complete ==="
```

---

## Summary

You've successfully deployed the Ghost Protocol infrastructure using the two-stage workflow!

**Stage 1 Checklist:**
- ✅ Terraform initialized
- ✅ Infrastructure deployed (VPC, EKS, RDS, S3)
- ✅ OIDC provider created
- ✅ OIDC values retrieved

**Stage 2 Checklist:**
- ✅ terraform.tfvars updated with OIDC values
- ✅ IRSA pod roles created
- ✅ Infrastructure validated

**Next Steps:**
1. Deploy Kubernetes applications using IRSA roles
2. Configure AWS Load Balancer Controller
3. Set up External DNS
4. Enable Cluster Autoscaler
5. Configure monitoring and logging with FluentBit

For questions or issues, please refer to the troubleshooting section or contact the DevOps team.

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-16  
**Maintained By**: DevOps Team
