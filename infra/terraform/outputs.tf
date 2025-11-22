#============================================================================
# STAGE 2 DEPLOYMENT - OIDC Provider Values
#============================================================================
# ⚠️  IMPORTANT: Copy these values to enable IRSA roles ⚠️
#
# After your FIRST terraform apply completes successfully:
# 1. Run: terraform output oidc_provider_for_stage_2
# 2. Copy the eks_oidc_provider_arn and eks_oidc_provider_url values
# 3. Add them to your environments/{env}/terraform.tfvars file
# 4. Run terraform apply again (STAGE 2)
# 5. IRSA pod roles will now be created
#
# See DEPLOYMENT_GUIDE.md for detailed instructions.
#============================================================================

output "oidc_provider_for_stage_2" {
  description = "⚠️ COPY these values to your terraform.tfvars for STAGE 2 deployment to enable IRSA roles ⚠️"
  value = {
    instructions              = "Add these to your terraform.tfvars, then run 'terraform apply' again to create IRSA pod roles"
    eks_oidc_provider_arn     = module.compute.oidc_provider_arn
    eks_oidc_provider_url     = module.compute.oidc_provider_url
  }
}

#============================================================================
# VPC and Networking Outputs
#============================================================================

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.networking.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "IDs of private application subnets"
  value       = module.networking.private_app_subnet_ids
}

output "private_data_subnet_ids" {
  description = "IDs of private data subnets"
  value       = module.networking.private_data_subnet_ids
}

output "nat_gateway_public_ips" {
  description = "Public IP addresses of NAT Gateways"
  value       = module.networking.nat_gateway_public_ips
}

#============================================================================
# Security Group Outputs
#============================================================================

output "alb_security_group_id" {
  description = "Security group ID for Application Load Balancer"
  value       = module.networking.alb_security_group_id
}

output "eks_cluster_security_group_id" {
  description = "Security group ID for EKS cluster control plane"
  value       = module.networking.eks_cluster_security_group_id
}

output "eks_nodes_security_group_id" {
  description = "Security group ID for EKS worker nodes"
  value       = module.networking.eks_nodes_security_group_id
}

output "rds_security_group_id" {
  description = "Security group ID for RDS PostgreSQL"
  value       = module.networking.rds_security_group_id
}

output "redis_security_group_id" {
  description = "Security group ID for ElastiCache Redis"
  value       = module.networking.redis_security_group_id
}

#============================================================================
# EKS Cluster Outputs
#============================================================================

output "eks_cluster_id" {
  description = "ID of the EKS cluster"
  value       = module.compute.cluster_id
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.compute.cluster_name
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.compute.cluster_arn
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS cluster API server"
  value       = module.compute.cluster_endpoint
}

output "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = module.compute.cluster_version
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster communication"
  value       = module.compute.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = module.compute.oidc_provider_arn
}

output "eks_oidc_provider_url" {
  description = "URL of the OIDC provider"
  value       = module.compute.oidc_provider_url
}

output "eks_cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer (without https://)"
  value       = module.compute.cluster_oidc_issuer_url
}

#============================================================================
# EKS Node Groups Outputs
#============================================================================

output "eks_node_group_ids" {
  description = "IDs of all EKS node groups"
  value       = module.compute.node_group_ids
}

output "eks_node_group_statuses" {
  description = "Status of all EKS node groups"
  value       = module.compute.node_group_statuses
}

#============================================================================
# RDS Database Outputs
#============================================================================

output "rds_instance_id" {
  description = "ID of the RDS instance"
  value       = module.database.db_instance_id
}

output "rds_instance_arn" {
  description = "ARN of the RDS instance"
  value       = module.database.db_instance_arn
}

output "rds_endpoint" {
  description = "Connection endpoint for the RDS instance"
  value       = module.database.db_instance_endpoint
}

output "rds_address" {
  description = "Address of the RDS instance"
  value       = module.database.db_instance_address
}

output "rds_port" {
  description = "Port of the RDS instance"
  value       = module.database.db_instance_port
}

output "rds_database_name" {
  description = "Name of the initial database"
  value       = module.database.db_instance_name
}

output "rds_connection_string" {
  description = "PostgreSQL connection string"
  value       = module.database.db_connection_string
  sensitive   = true
}

#============================================================================
# S3 Storage Outputs
#============================================================================

output "s3_bucket_ids" {
  description = "Map of bucket types to bucket IDs"
  value       = module.storage.bucket_ids
}

output "s3_bucket_arns" {
  description = "Map of bucket types to bucket ARNs"
  value       = module.storage.bucket_arns
}

output "s3_app_data_bucket_id" {
  description = "ID of the application data bucket"
  value       = module.storage.app_data_bucket_id
}

output "s3_app_data_bucket_arn" {
  description = "ARN of the application data bucket"
  value       = module.storage.app_data_bucket_arn
}

output "s3_backup_bucket_id" {
  description = "ID of the backup bucket"
  value       = module.storage.backup_bucket_id
}

output "s3_backup_bucket_arn" {
  description = "ARN of the backup bucket"
  value       = module.storage.backup_bucket_arn
}

output "s3_logs_bucket_id" {
  description = "ID of the logs bucket"
  value       = module.storage.logs_bucket_id
}

output "s3_logs_bucket_arn" {
  description = "ARN of the logs bucket"
  value       = module.storage.logs_bucket_arn
}

output "s3_static_assets_bucket_id" {
  description = "ID of the static assets bucket"
  value       = module.storage.static_assets_bucket_id
}

output "s3_static_assets_bucket_arn" {
  description = "ARN of the static assets bucket"
  value       = module.storage.static_assets_bucket_arn
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.storage.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.storage.cloudfront_domain_name
}

#============================================================================
# KMS Key Outputs
#============================================================================

output "kms_eks_secrets_key_arn" {
  description = "ARN of the KMS key for EKS secrets encryption"
  value       = module.observability.kms_eks_secrets_key_arn
}

output "kms_rds_key_arn" {
  description = "ARN of the KMS key for RDS encryption"
  value       = module.observability.kms_rds_key_arn
}

output "kms_s3_key_arn" {
  description = "ARN of the KMS key for S3 encryption"
  value       = module.observability.kms_s3_key_arn
}

output "kms_ebs_key_arn" {
  description = "ARN of the KMS key for EBS volume encryption"
  value       = module.observability.kms_ebs_key_arn
}

output "kms_cloudwatch_logs_key_arn" {
  description = "ARN of the KMS key for CloudWatch Logs encryption"
  value       = module.observability.kms_cloudwatch_logs_key_arn
}

output "kms_keys" {
  description = "Map of all KMS key details"
  value       = module.observability.kms_keys
}

#============================================================================
# IAM Role Outputs
#============================================================================

output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = module.observability.eks_cluster_role_arn
}

output "eks_node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = module.observability.eks_node_role_arn
}

output "pod_roles" {
  description = "Map of all pod IAM role details (IRSA)"
  value       = module.observability.pod_roles
}

output "api_gateway_irsa_role_arn" {
  description = "ARN of the API Gateway pod IAM role (IRSA)"
  value       = module.observability.api_gateway_pod_role_arn
}

output "indexer_irsa_role_arn" {
  description = "ARN of the Indexer pod IAM role (IRSA)"
  value       = module.observability.indexer_pod_role_arn
}

output "rpc_orchestrator_irsa_role_arn" {
  description = "ARN of the RPC Orchestrator pod IAM role (IRSA)"
  value       = module.observability.rpc_orchestrator_pod_role_arn
}

output "ai_engine_irsa_role_arn" {
  description = "ARN of the AI Engine pod IAM role (IRSA)"
  value       = module.observability.ai_engine_pod_role_arn
}

#============================================================================
# CloudWatch Log Groups Outputs
#============================================================================

output "eks_cluster_log_group_name" {
  description = "Name of the EKS cluster CloudWatch log group"
  value       = module.observability.eks_cluster_log_group_name
}

output "application_log_group_names" {
  description = "Map of application service names to their CloudWatch log group names"
  value       = module.observability.application_log_group_names
}

output "vpc_flow_log_group_name" {
  description = "Name of the VPC flow logs CloudWatch log group"
  value       = module.observability.vpc_flow_log_group_name
}

output "audit_log_group_name" {
  description = "Name of the audit CloudWatch log group"
  value       = module.observability.audit_log_group_name
}

#============================================================================
# Secrets Module Outputs
#============================================================================

output "secret_arns" {
  description = "Map of secret names to their ARNs"
  value       = module.secrets.secret_arns
}

output "database_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = module.secrets.database_secret_arn
}

output "database_secret_name" {
  description = "Name of the database credentials secret"
  value       = module.secrets.database_secret_name
}

output "redis_secret_arn" {
  description = "ARN of the Redis password secret"
  value       = module.secrets.redis_secret_arn
}

output "redis_secret_name" {
  description = "Name of the Redis password secret"
  value       = module.secrets.redis_secret_name
}

output "openai_api_key_secret_arn" {
  description = "ARN of the OpenAI API key secret"
  value       = module.secrets.openai_api_key_secret_arn
}

output "openai_api_key_secret_name" {
  description = "Name of the OpenAI API key secret"
  value       = module.secrets.openai_api_key_secret_name
}

output "huggingface_api_key_secret_arn" {
  description = "ARN of the Hugging Face API key secret"
  value       = module.secrets.huggingface_api_key_secret_arn
}

output "huggingface_api_key_secret_name" {
  description = "Name of the Hugging Face API key secret"
  value       = module.secrets.huggingface_api_key_secret_name
}

output "rotation_lambda_arn" {
  description = "ARN of the rotation Lambda function (null if rotation disabled)"
  value       = module.secrets.rotation_lambda_arn
}

output "rotation_lambda_name" {
  description = "Name of the rotation Lambda function (null if rotation disabled)"
  value       = module.secrets.rotation_lambda_name
}

output "external_secrets_operator_role_arn" {
  description = "ARN of the External Secrets Operator IAM role for IRSA (null if STAGE 1)"
  value       = module.secrets.external_secrets_operator_role_arn
}

output "external_secrets_operator_role_name" {
  description = "Name of the External Secrets Operator IAM role for IRSA (null if STAGE 1)"
  value       = module.secrets.external_secrets_operator_role_name
}

output "external_secrets_irsa_annotation" {
  description = "IRSA annotation value for External Secrets Operator ServiceAccount"
  value = module.secrets.external_secrets_operator_role_arn != null ? {
    "eks.amazonaws.com/role-arn" = module.secrets.external_secrets_operator_role_arn
  } : {}
}

#============================================================================
# Summary Outputs
#============================================================================

output "infrastructure_summary" {
  description = "Summary of deployed infrastructure"
  value = {
    environment         = var.environment
    region              = var.aws_region
    vpc_id              = module.networking.vpc_id
    eks_cluster_name    = module.compute.cluster_name
    eks_cluster_endpoint = module.compute.cluster_endpoint
    rds_endpoint        = module.database.db_instance_endpoint
    s3_buckets          = keys(module.storage.bucket_ids)
  }
}
