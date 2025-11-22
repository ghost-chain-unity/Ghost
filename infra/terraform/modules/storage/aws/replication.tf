resource "aws_iam_role" "replication" {
  count = var.enable_cross_region_replication ? 1 : 0

  name               = "${var.project_name}-${var.environment}-s3-replication-role"
  assume_role_policy = data.aws_iam_policy_document.replication_assume_role[0].json

  tags = var.tags
}

data "aws_iam_policy_document" "replication_assume_role" {
  count = var.enable_cross_region_replication ? 1 : 0

  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "replication" {
  count = var.enable_cross_region_replication ? 1 : 0

  statement {
    sid    = "S3ReplicationGetObjectVersioning"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [
      for k, v in local.bucket_configs : aws_s3_bucket.main[k].arn
      if v.enable_replication
    ]
  }

  statement {
    sid    = "S3ReplicationGetObject"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging"
    ]
    resources = [
      for k, v in local.bucket_configs : "${aws_s3_bucket.main[k].arn}/*"
      if v.enable_replication
    ]
  }

  statement {
    sid    = "S3ReplicationReplicateObject"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags"
    ]
    resources = [
      for k, v in local.bucket_configs : "${var.replication_destination_bucket_arn_prefix}${v.name}-replica/*"
      if v.enable_replication
    ]
  }

  statement {
    sid    = "S3ReplicationKMSEncryption"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = [var.kms_key_arn]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.${var.aws_region}.amazonaws.com"]
    }
  }

  statement {
    sid    = "S3ReplicationKMSEncryptionDestination"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [var.replication_destination_kms_key_arn != null ? var.replication_destination_kms_key_arn : var.kms_key_arn]
    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.${var.replication_destination_region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "replication" {
  count = var.enable_cross_region_replication ? 1 : 0

  role   = aws_iam_role.replication[0].name
  policy = data.aws_iam_policy_document.replication[0].json
}

resource "aws_s3_bucket_replication_configuration" "main" {
  for_each = var.enable_cross_region_replication ? {
    for k, v in local.bucket_configs : k => v if v.enable_replication
  } : {}

  role   = aws_iam_role.replication[0].arn
  bucket = aws_s3_bucket.main[each.key].id

  rule {
    id     = "replicate-all"
    status = "Enabled"

    filter {
      prefix = ""
    }

    destination {
      bucket        = "${var.replication_destination_bucket_arn_prefix}${each.value.name}-replica"
      storage_class = var.replication_storage_class

      encryption_configuration {
        replica_kms_key_id = var.replication_destination_kms_key_arn != null ? var.replication_destination_kms_key_arn : var.kms_key_arn
      }

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }

      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.main
  ]
}
