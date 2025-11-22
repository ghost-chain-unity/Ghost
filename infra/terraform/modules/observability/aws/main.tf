locals {
  common_tags = merge(
    var.tags,
    {
      Module      = "observability"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.eks_cluster_name}/cluster"
  retention_in_days = var.eks_log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-eks-cluster-logs"
      Service     = "EKS"
      LogType     = "ClusterLogs"
      Compliance  = "Audit"
    }
  )
}

resource "aws_cloudwatch_log_group" "application" {
  for_each = toset(var.application_services)

  name              = "/aws/application/${each.key}"
  retention_in_days = var.application_log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-${each.key}-logs"
      Service     = each.key
      LogType     = "ApplicationLogs"
    }
  )
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count = var.create_vpc_flow_log_group ? 1 : 0

  name              = "/aws/vpc/flow-logs"
  retention_in_days = var.vpc_flow_log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-vpc-flow-logs"
      Service     = "VPC"
      LogType     = "FlowLogs"
      Compliance  = "Audit"
    }
  )
}

# RDS CloudWatch Log Groups
# IMPORTANT: RDS log group names must follow the pattern /aws/rds/instance/{db_instance_identifier}/{engine}
# to ensure RDS log exports land in these managed, encrypted groups instead of auto-created unencrypted ones.
# 
# Engine-specific suffixes:
#   - postgresql: /aws/rds/instance/{instance_id}/postgresql
#   - mysql: /aws/rds/instance/{instance_id}/error, /aws/rds/instance/{instance_id}/general, /aws/rds/instance/{instance_id}/slowquery
#   - mariadb: /aws/rds/instance/{instance_id}/error, /aws/rds/instance/{instance_id}/general, /aws/rds/instance/{instance_id}/slowquery
#   - oracle: /aws/rds/instance/{instance_id}/alert, /aws/rds/instance/{instance_id}/audit, /aws/rds/instance/{instance_id}/trace, /aws/rds/instance/{instance_id}/listener
#   - sqlserver: /aws/rds/instance/{instance_id}/error, /aws/rds/instance/{instance_id}/agent
#
# This module currently creates PostgreSQL log groups. For other engines, modify the name pattern accordingly.
resource "aws_cloudwatch_log_group" "rds" {
  for_each = toset(var.rds_instance_names)

  name              = "/aws/rds/instance/${each.key}/postgresql"
  retention_in_days = var.rds_log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-rds-${each.key}-logs"
      Service     = "RDS"
      Instance    = each.key
      LogType     = "DatabaseLogs"
    }
  )
}

resource "aws_cloudwatch_log_group" "lambda" {
  for_each = toset(var.lambda_function_names)

  name              = "/aws/lambda/${each.key}"
  retention_in_days = var.lambda_log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-lambda-${each.key}-logs"
      Service     = "Lambda"
      Function    = each.key
      LogType     = "FunctionLogs"
    }
  )
}

resource "aws_cloudwatch_log_group" "audit" {
  name              = "/aws/audit/${var.name_prefix}"
  retention_in_days = var.audit_log_retention_days
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-audit-logs"
      Service     = "Audit"
      LogType     = "AuditLogs"
      Compliance  = "SOC2-GDPR"
    }
  )
}

resource "aws_s3_bucket" "loki_chunks" {
  bucket = "${var.project_name}-${var.environment}-loki-chunks"

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-loki-chunks"
      Description = "Loki compressed log chunks storage"
      Service     = "Loki"
      BucketType  = "loki-chunks"
      Purpose     = "LogStorage"
    }
  )
}

resource "aws_s3_bucket" "loki_ruler" {
  bucket = "${var.project_name}-${var.environment}-loki-ruler"

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.project_name}-${var.environment}-loki-ruler"
      Description = "Loki alerting and recording rules storage"
      Service     = "Loki"
      BucketType  = "loki-ruler"
      Purpose     = "RuleStorage"
    }
  )
}

resource "aws_s3_bucket_versioning" "loki_chunks" {
  bucket = aws_s3_bucket.loki_chunks.id

  versioning_configuration {
    status = "Suspended"
  }
}

resource "aws_s3_bucket_versioning" "loki_ruler" {
  bucket = aws_s3_bucket.loki_ruler.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "loki_chunks" {
  bucket = aws_s3_bucket.loki_chunks.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "loki_ruler" {
  bucket = aws_s3_bucket.loki_ruler.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "loki_chunks" {
  bucket = aws_s3_bucket.loki_chunks.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "loki_ruler" {
  bucket = aws_s3_bucket.loki_ruler.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "loki_chunks" {
  bucket = aws_s3_bucket.loki_chunks.id

  rule {
    id     = "transition-and-expire-chunks"
    status = "Enabled"

    dynamic "transition" {
      for_each = var.loki_enable_intelligent_tiering ? [1] : []
      content {
        days          = 31
        storage_class = "INTELLIGENT_TIERING"
      }
    }

    expiration {
      days = var.loki_chunks_retention_days
    }
  }
}

resource "aws_s3_bucket_logging" "loki_chunks" {
  bucket = aws_s3_bucket.loki_chunks.id

  target_bucket = var.logs_bucket_name != "" ? var.logs_bucket_name : "${var.project_name}-${var.environment}-logs"
  target_prefix = "s3-access-logs/loki-chunks/"
}

resource "aws_s3_bucket_logging" "loki_ruler" {
  bucket = aws_s3_bucket.loki_ruler.id

  target_bucket = var.logs_bucket_name != "" ? var.logs_bucket_name : "${var.project_name}-${var.environment}-logs"
  target_prefix = "s3-access-logs/loki-ruler/"
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "loki_chunks" {
  count = var.loki_enable_intelligent_tiering ? 1 : 0

  bucket = aws_s3_bucket.loki_chunks.id
  name   = "entire-bucket"

  tiering {
    access_tier = "ARCHIVE_ACCESS"
    days        = 90
  }

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}
