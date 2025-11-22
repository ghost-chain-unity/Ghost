output "eks_cluster_log_group_name" {
  description = "Name of the EKS cluster CloudWatch log group"
  value       = aws_cloudwatch_log_group.eks_cluster.name
}

output "eks_cluster_log_group_arn" {
  description = "ARN of the EKS cluster CloudWatch log group"
  value       = aws_cloudwatch_log_group.eks_cluster.arn
}

output "application_log_group_names" {
  description = "Map of application service names to their CloudWatch log group names"
  value       = { for k, v in aws_cloudwatch_log_group.application : k => v.name }
}

output "application_log_group_arns" {
  description = "Map of application service names to their CloudWatch log group ARNs"
  value       = { for k, v in aws_cloudwatch_log_group.application : k => v.arn }
}

output "vpc_flow_log_group_name" {
  description = "Name of the VPC flow logs CloudWatch log group"
  value       = var.create_vpc_flow_log_group ? aws_cloudwatch_log_group.vpc_flow_logs[0].name : null
}

output "vpc_flow_log_group_arn" {
  description = "ARN of the VPC flow logs CloudWatch log group"
  value       = var.create_vpc_flow_log_group ? aws_cloudwatch_log_group.vpc_flow_logs[0].arn : null
}

output "rds_log_group_names" {
  description = "Map of RDS instance names to their CloudWatch log group names"
  value       = { for k, v in aws_cloudwatch_log_group.rds : k => v.name }
}

output "rds_log_group_arns" {
  description = "Map of RDS instance names to their CloudWatch log group ARNs"
  value       = { for k, v in aws_cloudwatch_log_group.rds : k => v.arn }
}

output "lambda_log_group_names" {
  description = "Map of Lambda function names to their CloudWatch log group names"
  value       = { for k, v in aws_cloudwatch_log_group.lambda : k => v.name }
}

output "lambda_log_group_arns" {
  description = "Map of Lambda function names to their CloudWatch log group ARNs"
  value       = { for k, v in aws_cloudwatch_log_group.lambda : k => v.arn }
}

output "audit_log_group_name" {
  description = "Name of the audit CloudWatch log group"
  value       = aws_cloudwatch_log_group.audit.name
}

output "audit_log_group_arn" {
  description = "ARN of the audit CloudWatch log group"
  value       = aws_cloudwatch_log_group.audit.arn
}

output "kms_eks_secrets_key_id" {
  description = "ID of the KMS key for EKS secrets encryption"
  value       = aws_kms_key.eks_secrets.key_id
}

output "kms_eks_secrets_key_arn" {
  description = "ARN of the KMS key for EKS secrets encryption"
  value       = aws_kms_key.eks_secrets.arn
}

output "kms_eks_secrets_alias" {
  description = "Alias of the KMS key for EKS secrets encryption"
  value       = aws_kms_alias.eks_secrets.name
}

output "kms_rds_key_id" {
  description = "ID of the KMS key for RDS encryption"
  value       = aws_kms_key.rds.key_id
}

output "kms_rds_key_arn" {
  description = "ARN of the KMS key for RDS encryption"
  value       = aws_kms_key.rds.arn
}

output "kms_rds_alias" {
  description = "Alias of the KMS key for RDS encryption"
  value       = aws_kms_alias.rds.name
}

output "kms_s3_key_id" {
  description = "ID of the KMS key for S3 encryption"
  value       = aws_kms_key.s3.key_id
}

output "kms_s3_key_arn" {
  description = "ARN of the KMS key for S3 encryption"
  value       = aws_kms_key.s3.arn
}

output "kms_s3_alias" {
  description = "Alias of the KMS key for S3 encryption"
  value       = aws_kms_alias.s3.name
}

output "kms_cloudwatch_logs_key_id" {
  description = "ID of the KMS key for CloudWatch Logs encryption"
  value       = aws_kms_key.cloudwatch_logs.key_id
}

output "kms_cloudwatch_logs_key_arn" {
  description = "ARN of the KMS key for CloudWatch Logs encryption"
  value       = aws_kms_key.cloudwatch_logs.arn
}

output "kms_cloudwatch_logs_alias" {
  description = "Alias of the KMS key for CloudWatch Logs encryption"
  value       = aws_kms_alias.cloudwatch_logs.name
}

output "kms_ebs_key_id" {
  description = "ID of the KMS key for EBS volume encryption"
  value       = aws_kms_key.ebs.key_id
}

output "kms_ebs_key_arn" {
  description = "ARN of the KMS key for EBS volume encryption"
  value       = aws_kms_key.ebs.arn
}

output "kms_ebs_alias" {
  description = "Alias of the KMS key for EBS volume encryption"
  value       = aws_kms_alias.ebs.name
}

output "kms_keys" {
  description = "Map of all KMS key details"
  value = {
    eks_secrets = {
      id    = aws_kms_key.eks_secrets.key_id
      arn   = aws_kms_key.eks_secrets.arn
      alias = aws_kms_alias.eks_secrets.name
    }
    rds = {
      id    = aws_kms_key.rds.key_id
      arn   = aws_kms_key.rds.arn
      alias = aws_kms_alias.rds.name
    }
    s3 = {
      id    = aws_kms_key.s3.key_id
      arn   = aws_kms_key.s3.arn
      alias = aws_kms_alias.s3.name
    }
    cloudwatch_logs = {
      id    = aws_kms_key.cloudwatch_logs.key_id
      arn   = aws_kms_key.cloudwatch_logs.arn
      alias = aws_kms_alias.cloudwatch_logs.name
    }
    ebs = {
      id    = aws_kms_key.ebs.key_id
      arn   = aws_kms_key.ebs.arn
      alias = aws_kms_alias.ebs.name
    }
  }
}

output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.name
}

output "eks_node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = aws_iam_role.eks_node.arn
}

output "eks_node_role_name" {
  description = "Name of the EKS node IAM role"
  value       = aws_iam_role.eks_node.name
}

output "eks_node_instance_profile_name" {
  description = "Name of the EKS node instance profile"
  value       = aws_iam_instance_profile.eks_node.name
}

output "eks_node_instance_profile_arn" {
  description = "ARN of the EKS node instance profile"
  value       = aws_iam_instance_profile.eks_node.arn
}

output "api_gateway_pod_role_arn" {
  description = "ARN of the API Gateway pod IAM role (IRSA)"
  value       = local.create_irsa_roles ? aws_iam_role.api_gateway_pod["enabled"].arn : null
}

output "api_gateway_pod_role_name" {
  description = "Name of the API Gateway pod IAM role (IRSA)"
  value       = local.create_irsa_roles ? aws_iam_role.api_gateway_pod["enabled"].name : null
}

output "indexer_pod_role_arn" {
  description = "ARN of the Indexer pod IAM role (IRSA)"
  value       = local.create_irsa_roles ? aws_iam_role.indexer_pod["enabled"].arn : null
}

output "indexer_pod_role_name" {
  description = "Name of the Indexer pod IAM role (IRSA)"
  value       = local.create_irsa_roles ? aws_iam_role.indexer_pod["enabled"].name : null
}

output "rpc_orchestrator_pod_role_arn" {
  description = "ARN of the RPC Orchestrator pod IAM role (IRSA)"
  value       = local.create_irsa_roles ? aws_iam_role.rpc_orchestrator_pod["enabled"].arn : null
}

output "rpc_orchestrator_pod_role_name" {
  description = "Name of the RPC Orchestrator pod IAM role (IRSA)"
  value       = local.create_irsa_roles ? aws_iam_role.rpc_orchestrator_pod["enabled"].name : null
}

output "ai_engine_pod_role_arn" {
  description = "ARN of the AI Engine pod IAM role (IRSA)"
  value       = local.create_irsa_roles ? aws_iam_role.ai_engine_pod["enabled"].arn : null
}

output "ai_engine_pod_role_name" {
  description = "Name of the AI Engine pod IAM role (IRSA)"
  value       = local.create_irsa_roles ? aws_iam_role.ai_engine_pod["enabled"].name : null
}

output "pod_roles" {
  description = "Map of all pod IAM role details (IRSA)"
  value = local.create_irsa_roles ? {
    api_gateway = {
      arn  = aws_iam_role.api_gateway_pod["enabled"].arn
      name = aws_iam_role.api_gateway_pod["enabled"].name
    }
    indexer = {
      arn  = aws_iam_role.indexer_pod["enabled"].arn
      name = aws_iam_role.indexer_pod["enabled"].name
    }
    rpc_orchestrator = {
      arn  = aws_iam_role.rpc_orchestrator_pod["enabled"].arn
      name = aws_iam_role.rpc_orchestrator_pod["enabled"].name
    }
    ai_engine = {
      arn  = aws_iam_role.ai_engine_pod["enabled"].arn
      name = aws_iam_role.ai_engine_pod["enabled"].name
    }
  } : null
}

output "rds_enhanced_monitoring_role_arn" {
  description = "ARN of the RDS enhanced monitoring IAM role"
  value       = var.enable_rds_enhanced_monitoring ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
}

output "rds_enhanced_monitoring_role_name" {
  description = "Name of the RDS enhanced monitoring IAM role"
  value       = var.enable_rds_enhanced_monitoring ? aws_iam_role.rds_enhanced_monitoring[0].name : null
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution IAM role"
  value       = var.enable_lambda_roles ? aws_iam_role.lambda_execution[0].arn : null
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda execution IAM role"
  value       = var.enable_lambda_roles ? aws_iam_role.lambda_execution[0].name : null
}

output "all_iam_roles" {
  description = "Map of all IAM role details"
  value = merge(
    {
      eks_cluster = {
        arn  = aws_iam_role.eks_cluster.arn
        name = aws_iam_role.eks_cluster.name
      }
      eks_node = {
        arn  = aws_iam_role.eks_node.arn
        name = aws_iam_role.eks_node.name
      }
    },
    var.enable_rds_enhanced_monitoring ? {
      rds_enhanced_monitoring = {
        arn  = aws_iam_role.rds_enhanced_monitoring[0].arn
        name = aws_iam_role.rds_enhanced_monitoring[0].name
      }
    } : {},
    var.enable_lambda_roles ? {
      lambda_execution = {
        arn  = aws_iam_role.lambda_execution[0].arn
        name = aws_iam_role.lambda_execution[0].name
      }
    } : {}
  )
}

output "loki_chunks_bucket_name" {
  description = "Name of the Loki chunks S3 bucket"
  value       = aws_s3_bucket.loki_chunks.id
}

output "loki_chunks_bucket_arn" {
  description = "ARN of the Loki chunks S3 bucket"
  value       = aws_s3_bucket.loki_chunks.arn
}

output "loki_ruler_bucket_name" {
  description = "Name of the Loki ruler S3 bucket"
  value       = aws_s3_bucket.loki_ruler.id
}

output "loki_ruler_bucket_arn" {
  description = "ARN of the Loki ruler S3 bucket"
  value       = aws_s3_bucket.loki_ruler.arn
}

output "loki_irsa_role_arn" {
  description = "ARN of the Loki pod IAM role (IRSA)"
  value       = local.create_irsa_roles ? aws_iam_role.loki_pod["enabled"].arn : null
}

output "loki_irsa_role_name" {
  description = "Name of the Loki pod IAM role (IRSA)"
  value       = local.create_irsa_roles ? aws_iam_role.loki_pod["enabled"].name : null
}

output "loki_s3_buckets" {
  description = "Map of Loki S3 bucket details"
  value = {
    chunks = {
      name = aws_s3_bucket.loki_chunks.id
      arn  = aws_s3_bucket.loki_chunks.arn
    }
    ruler = {
      name = aws_s3_bucket.loki_ruler.id
      arn  = aws_s3_bucket.loki_ruler.arn
    }
  }
}
