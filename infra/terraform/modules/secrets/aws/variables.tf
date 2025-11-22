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

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID for ARN construction"
  type        = string
}

variable "eks_secrets_kms_key_arn" {
  description = "ARN of the KMS key for secrets encryption (from observability module)"
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

variable "database_rotation_days" {
  description = "Number of days between automatic database credential rotation"
  type        = number
  default     = 30
  validation {
    condition     = var.database_rotation_days >= 1 && var.database_rotation_days <= 365
    error_message = "Database rotation days must be between 1 and 365"
  }
}

variable "rds_instance_endpoint" {
  description = "RDS instance endpoint for rotation Lambda (format: hostname:port)"
  type        = string
  default     = ""
}

variable "rds_instance_identifier" {
  description = "RDS instance identifier for rotation Lambda"
  type        = string
  default     = ""
}

variable "database_name" {
  description = "Database name for rotation Lambda"
  type        = string
  default     = "ghostprotocol"
}

variable "database_username" {
  description = "Master database username for rotation Lambda"
  type        = string
  default     = "ghostadmin"
}

variable "vpc_subnet_ids" {
  description = "VPC subnet IDs for rotation Lambda (required for RDS access)"
  type        = list(string)
  default     = []
}

variable "vpc_security_group_ids" {
  description = "VPC security group IDs for rotation Lambda (required for RDS access)"
  type        = list(string)
  default     = []
}

variable "enable_rotation" {
  description = "Enable automatic rotation for database credentials"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
