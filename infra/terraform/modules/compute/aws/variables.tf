variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^1\\.(2[89]|[3-9][0-9])$", var.cluster_version))
    error_message = "Cluster version must be 1.28 or higher."
  }
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role for the EKS cluster (from observability module)"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role for the EKS worker nodes (from observability module)"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS nodes (from networking module)"
  type        = list(string)
}

variable "cluster_security_group_id" {
  description = "Security group ID for EKS cluster control plane (from networking module)"
  type        = string
}

variable "nodes_security_group_id" {
  description = "Security group ID for EKS worker nodes (from networking module)"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of KMS key for EKS secrets encryption (from observability module)"
  type        = string
}

variable "ebs_kms_key_arn" {
  description = "ARN of KMS key for EBS volume encryption (from observability module)"
  type        = string
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  validation {
    condition = alltrue([
      for log_type in var.enabled_cluster_log_types :
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

variable "node_group_version" {
  description = "Kubernetes version for node groups (defaults to cluster version)"
  type        = string
  default     = null
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
  default     = 5
}

variable "general_node_group_desired_size" {
  description = "Desired number of nodes in general node group"
  type        = number
  default     = 2
}

variable "general_node_group_disk_size" {
  description = "Disk size (GB) for general node group"
  type        = number
  default     = 50
}

variable "compute_node_group_instance_types" {
  description = "Instance types for compute-optimized node group"
  type        = list(string)
  default     = ["c5.2xlarge"]
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

variable "compute_node_group_disk_size" {
  description = "Disk size (GB) for compute-optimized node group"
  type        = number
  default     = 500
}

variable "compute_node_group_taints" {
  description = "Taints for compute-optimized node group"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = [{
    key    = "workload"
    value  = "compute-intensive"
    effect = "NoSchedule"
  }]
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

variable "memory_node_group_disk_size" {
  description = "Disk size (GB) for memory-optimized node group"
  type        = number
  default     = 100
}

variable "memory_node_group_taints" {
  description = "Taints for memory-optimized node group"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = [{
    key    = "workload"
    value  = "memory-intensive"
    effect = "NoSchedule"
  }]
}

variable "bootstrap_extra_args" {
  description = "Extra arguments to pass to the EKS bootstrap script"
  type        = string
  default     = ""
}

variable "enable_vpc_cni_addon" {
  description = "Enable VPC CNI addon"
  type        = bool
  default     = true
}

variable "vpc_cni_service_account_role_arn" {
  description = "ARN of IAM role for VPC CNI service account (optional)"
  type        = string
  default     = null
}

variable "enable_kube_proxy_addon" {
  description = "Enable kube-proxy addon"
  type        = bool
  default     = true
}

variable "enable_coredns_addon" {
  description = "Enable CoreDNS addon"
  type        = bool
  default     = true
}

variable "enable_ebs_csi_addon" {
  description = "Enable EBS CSI driver addon"
  type        = bool
  default     = true
}

variable "ebs_csi_service_account_role_arn" {
  description = "ARN of IAM role for EBS CSI driver service account (optional)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
