variable "identifier" {
  description = "Identifier for the RDS instance"
  type        = string
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"

  validation {
    condition     = can(regex("^1[5-9]\\.", var.engine_version))
    error_message = "PostgreSQL version must be 15 or higher."
  }
}

variable "instance_class" {
  description = "Instance class for RDS (e.g., db.t3.micro, db.r5.large)"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage for autoscaling (0 to disable)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (gp2, gp3, io1)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1"], var.storage_type)
    error_message = "Storage type must be gp2, gp3, or io1."
  }
}

variable "iops" {
  description = "Provisioned IOPS (required for io1, optional for gp3)"
  type        = number
  default     = null
}

variable "storage_throughput" {
  description = "Storage throughput in MB/s (gp3 only)"
  type        = number
  default     = 125
}

variable "kms_key_arn" {
  description = "ARN of KMS key for RDS encryption (from observability module)"
  type        = string
}

variable "database_name" {
  description = "Name of the initial database"
  type        = string
  default     = "ghostprotocol"
}

variable "master_username" {
  description = "Master username for RDS"
  type        = string
  default     = "ghostadmin"
}

variable "master_password" {
  description = "Master password for RDS (use AWS Secrets Manager in production)"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "Port for PostgreSQL"
  type        = number
  default     = 5432
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "List of subnet IDs for DB subnet group (from networking module)"
  type        = list(string)
}

variable "rds_security_group_id" {
  description = "Security group ID for RDS (from networking module)"
  type        = string
}

variable "eks_nodes_security_group_id" {
  description = "Security group ID for EKS nodes (from networking module)"
  type        = string
  default     = null
}

variable "additional_security_group_ids" {
  description = "Additional security group IDs to attach to RDS"
  type        = list(string)
  default     = []
}

variable "create_security_group_rules" {
  description = "Create security group rules for RDS ingress"
  type        = bool
  default     = true
}

variable "additional_ingress_rules" {
  description = "Additional ingress rules for RDS security group"
  type = map(object({
    description              = string
    source_security_group_id = optional(string)
    cidr_blocks              = optional(list(string))
  }))
  default = {}
}

variable "parameter_group_family" {
  description = "Parameter group family (e.g., postgres15)"
  type        = string
  default     = "postgres15"
}

variable "parameters" {
  description = "List of DB parameters to apply"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = [
    {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements"
    },
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"
    },
    {
      name  = "ssl"
      value = "1"
    }
  ]
}

variable "create_option_group" {
  description = "Create a DB option group"
  type        = bool
  default     = false
}

variable "major_engine_version" {
  description = "Major engine version for option group"
  type        = string
  default     = "15"
}

variable "options" {
  description = "List of DB options to apply"
  type = list(object({
    option_name = string
    option_settings = optional(list(object({
      name  = string
      value = string
    })), [])
  }))
  default = []
}

variable "backup_retention_period" {
  description = "Backup retention period in days (7-35)"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 0 and 35 days."
  }
}

variable "backup_window" {
  description = "Backup window (UTC)"
  type        = string
  default     = "02:00-04:00"
}

variable "maintenance_window" {
  description = "Maintenance window (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = ["postgresql", "upgrade"]

  validation {
    condition = alltrue([
      for log_type in var.enabled_cloudwatch_logs_exports :
      contains(["postgresql", "upgrade"], log_type)
    ])
    error_message = "Invalid log type. Must be postgresql or upgrade."
  }
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days (7, 731)"
  type        = number
  default     = 7

  validation {
    condition     = contains([7, 731], var.performance_insights_retention_period)
    error_message = "Performance Insights retention must be 7 or 731 days."
  }
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be 0, 1, 5, 10, 15, 30, or 60 seconds."
  }
}

variable "monitoring_role_arn" {
  description = "ARN of IAM role for enhanced monitoring (from observability module)"
  type        = string
  default     = null
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately (not during maintenance window)"
  type        = bool
  default     = false
}

variable "ca_cert_identifier" {
  description = "CA certificate identifier"
  type        = string
  default     = "rds-ca-rsa2048-g1"
}

variable "create_read_replica" {
  description = "Create read replicas"
  type        = bool
  default     = false
}

variable "read_replica_count" {
  description = "Number of read replicas to create"
  type        = number
  default     = 1

  validation {
    condition     = var.read_replica_count >= 1 && var.read_replica_count <= 5
    error_message = "Read replica count must be between 1 and 5."
  }
}

variable "read_replica_instance_class" {
  description = "Instance class for read replicas (defaults to main instance class)"
  type        = string
  default     = null
}

variable "read_replica_multi_az" {
  description = "Enable Multi-AZ for read replicas"
  type        = bool
  default     = false
}

variable "create_cross_region_replica" {
  description = "Create cross-region read replica for DR"
  type        = bool
  default     = false
}

variable "cross_region_replica_instance_class" {
  description = "Instance class for cross-region replica"
  type        = string
  default     = null
}

variable "cross_region_replica_multi_az" {
  description = "Enable Multi-AZ for cross-region replica"
  type        = bool
  default     = false
}

variable "cross_region_replica_backup_retention" {
  description = "Backup retention for cross-region replica"
  type        = number
  default     = 7
}

variable "cross_region_kms_key_arn" {
  description = "KMS key ARN in replica region"
  type        = string
  default     = null
}

variable "cross_region_monitoring_role_arn" {
  description = "Monitoring role ARN in replica region"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
