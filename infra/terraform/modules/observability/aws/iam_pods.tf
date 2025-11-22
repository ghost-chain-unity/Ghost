locals {
  oidc_provider_url_without_protocol = var.eks_oidc_provider_url != "" ? replace(var.eks_oidc_provider_url, "https://", "") : ""
  create_irsa_roles                   = var.eks_oidc_provider_arn != "" && var.eks_oidc_provider_url != ""
}

resource "aws_iam_role" "api_gateway_pod" {
  for_each = local.create_irsa_roles ? { "enabled" = true } : {}

  name = "${var.name_prefix}-api-gateway-pod-role"

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
            "${local.oidc_provider_url_without_protocol}:sub" = "system:serviceaccount:${var.environment}:api-gateway"
            "${local.oidc_provider_url_without_protocol}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-api-gateway-pod-role"
      Service     = "APIGateway"
      Purpose     = "PodRole"
      IRSA        = "true"
    }
  )
}

resource "aws_iam_role_policy" "api_gateway_rds" {
  for_each = local.create_irsa_roles ? { "enabled" = true } : {}

  name = "${var.name_prefix}-api-gateway-rds-policy"
  role = aws_iam_role.api_gateway_pod["enabled"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = [
          "arn:aws:rds-db:${var.aws_region}:${var.aws_account_id}:dbuser:*/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_gateway_secrets" {
  for_each = local.create_irsa_roles ? { "enabled" = true } : {}

  name = "${var.name_prefix}-api-gateway-secrets-policy"
  role = aws_iam_role.api_gateway_pod["enabled"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:${var.name_prefix}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [
          aws_kms_key.rds.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_gateway_s3" {
  for_each = local.create_irsa_roles ? { "enabled" = true } : {}

  name = "${var.name_prefix}-api-gateway-s3-policy"
  role = aws_iam_role.api_gateway_pod["enabled"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.name_prefix}-*/*",
          "arn:aws:s3:::${var.name_prefix}-*"
        ]
      },
      {
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

resource "aws_iam_role_policy" "api_gateway_cloudwatch" {
  for_each = local.create_irsa_roles ? { "enabled" = true } : {}

  name = "${var.name_prefix}-api-gateway-cloudwatch-policy"
  role = aws_iam_role.api_gateway_pod["enabled"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.application["api-gateway"].arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "indexer_pod" {
  for_each = local.create_irsa_roles ? { "enabled" = true } : {}

  name = "${var.name_prefix}-indexer-pod-role"

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
            "${local.oidc_provider_url_without_protocol}:sub" = "system:serviceaccount:${var.environment}:indexer"
            "${local.oidc_provider_url_without_protocol}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-indexer-pod-role"
      Service     = "Indexer"
      Purpose     = "PodRole"
      IRSA        = "true"
    }
  )
}

resource "aws_iam_role_policy" "indexer_rds" {
  for_each = local.create_irsa_roles ? { "enabled" = true } : {}

  name = "${var.name_prefix}-indexer-rds-policy"
  role = aws_iam_role.indexer_pod["enabled"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = [
          "arn:aws:rds-db:${var.aws_region}:${var.aws_account_id}:dbuser:*/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "indexer_s3" {
  for_each = local.create_irsa_roles ? { "enabled" = true } : {}

  name = "${var.name_prefix}-indexer-s3-policy"
  role = aws_iam_role.indexer_pod["enabled"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.name_prefix}-*/*",
          "arn:aws:s3:::${var.name_prefix}-*"
        ]
      },
      {
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

resource "aws_iam_role_policy" "indexer_cloudwatch" {
  for_each = local.create_irsa_roles ? { "enabled" = true } : {}

  name = "${var.name_prefix}-indexer-cloudwatch-policy"
  role = aws_iam_role.indexer_pod["enabled"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.application["indexer"].arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "rpc_orchestrator_pod" {
  for_each = local.create_irsa_roles ? { "enabled" = true } : {}

  name = "${var.name_prefix}-rpc-orchestrator-pod-role"

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
            "${local.oidc_provider_url_without_protocol}:sub" = "system:serviceaccount:${var.environment}:rpc-orchestrator"
            "${local.oidc_provider_url_without_protocol}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-rpc-orchestrator-pod-role"
      Service     = "RPCOrchestrator"
      Purpose     = "PodRole"
      IRSA        = "true"
    }
  )
}

resource "aws_iam_role_policy" "rpc_orchestrator_ec2" {
  for_each = local.create_irsa_roles ? { "enabled" = true } : {}

  name = "${var.name_prefix}-rpc-orchestrator-ec2-policy"
  role = aws_iam_role.rpc_orchestrator_pod["enabled"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeTags",
          "ec2:DescribeRegions",
          "ec2:DescribeAvailabilityZones"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "rpc_orchestrator_cloudwatch" {
  for_each = local.create_irsa_roles ? { "enabled" = true } : {}

  name = "${var.name_prefix}-rpc-orchestrator-cloudwatch-policy"
  role = aws_iam_role.rpc_orchestrator_pod["enabled"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.application["rpc-orchestrator"].arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "ai_engine_pod" {
  for_each = local.create_irsa_roles ? { "enabled" = true } : {}

  name = "${var.name_prefix}-ai-engine-pod-role"

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
            "${local.oidc_provider_url_without_protocol}:sub" = "system:serviceaccount:${var.environment}:ai-engine"
            "${local.oidc_provider_url_without_protocol}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-ai-engine-pod-role"
      Service     = "AIEngine"
      Purpose     = "PodRole"
      IRSA        = "true"
    }
  )
}

resource "aws_iam_role_policy" "ai_engine_s3" {
  for_each = local.create_irsa_roles ? { "enabled" = true } : {}

  name = "${var.name_prefix}-ai-engine-s3-policy"
  role = aws_iam_role.ai_engine_pod["enabled"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.name_prefix}-*/*",
          "arn:aws:s3:::${var.name_prefix}-*"
        ]
      },
      {
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

resource "aws_iam_role_policy" "ai_engine_cloudwatch" {
  for_each = local.create_irsa_roles ? { "enabled" = true } : {}

  name = "${var.name_prefix}-ai-engine-cloudwatch-policy"
  role = aws_iam_role.ai_engine_pod["enabled"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.application["ai-engine"].arn}:*"
        ]
      }
    ]
  })
}
