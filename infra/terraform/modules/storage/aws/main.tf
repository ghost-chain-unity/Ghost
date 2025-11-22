locals {
  bucket_configs = {
    application = {
      name        = "${var.project_name}-${var.environment}-app-data"
      description = "Application data bucket for user uploads and assets"
      lifecycle_rules = var.app_data_lifecycle_rules
      enable_replication = false
      enable_object_lock = false
    }
    backup = {
      name        = "${var.project_name}-${var.environment}-backups"
      description = "Backup bucket for database backups and snapshots"
      lifecycle_rules = var.backup_lifecycle_rules
      enable_replication = var.enable_backup_replication
      enable_object_lock = var.enable_backup_object_lock
    }
    logs = {
      name        = "${var.project_name}-${var.environment}-logs"
      description = "Logs bucket for application and audit logs"
      lifecycle_rules = var.logs_lifecycle_rules
      enable_replication = var.enable_logs_replication
      enable_object_lock = false
    }
    static = {
      name        = "${var.project_name}-${var.environment}-static-assets"
      description = "Static assets bucket for frontend assets and public files"
      lifecycle_rules = var.static_assets_lifecycle_rules
      enable_replication = false
      enable_object_lock = false
    }
  }
}

resource "aws_s3_bucket" "main" {
  for_each = local.bucket_configs

  bucket = each.value.name

  tags = merge(
    var.tags,
    {
      Name        = each.value.name
      Description = each.value.description
      BucketType  = each.key
    }
  )
}

resource "aws_s3_bucket_versioning" "main" {
  for_each = local.bucket_configs

  bucket = aws_s3_bucket.main[each.key].id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  for_each = local.bucket_configs

  bucket = aws_s3_bucket.main[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  for_each = local.bucket_configs

  bucket = aws_s3_bucket.main[each.key].id

  block_public_acls       = var.block_public_access
  block_public_policy     = var.block_public_access
  ignore_public_acls      = var.block_public_access
  restrict_public_buckets = var.block_public_access
}

resource "aws_s3_bucket_lifecycle_configuration" "main" {
  for_each = { for k, v in local.bucket_configs : k => v if length(v.lifecycle_rules) > 0 }

  bucket = aws_s3_bucket.main[each.key].id

  dynamic "rule" {
    for_each = each.value.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      dynamic "filter" {
        for_each = lookup(rule.value, "prefix", null) != null ? [1] : []
        content {
          prefix = rule.value.prefix
        }
      }

      dynamic "transition" {
        for_each = lookup(rule.value, "transitions", [])
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      dynamic "expiration" {
        for_each = lookup(rule.value, "expiration_days", null) != null ? [1] : []
        content {
          days = rule.value.expiration_days
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = lookup(rule.value, "noncurrent_transitions", [])
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = lookup(rule.value, "noncurrent_expiration_days", null) != null ? [1] : []
        content {
          noncurrent_days = rule.value.noncurrent_expiration_days
        }
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.main]
}

resource "aws_s3_bucket_logging" "main" {
  for_each = var.enable_access_logging ? local.bucket_configs : {}

  bucket = aws_s3_bucket.main[each.key].id

  target_bucket = aws_s3_bucket.main["logs"].id
  target_prefix = "s3-access-logs/${each.key}/"
}

resource "aws_s3_bucket_object_lock_configuration" "main" {
  for_each = { for k, v in local.bucket_configs : k => v if v.enable_object_lock }

  bucket = aws_s3_bucket.main[each.key].id

  rule {
    default_retention {
      mode = var.object_lock_mode
      days = var.object_lock_retention_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.main]
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "main" {
  for_each = var.enable_intelligent_tiering ? local.bucket_configs : {}

  bucket = aws_s3_bucket.main[each.key].id
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
