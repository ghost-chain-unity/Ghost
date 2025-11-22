resource "aws_iam_role" "loki_pod" {
  for_each = local.create_irsa_roles ? { "enabled" = true } : {}

  name = "${var.name_prefix}-loki-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.eks_oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_url_without_protocol}:sub" = "system:serviceaccount:${var.loki_namespace}:loki"
            "${local.oidc_provider_url_without_protocol}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-loki-irsa-role"
      Service     = "Loki"
      Purpose     = "PodRole"
      IRSA        = "true"
      Namespace   = var.loki_namespace
    }
  )
}

resource "aws_iam_role_policy" "loki_s3_access" {
  for_each = local.create_irsa_roles ? { "enabled" = true } : {}

  name = "${var.name_prefix}-loki-s3-access-policy"
  role = aws_iam_role.loki_pod["enabled"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LokiListBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.loki_chunks.arn,
          aws_s3_bucket.loki_ruler.arn
        ]
      },
      {
        Sid    = "LokiObjectOperations"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.loki_chunks.arn}/*",
          "${aws_s3_bucket.loki_ruler.arn}/*"
        ]
      },
      {
        Sid    = "LokiListAllBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets"
        ]
        Resource = ["*"]
      },
      {
        Sid    = "LokiKMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = [
          aws_kms_key.s3.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "loki_cloudwatch" {
  for_each = local.create_irsa_roles ? { "enabled" = true } : {}

  name = "${var.name_prefix}-loki-cloudwatch-policy"
  role = aws_iam_role.loki_pod["enabled"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LokiCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/eks/${var.eks_cluster_name}/loki:*"
        ]
      }
    ]
  })
}
