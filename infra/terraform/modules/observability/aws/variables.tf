variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod/production)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod", "production"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, production"
  }
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID for KMS key policies"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider for IRSA (leave empty if EKS not yet created)"
  type        = string
  default     = ""
}

variable "eks_oidc_provider_url" {
  description = "URL of the EKS OIDC provider for IRSA (leave empty if EKS not yet created)"
  type        = string
  default     = ""
}

variable "application_services" {
  description = "List of application service names for log groups"
  type        = list(string)
  default     = ["api-gateway", "indexer", "rpc-orchestrator", "ai-engine"]
}

variable "rds_instance_names" {
  description = "List of RDS instance names for log groups"
  type        = list(string)
  default     = ["main"]
}

variable "lambda_function_names" {
  description = "List of Lambda function names for log groups"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Default log retention in days"
  type        = number
  default     = 30
}

variable "eks_log_retention_days" {
  description = "EKS cluster log retention in days"
  type        = number
  default     = 7
}

variable "application_log_retention_days" {
  description = "Application log retention in days"
  type        = number
  default     = 30
}

variable "vpc_flow_log_retention_days" {
  description = "VPC flow log retention in days"
  type        = number
  default     = 7
}

variable "rds_log_retention_days" {
  description = "RDS log retention in days"
  type        = number
  default     = 7
}

variable "lambda_log_retention_days" {
  description = "Lambda log retention in days"
  type        = number
  default     = 30
}

variable "audit_log_retention_days" {
  description = "Audit log retention in days (compliance requirement)"
  type        = number
  default     = 90
}

variable "enable_kms_key_rotation" {
  description = "Enable automatic KMS key rotation (annual)"
  type        = bool
  default     = true
}

variable "kms_deletion_window_days" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30
}

variable "vpc_id" {
  description = "VPC ID for security group references (optional)"
  type        = string
  default     = ""
}

variable "enable_rds_enhanced_monitoring" {
  description = "Enable RDS enhanced monitoring IAM role"
  type        = bool
  default     = true
}

variable "enable_lambda_roles" {
  description = "Enable Lambda execution IAM roles"
  type        = bool
  default     = false
}

variable "api_gateway_permissions" {
  description = "Additional IAM permissions for API Gateway pod role"
  type        = list(string)
  default     = []
}

variable "indexer_permissions" {
  description = "Additional IAM permissions for Indexer pod role"
  type        = list(string)
  default     = []
}

variable "rpc_orchestrator_permissions" {
  description = "Additional IAM permissions for RPC Orchestrator pod role"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_mfa_for_roles" {
  description = "Require MFA for sensitive IAM role assumptions (future use)"
  type        = bool
  default     = false
}

variable "create_vpc_flow_log_group" {
  description = "Create CloudWatch log group for VPC flow logs (set false if using networking module's log group)"
  type        = bool
  default     = false
}

variable "project_name" {
  description = "Project name for S3 bucket naming (e.g., ghost-protocol)"
  type        = string
  default     = "ghost-protocol"
}

variable "loki_chunks_retention_days" {
  description = "Retention period for Loki chunks in S3 (days)"
  type        = number
  default     = 30
}

variable "loki_enable_intelligent_tiering" {
  description = "Enable S3 Intelligent-Tiering for Loki chunks (cost optimization)"
  type        = bool
  default     = true
}

variable "loki_namespace" {
  description = "Kubernetes namespace for Loki deployment"
  type        = string
  default     = "ghost-protocol-monitoring"
}

variable "logs_bucket_name" {
  description = "Name of the logs bucket for S3 access logging (empty = auto-generate)"
  type        = string
  default     = ""
}
