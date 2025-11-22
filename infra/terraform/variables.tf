variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "ghost-protocol"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones for multi-AZ deployment"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Enable VPN Gateway"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

#============================================================================
# Networking Module Variables
#============================================================================

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all AZs (cost optimization for dev)"
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

variable "enable_s3_endpoint" {
  description = "Enable S3 VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_ecr_endpoint" {
  description = "Enable ECR VPC endpoints"
  type        = bool
  default     = true
}

variable "enable_eks_endpoint" {
  description = "Enable EKS VPC endpoint"
  type        = bool
  default     = true
}

variable "enable_ec2_endpoint" {
  description = "Enable EC2 VPC endpoints"
  type        = bool
  default     = true
}

#============================================================================
# Observability Module Variables
#============================================================================

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

variable "enable_rds_enhanced_monitoring" {
  description = "Enable RDS enhanced monitoring IAM role"
  type        = bool
  default     = true
}

#============================================================================
# OIDC/IRSA Configuration Variables (Two-Stage Workflow)
#============================================================================

variable "deployment_stage" {
  description = "Deployment stage (stage1 = initial infra without IRSA, stage2 = enable IRSA with OIDC values)"
  type        = string
  default     = "stage1"
  
  validation {
    condition     = contains(["stage1", "stage2"], var.deployment_stage)
    error_message = "deployment_stage must be 'stage1' or 'stage2'"
  }
}

variable "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN (leave empty for first apply, populate after EKS creation for second apply to enable IRSA)"
  type        = string
  default     = ""
}

variable "eks_oidc_provider_url" {
  description = "EKS OIDC provider URL (leave empty for first apply, populate after EKS creation for second apply to enable IRSA)"
  type        = string
  default     = ""
}

#============================================================================
# EKS Compute Module Variables
#============================================================================

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^1\\.(2[89]|[3-9][0-9])$", var.eks_cluster_version))
    error_message = "EKS cluster version must be 1.28 or higher."
  }
}

variable "eks_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "eks_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "eks_public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_enabled_cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  validation {
    condition = alltrue([
      for log_type in var.eks_enabled_cluster_log_types :
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "Invalid log type. Must be one of: api, audit, authenticator, controllerManager, scheduler."
  }
}

variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts (IRSA)"
  type        = bool
  default     = true
}

variable "enable_node_groups" {
  description = "Enable managed node groups"
  type        = bool
  default     = true
}

variable "general_node_group_instance_types" {
  description = "Instance types for general node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "general_node_group_capacity_type" {
  description = "Capacity type for general node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.general_node_group_capacity_type)
    error_message = "Capacity type must be ON_DEMAND or SPOT."
  }
}

variable "general_node_group_min_size" {
  description = "Minimum number of nodes in general node group"
  type        = number
  default     = 1
}

variable "general_node_group_max_size" {
  description = "Maximum number of nodes in general node group"
  type        = number
  default     = 3
}

variable "general_node_group_desired_size" {
  description = "Desired number of nodes in general node group"
  type        = number
  default     = 2
}

variable "compute_node_group_instance_types" {
  description = "Instance types for compute-optimized node group"
  type        = list(string)
  default     = ["c5.large"]
}

variable "compute_node_group_capacity_type" {
  description = "Capacity type for compute-optimized node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.compute_node_group_capacity_type)
    error_message = "Capacity type must be ON_DEMAND or SPOT."
  }
}

variable "compute_node_group_min_size" {
  description = "Minimum number of nodes in compute-optimized node group"
  type        = number
  default     = 0
}

variable "compute_node_group_max_size" {
  description = "Maximum number of nodes in compute-optimized node group"
  type        = number
  default     = 3
}

variable "compute_node_group_desired_size" {
  description = "Desired number of nodes in compute-optimized node group"
  type        = number
  default     = 1
}

variable "memory_node_group_instance_types" {
  description = "Instance types for memory-optimized node group"
  type        = list(string)
  default     = ["r5.large"]
}

variable "memory_node_group_capacity_type" {
  description = "Capacity type for memory-optimized node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.memory_node_group_capacity_type)
    error_message = "Capacity type must be ON_DEMAND or SPOT."
  }
}

variable "memory_node_group_min_size" {
  description = "Minimum number of nodes in memory-optimized node group"
  type        = number
  default     = 0
}

variable "memory_node_group_max_size" {
  description = "Maximum number of nodes in memory-optimized node group"
  type        = number
  default     = 3
}

variable "memory_node_group_desired_size" {
  description = "Desired number of nodes in memory-optimized node group"
  type        = number
  default     = 1
}

variable "enable_vpc_cni_addon" {
  description = "Enable VPC CNI addon for EKS"
  type        = bool
  default     = true
}

variable "enable_kube_proxy_addon" {
  description = "Enable kube-proxy addon for EKS"
  type        = bool
  default     = true
}

variable "enable_coredns_addon" {
  description = "Enable CoreDNS addon for EKS"
  type        = bool
  default     = true
}

variable "enable_ebs_csi_addon" {
  description = "Enable EBS CSI driver addon for EKS"
  type        = bool
  default     = true
}

#============================================================================
# RDS Database Module Variables
#============================================================================

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"

  validation {
    condition     = can(regex("^1[5-9]\\.", var.db_engine_version))
    error_message = "PostgreSQL version must be 15 or higher."
  }
}

variable "db_instance_class" {
  description = "Instance class for RDS (e.g., db.t3.micro, db.r5.large)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum storage for autoscaling (0 to disable)"
  type        = number
  default     = 100
}

variable "db_storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1"], var.db_storage_type)
    error_message = "Storage type must be gp2, gp3, or io1."
  }
}

variable "db_storage_throughput" {
  description = "Storage throughput in MB/s (gp3 only)"
  type        = number
  default     = 125
}

variable "db_name" {
  description = "Name of the initial database"
  type        = string
  default     = "ghostprotocol"
}

variable "db_master_username" {
  description = "Master username for RDS"
  type        = string
  default     = "ghostadmin"
}

variable "db_master_password" {
  description = "Master password for RDS (use AWS Secrets Manager in production)"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Port for PostgreSQL"
  type        = number
  default     = 5432
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "db_backup_window" {
  description = "Daily backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Weekly maintenance window (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "db_delete_automated_backups" {
  description = "Delete automated backups when RDS instance is deleted"
  type        = bool
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot when destroying RDS instance"
  type        = bool
  default     = false
}

variable "db_enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = ["postgresql", "upgrade"]
}

variable "db_performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = false
}

variable "db_monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 to disable, 1/5/10/15/30/60)"
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.db_monitoring_interval)
    error_message = "Monitoring interval must be 0, 1, 5, 10, 15, 30, or 60 seconds."
  }
}

variable "db_create_read_replica" {
  description = "Create read replica(s)"
  type        = bool
  default     = false
}

variable "db_read_replica_count" {
  description = "Number of read replicas to create"
  type        = number
  default     = 0
}

#============================================================================
# S3 Storage Module Variables
#============================================================================

variable "s3_enable_versioning" {
  description = "Enable versioning for S3 buckets"
  type        = bool
  default     = true
}

variable "s3_block_public_access" {
  description = "Block all public access to S3 buckets"
  type        = bool
  default     = true
}

variable "s3_enable_access_logging" {
  description = "Enable S3 access logging"
  type        = bool
  default     = true
}

variable "s3_enable_intelligent_tiering" {
  description = "Enable S3 Intelligent-Tiering"
  type        = bool
  default     = false
}

variable "s3_enable_cloudfront" {
  description = "Enable CloudFront distribution for static assets"
  type        = bool
  default     = false
}

variable "s3_enable_cross_region_replication" {
  description = "Enable cross-region replication for S3 buckets"
  type        = bool
  default     = false
}

variable "s3_replication_region" {
  description = "AWS region for S3 cross-region replication"
  type        = string
  default     = "us-west-2"
}

#============================================================================
# Secrets Module Variables
#============================================================================

variable "enable_secrets_rotation" {
  description = "Enable automatic rotation for database credentials (requires VPC configuration)"
  type        = bool
  default     = false
}

variable "database_rotation_days" {
  description = "Number of days between automatic database credential rotations"
  type        = number
  default     = 30
  
  validation {
    condition     = var.database_rotation_days >= 1 && var.database_rotation_days <= 365
    error_message = "Rotation days must be between 1 and 365"
  }
}
