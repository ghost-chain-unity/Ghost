# Terraform Infrastructure

This directory contains Terraform configuration for the Ghost Protocol infrastructure.

## Prerequisites

- Terraform >= 1.6.0
- AWS CLI configured with appropriate credentials
- AWS account with permissions to create VPCs, S3 buckets, DynamoDB tables, and IAM roles

## Initial Setup (First-Time Bootstrap)

Before you can use the remote S3 backend, you need to create the backend infrastructure. This is a one-time setup.

### Step 1: Bootstrap Backend Resources

1. **Comment out the remote backend configuration** in `backend.tf`:
   ```hcl
   # terraform {
   #   backend "s3" {
   #     bucket         = "ghost-protocol-terraform-state"
   #     key            = "terraform.tfstate"
   #     region         = "us-east-1"
   #     encrypt        = true
   #     dynamodb_table = "ghost-protocol-terraform-locks"
   #   }
   # }
   ```

2. **Uncomment the bootstrap resources** in `backend-bootstrap.tf`:
   - Uncomment the `aws_s3_bucket` resource
   - Uncomment the `aws_s3_bucket_versioning` resource
   - Uncomment the `aws_s3_bucket_server_side_encryption_configuration` resource
   - Uncomment the `aws_dynamodb_table` resource

3. **Initialize and apply the bootstrap configuration**:
   ```bash
   cd infra/terraform
   terraform init
   terraform apply
   ```
   
   This will create:
   - S3 bucket: `ghost-protocol-terraform-state`
   - DynamoDB table: `ghost-protocol-terraform-locks`

4. **Re-enable the remote backend**:
   - Uncomment the backend configuration in `backend.tf`
   - Comment out the bootstrap resources in `backend-bootstrap.tf`

5. **Migrate state to remote backend**:
   ```bash
   terraform init -migrate-state
   ```
   
   Type "yes" when prompted to migrate the state.

6. **Verify the migration**:
   ```bash
   terraform plan
   ```
   
   You should see no changes needed. Your state is now stored remotely in S3.

### Step 2: Deploy Environment Infrastructure

After bootstrapping the backend, you can deploy environment-specific infrastructure:

```bash
# For development environment
terraform workspace new dev || terraform workspace select dev
terraform apply -var-file="environments/dev/terraform.tfvars"

# For staging environment
terraform workspace new staging || terraform workspace select staging
terraform apply -var-file="environments/staging/terraform.tfvars"

# For production environment
terraform workspace new prod || terraform workspace select prod
terraform apply -var-file="environments/prod/terraform.tfvars"
```

## Normal Usage (After Bootstrap)

Once the backend is bootstrapped, you can work with Terraform normally:

```bash
cd infra/terraform

# Initialize (downloads providers and configures backend)
terraform init

# Select workspace
terraform workspace select dev

# Plan changes
terraform plan -var-file="environments/dev/terraform.tfvars"

# Apply changes
terraform apply -var-file="environments/dev/terraform.tfvars"

# Destroy resources (use with caution)
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

## Directory Structure

```
infra/terraform/
├── backend.tf              # Remote backend configuration
├── backend-bootstrap.tf    # Bootstrap resources for backend (commented by default)
├── provider.tf            # AWS provider configuration
├── versions.tf            # Terraform and provider version constraints
├── variables.tf           # Root module variables
├── locals.tf              # Local values
├── modules/
│   └── networking/
│       └── aws/           # AWS VPC networking module
└── environments/
    ├── dev/               # Development environment variables
    ├── staging/           # Staging environment variables
    └── prod/              # Production environment variables
```

## Modules

### networking/aws

Creates a multi-tier VPC with:
- Public subnets for load balancers and bastion hosts
- Private app subnets for application workloads
- Private data subnets for databases
- NAT Gateways for private subnet internet access
- VPC Flow Logs for network monitoring
- VPC Endpoints for AWS services

## State Management

- **State Storage**: S3 bucket `ghost-protocol-terraform-state`
- **State Locking**: DynamoDB table `ghost-protocol-terraform-locks`
- **Encryption**: State is encrypted at rest using AES-256
- **Versioning**: S3 bucket versioning is enabled for state recovery

## Security Notes

- State files are encrypted in S3
- DynamoDB is used for state locking to prevent concurrent modifications
- VPC Flow Logs are enabled by default for network monitoring
- IAM policies follow least-privilege principles with scoped resource ARNs

## Troubleshooting

### Backend Initialization Fails

If `terraform init` fails with "bucket does not exist":
- You need to complete the bootstrap process (see Initial Setup above)
- Verify the S3 bucket exists: `aws s3 ls s3://ghost-protocol-terraform-state`

### State Lock Errors

If you encounter state lock errors:
```bash
# List locks
aws dynamodb scan --table-name ghost-protocol-terraform-locks

# Force unlock (use with extreme caution)
terraform force-unlock <LOCK_ID>
```

### VPC Flow Logs Creation Fails

If flow logs fail to create, verify:
- CloudWatch Logs log group exists
- IAM role has correct permissions (CreateLogStream, PutLogEvents)
- IAM role trust policy allows vpc-flow-logs.amazonaws.com

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [Terraform Backend Configuration](https://www.terraform.io/docs/language/settings/backends/s3.html)
