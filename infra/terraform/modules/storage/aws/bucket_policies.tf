data "aws_iam_policy_document" "bucket_policy" {
  for_each = local.bucket_configs

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.main[each.key].arn,
      "${aws_s3_bucket.main[each.key].arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "DenyUnencryptedObjectUploads"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.main[each.key].arn}/*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }

  dynamic "statement" {
    for_each = length(var.allowed_role_arns) > 0 ? [1] : []
    content {
      sid    = "AllowIAMRoleAccess"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.allowed_role_arns
      }
      actions = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      resources = [
        aws_s3_bucket.main[each.key].arn,
        "${aws_s3_bucket.main[each.key].arn}/*"
      ]
    }
  }

  dynamic "statement" {
    for_each = each.key == "static" && var.enable_cloudfront ? [1] : []
    content {
      sid    = "AllowCloudFrontAccess"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = [aws_cloudfront_origin_access_identity.main[0].iam_arn]
      }
      actions = ["s3:GetObject"]
      resources = [
        "${aws_s3_bucket.main[each.key].arn}/*"
      ]
    }
  }

  dynamic "statement" {
    for_each = each.key == "logs" ? [1] : []
    content {
      sid    = "S3ServerAccessLogsPolicy"
      effect = "Allow"
      principals {
        type        = "Service"
        identifiers = ["logging.s3.amazonaws.com"]
      }
      actions = ["s3:PutObject"]
      resources = [
        "${aws_s3_bucket.main[each.key].arn}/*"
      ]
      condition {
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "main" {
  for_each = local.bucket_configs

  bucket = aws_s3_bucket.main[each.key].id
  policy = data.aws_iam_policy_document.bucket_policy[each.key].json
}

data "aws_caller_identity" "current" {}
