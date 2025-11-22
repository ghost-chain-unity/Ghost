#============================================================================
# TWO-STAGE DEPLOYMENT WORKFLOW
#============================================================================
# This infrastructure uses a two-stage deployment to handle OIDC/IRSA setup:
#
# STAGE 1 - Initial Infrastructure (First terraform apply):
#   1. Deploy with empty OIDC values (default in variables.tf)
#   2. Observability module creates KMS, IAM roles, logs (NO IRSA pod roles)
#   3. Networking module creates VPC, subnets, security groups
#   4. Compute module creates EKS cluster WITH OIDC provider
#   5. Database and Storage modules deploy
#   6. Get OIDC values from: terraform output oidc_provider_for_stage_2
#
# STAGE 2 - Enable IRSA (Second terraform apply):
#   1. Copy OIDC values from Stage 1 output
#   2. Add them to your terraform.tfvars file
#   3. Run terraform apply again
#   4. Observability module NOW creates IRSA pod roles (with valid OIDC)
#
# See DEPLOYMENT_GUIDE.md for detailed step-by-step instructions.
#============================================================================

#============================================================================
# Data Sources
#============================================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

#============================================================================
# Module 1: Observability (First - no dependencies)
#============================================================================
# This module must be created first as it provides:
# - KMS keys for encryption (EKS secrets, RDS, S3, EBS, CloudWatch Logs)
# - IAM roles for EKS cluster and nodes
# - CloudWatch log groups for all services
# 
# OIDC/IRSA CONFIGURATION - TWO-STAGE WORKFLOW:
# ┌─────────────────────────────────────────────────────────────────┐
# │ STAGE 1 (First Apply):                                         │
# │ - eks_oidc_provider_arn = "" (empty, from default variable)    │
# │ - eks_oidc_provider_url = "" (empty, from default variable)    │
# │ - Result: NO IRSA pod roles created                            │
# │                                                                 │
# │ STAGE 2 (Second Apply):                                        │
# │ - eks_oidc_provider_arn = actual ARN (from terraform.tfvars)   │
# │ - eks_oidc_provider_url = actual URL (from terraform.tfvars)   │
# │ - Result: IRSA pod roles ARE created                           │
# └─────────────────────────────────────────────────────────────────┘
#
# Note: We use a deterministic cluster name to avoid circular dependency
# with the compute module. Cannot reference module.compute.oidc_provider_*
# here because compute depends on observability (would create cycle).
#============================================================================

module "observability" {
  source = "./modules/observability/aws"

  name_prefix      = local.name_prefix
  environment      = var.environment
  eks_cluster_name = "${local.name_prefix}-eks"
  aws_account_id   = data.aws_caller_identity.current.account_id
  aws_region       = var.aws_region

  # OIDC provider configuration (two-stage workflow)
  # STAGE 1: deployment_stage = "stage1" -> empty OIDC values (no IRSA pod roles)
  # STAGE 2: deployment_stage = "stage2" -> actual OIDC values (IRSA pod roles created)
  eks_oidc_provider_arn = var.deployment_stage == "stage2" ? var.eks_oidc_provider_arn : ""
  eks_oidc_provider_url = var.deployment_stage == "stage2" ? var.eks_oidc_provider_url : ""

  # Log retention configuration
  log_retention_days            = var.log_retention_days
  eks_log_retention_days        = var.eks_log_retention_days
  application_log_retention_days = var.application_log_retention_days
  vpc_flow_log_retention_days   = var.vpc_flow_log_retention_days
  rds_log_retention_days        = var.rds_log_retention_days
  audit_log_retention_days      = var.audit_log_retention_days

  # KMS configuration
  enable_kms_key_rotation  = var.enable_kms_key_rotation
  kms_deletion_window_days = var.kms_deletion_window_days

  # Feature flags
  enable_rds_enhanced_monitoring = var.enable_rds_enhanced_monitoring
  create_vpc_flow_log_group      = var.enable_flow_logs

  tags = local.common_tags
}

#============================================================================
# Module 2: Networking (Second - depends on observability for VPC flow logs)
#============================================================================
# This module provides:
# - VPC with public, private app, and private data subnets
# - Security groups for ALB, EKS, RDS, Redis, VPC endpoints
# - NAT Gateways, Internet Gateway, VPC endpoints
# - VPC Flow Logs (uses CloudWatch log group from observability)
#============================================================================

module "networking" {
  source = "./modules/networking/aws"

  name_prefix = local.name_prefix

  # VPC configuration
  vpc_cidr                 = var.vpc_cidr
  azs                      = local.azs
  public_subnet_cidrs      = local.public_subnets
  private_app_subnet_cidrs = local.private_app_subnets
  private_data_subnet_cidrs = local.private_data_subnets

  # NAT Gateway configuration
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  # DNS configuration
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # VPC Flow Logs
  enable_flow_logs          = var.enable_flow_logs
  flow_logs_retention_days  = var.vpc_flow_log_retention_days

  # VPC Endpoints
  enable_s3_endpoint  = var.enable_s3_endpoint
  enable_ecr_endpoint = var.enable_ecr_endpoint
  enable_eks_endpoint = var.enable_eks_endpoint
  enable_ec2_endpoint = var.enable_ec2_endpoint

  tags = local.common_tags

  depends_on = [module.observability]
}

#============================================================================
# Module 3: Compute (Third - depends on observability and networking)
#============================================================================
# This module provides:
# - EKS cluster with control plane logging
# - Managed node groups (general, compute-optimized, memory-optimized)
# - EKS addons (VPC CNI, kube-proxy, CoreDNS, EBS CSI driver)
# - OIDC provider for IRSA (IAM Roles for Service Accounts)
#
# Dependencies:
# - Observability: IAM roles, KMS keys for secrets and EBS encryption
# - Networking: Private subnets, security groups
#============================================================================

module "compute" {
  source = "./modules/compute/aws"

  cluster_name    = "${local.name_prefix}-eks"
  cluster_version = var.eks_cluster_version

  # IAM roles from observability module
  cluster_role_arn = module.observability.eks_cluster_role_arn
  node_role_arn    = module.observability.eks_node_role_arn

  # Networking resources
  private_subnet_ids        = module.networking.private_app_subnet_ids
  cluster_security_group_id = module.networking.eks_cluster_security_group_id
  nodes_security_group_id   = module.networking.eks_nodes_security_group_id

  # KMS encryption from observability module
  kms_key_arn     = module.observability.kms_eks_secrets_key_arn
  ebs_kms_key_arn = module.observability.kms_ebs_key_arn

  # API server endpoint configuration
  endpoint_private_access = var.eks_endpoint_private_access
  endpoint_public_access  = var.eks_endpoint_public_access
  public_access_cidrs     = var.eks_public_access_cidrs

  # Control plane logging
  enabled_cluster_log_types = var.eks_enabled_cluster_log_types

  # IRSA configuration (two-stage workflow)
  # STAGE 1: deployment_stage = "stage1" -> IRSA disabled (OIDC provider doesn't exist yet)
  # STAGE 2: deployment_stage = "stage2" -> IRSA enabled (OIDC provider exists from Stage 1)
  enable_irsa = var.deployment_stage == "stage2"

  # Node groups configuration
  enable_node_groups = var.enable_node_groups

  # General node group
  general_node_group_instance_types  = var.general_node_group_instance_types
  general_node_group_capacity_type   = var.general_node_group_capacity_type
  general_node_group_min_size        = var.general_node_group_min_size
  general_node_group_max_size        = var.general_node_group_max_size
  general_node_group_desired_size    = var.general_node_group_desired_size

  # Compute-optimized node group
  compute_node_group_instance_types  = var.compute_node_group_instance_types
  compute_node_group_capacity_type   = var.compute_node_group_capacity_type
  compute_node_group_min_size        = var.compute_node_group_min_size
  compute_node_group_max_size        = var.compute_node_group_max_size
  compute_node_group_desired_size    = var.compute_node_group_desired_size

  # Memory-optimized node group
  memory_node_group_instance_types   = var.memory_node_group_instance_types
  memory_node_group_capacity_type    = var.memory_node_group_capacity_type
  memory_node_group_min_size         = var.memory_node_group_min_size
  memory_node_group_max_size         = var.memory_node_group_max_size
  memory_node_group_desired_size     = var.memory_node_group_desired_size

  # EKS addons
  enable_vpc_cni_addon       = var.enable_vpc_cni_addon
  enable_kube_proxy_addon    = var.enable_kube_proxy_addon
  enable_coredns_addon       = var.enable_coredns_addon
  enable_ebs_csi_addon       = var.enable_ebs_csi_addon

  tags = local.common_tags

  depends_on = [
    module.observability,
    module.networking
  ]
}

#============================================================================
# Module 4: Database (Fourth - depends on observability and networking)
#============================================================================
# This module provides:
# - RDS PostgreSQL instance with Multi-AZ support
# - DB subnet group in private data subnets
# - DB parameter group and option group
# - Optional read replicas and cross-region replication
# - Performance Insights and enhanced monitoring
#
# Dependencies:
# - Observability: KMS key for RDS encryption, IAM role for enhanced monitoring
# - Networking: Private data subnets, RDS security group
#============================================================================

module "database" {
  source = "./modules/database/aws"

  identifier      = "${local.name_prefix}-rds"
  engine_version  = var.db_engine_version
  instance_class  = var.db_instance_class

  # Storage configuration
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = var.db_storage_type
  storage_throughput    = var.db_storage_throughput

  # KMS encryption from observability module
  kms_key_arn = module.observability.kms_rds_key_arn

  # Database configuration
  database_name   = var.db_name
  master_username = var.db_master_username
  master_password = var.db_master_password
  port            = var.db_port

  # High availability
  multi_az = var.db_multi_az

  # Networking resources
  subnet_ids                   = module.networking.private_data_subnet_ids
  rds_security_group_id        = module.networking.rds_security_group_id
  eks_nodes_security_group_id  = module.networking.eks_nodes_security_group_id

  # Backup configuration
  backup_retention_period      = var.db_backup_retention_period
  backup_window                = var.db_backup_window
  maintenance_window           = var.db_maintenance_window
  delete_automated_backups     = var.db_delete_automated_backups
  skip_final_snapshot          = var.db_skip_final_snapshot
  final_snapshot_identifier    = var.db_skip_final_snapshot ? null : "${local.name_prefix}-rds-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Monitoring
  enabled_cloudwatch_logs_exports = var.db_enabled_cloudwatch_logs_exports
  performance_insights_enabled    = var.db_performance_insights_enabled
  monitoring_interval             = var.db_monitoring_interval
  monitoring_role_arn             = var.db_monitoring_interval > 0 ? module.observability.rds_enhanced_monitoring_role_arn : null

  # Read replicas
  create_read_replica      = var.db_create_read_replica
  read_replica_count       = var.db_read_replica_count

  tags = local.common_tags

  depends_on = [
    module.observability,
    module.networking
  ]
}

#============================================================================
# Module 5: Storage (Fifth - depends on observability)
#============================================================================
# This module provides:
# - S3 buckets for application data, backups, logs, static assets
# - Bucket encryption using KMS
# - Lifecycle policies for cost optimization
# - Optional CloudFront distribution for static assets
# - Optional cross-region replication
#
# Dependencies:
# - Observability: KMS key for S3 encryption
#============================================================================

module "storage" {
  source = "./modules/storage/aws"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  # KMS encryption from observability module
  kms_key_arn = module.observability.kms_s3_key_arn

  # Bucket configuration
  enable_versioning        = var.s3_enable_versioning
  block_public_access      = var.s3_block_public_access
  enable_access_logging    = var.s3_enable_access_logging
  enable_intelligent_tiering = var.s3_enable_intelligent_tiering

  # CloudFront configuration
  enable_cloudfront = var.s3_enable_cloudfront

  # Cross-region replication
  enable_cross_region_replication = var.s3_enable_cross_region_replication
  replication_region              = var.s3_replication_region

  tags = local.common_tags

  depends_on = [module.observability]
}

#============================================================================
# Module 6: Secrets (Sixth - depends on observability for KMS)
#============================================================================
# This module provides:
# - AWS Secrets Manager secrets for database credentials, API keys
# - Lambda function for automatic database credential rotation (30 days)
# - IAM role for External Secrets Operator (IRSA-based)
# - Secrets encrypted with KMS key from observability module
#
# Dependencies:
# - Observability: KMS key for secrets encryption, OIDC provider for IRSA
# - Database: RDS endpoint for rotation Lambda (optional)
#
# Two-Stage Workflow:
# - Stage 1: Secrets created without rotation (no VPC config)
# - Stage 2: Enable rotation with VPC subnet IDs and security groups
#============================================================================

module "secrets" {
  source = "./modules/secrets/aws"

  name_prefix      = local.name_prefix
  environment      = var.environment
  aws_region       = var.aws_region
  aws_account_id   = data.aws_caller_identity.current.account_id

  # KMS encryption from observability module
  eks_secrets_kms_key_arn = module.observability.kms_eks_secrets_key_arn

  # IRSA configuration (two-stage workflow)
  # STAGE 1: deployment_stage = "stage1" -> no IRSA role (OIDC doesn't exist)
  # STAGE 2: deployment_stage = "stage2" -> IRSA role created
  eks_oidc_provider_arn = var.deployment_stage == "stage2" ? var.eks_oidc_provider_arn : ""
  eks_oidc_provider_url = var.deployment_stage == "stage2" ? var.eks_oidc_provider_url : ""

  # Rotation configuration (optional, production-only)
  enable_rotation        = var.enable_secrets_rotation
  database_rotation_days = var.database_rotation_days

  # VPC configuration for rotation Lambda (required if enable_rotation = true)
  vpc_subnet_ids         = var.enable_secrets_rotation ? module.networking.private_app_subnet_ids : []
  vpc_security_group_ids = var.enable_secrets_rotation ? [module.networking.eks_nodes_security_group_id] : []

  tags = local.common_tags

  depends_on = [
    module.observability,
    module.database  # Rotation Lambda needs RDS endpoint
  ]
}
