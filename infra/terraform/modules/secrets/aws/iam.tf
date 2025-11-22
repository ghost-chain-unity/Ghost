locals {
  oidc_provider_url_without_protocol = var.eks_oidc_provider_url != "" ? replace(var.eks_oidc_provider_url, "https://", "") : ""
  create_irsa_role                   = var.eks_oidc_provider_arn != "" && var.eks_oidc_provider_url != ""
}

resource "aws_iam_role" "external_secrets_operator" {
  for_each = local.create_irsa_role ? { "enabled" = true } : {}

  name = "${var.name_prefix}-external-secrets-operator-role"

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
            "${local.oidc_provider_url_without_protocol}:sub" = "system:serviceaccount:external-secrets:external-secrets-operator"
            "${local.oidc_provider_url_without_protocol}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name_prefix}-external-secrets-operator-role"
      Service     = "ExternalSecretsOperator"
      Purpose     = "SecretsAccess"
      IRSA        = "true"
    }
  )
}

resource "aws_iam_role_policy" "external_secrets_operator_secrets" {
  for_each = local.create_irsa_role ? { "enabled" = true } : {}

  name = "${var.name_prefix}-external-secrets-operator-secrets-policy"
  role = aws_iam_role.external_secrets_operator["enabled"].id

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
          aws_secretsmanager_secret.database_credentials.arn,
          aws_secretsmanager_secret.redis_password.arn,
          aws_secretsmanager_secret.openai_api_key.arn,
          aws_secretsmanager_secret.huggingface_api_key.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "external_secrets_operator_kms" {
  for_each = local.create_irsa_role ? { "enabled" = true } : {}

  name = "${var.name_prefix}-external-secrets-operator-kms-policy"
  role = aws_iam_role.external_secrets_operator["enabled"].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          var.eks_secrets_kms_key_arn
        ]
      }
    ]
  })
}
