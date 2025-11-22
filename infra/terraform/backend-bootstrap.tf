# Backend Bootstrap Resources
# 
# IMPORTANT: These resources are used ONLY for initial backend setup.
# 
# Initial Setup Process:
# 1. Comment out the backend configuration in backend.tf
# 2. Uncomment the resources below
# 3. Run: terraform init && terraform apply
# 4. Re-comment the resources below
# 5. Uncomment the backend configuration in backend.tf
# 6. Run: terraform init -migrate-state
#
# After bootstrap, these resources should remain commented out.
# The backend will be managed separately and should not be modified by this configuration.

# Uncomment this block for initial backend bootstrap
# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "ghost-protocol-terraform-state"
# 
#   tags = {
#     Name        = "Terraform State Bucket"
#     Environment = "global"
#     ManagedBy   = "Terraform"
#     Purpose     = "terraform-state-storage"
#   }
# 
#   lifecycle {
#     prevent_destroy = true
#   }
# }

# Uncomment this block for initial backend bootstrap
# resource "aws_s3_bucket_versioning" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id
# 
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# Uncomment this block for initial backend bootstrap
# resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id
# 
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# Uncomment this block for initial backend bootstrap
# resource "aws_s3_bucket_public_access_block" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id
# 
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# Uncomment this block for initial backend bootstrap
# resource "aws_dynamodb_table" "terraform_locks" {
#   name         = "ghost-protocol-terraform-locks"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"
# 
#   attribute {
#     name = "LockID"
#     type = "S"
#   }
# 
#   tags = {
#     Name        = "Terraform State Lock Table"
#     Environment = "global"
#     ManagedBy   = "Terraform"
#     Purpose     = "terraform-state-locking"
#   }
# 
#   lifecycle {
#     prevent_destroy = true
#   }
# }

# Outputs for verification (uncomment during bootstrap)
# output "terraform_state_bucket" {
#   description = "The name of the S3 bucket for Terraform state"
#   value       = aws_s3_bucket.terraform_state.id
# }
# 
# output "terraform_state_bucket_arn" {
#   description = "The ARN of the S3 bucket for Terraform state"
#   value       = aws_s3_bucket.terraform_state.arn
# }
# 
# output "terraform_locks_table" {
#   description = "The name of the DynamoDB table for Terraform locks"
#   value       = aws_dynamodb_table.terraform_locks.id
# }
# 
# output "terraform_locks_table_arn" {
#   description = "The ARN of the DynamoDB table for Terraform locks"
#   value       = aws_dynamodb_table.terraform_locks.arn
# }
